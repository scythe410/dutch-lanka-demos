/**
 * createOrder — callable Cloud Function. Per architecture.md §4.2 step 3+:
 *
 *   1. Authenticated customer submits cart + delivery address.
 *   2. Server re-fetches every product, validates availability, stock, and
 *      that the client-supplied unit price still matches Firestore.
 *   3. Server computes subtotal + delivery fee + total (all in cents).
 *   4. Server writes the order doc with `status: "pending_payment"`.
 *   5. Server returns `{ orderId, payherePayload }` — the payload includes
 *      the PayHere hash that the client SDK needs.
 *
 * The PayHere hash is built server-side using the merchant secret; the
 * client never sees the secret. Source of truth for payment confirmation
 * is `payhereNotify`, not the SDK's success callback (CLAUDE.md rule 2).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { z } from "zod";

import { db, FieldValue } from "../lib/admin";
import { buildPaymentHash, formatAmount } from "../lib/payhere";

const PAYHERE_MERCHANT_ID = defineString("PAYHERE_MERCHANT_ID");
const PAYHERE_NOTIFY_URL = defineString("PAYHERE_NOTIFY_URL");
const PAYHERE_MERCHANT_SECRET = defineSecret("PAYHERE_MERCHANT_SECRET");

// Flat delivery fee for MVP. Real fee logic (distance-based) lives in a
// later step.
const DELIVERY_FEE_CENTS = 30000; // LKR 300.00

const InputSchema = z.object({
  items: z
    .array(
      z.object({
        productId: z.string().min(1),
        qty: z.number().int().positive(),
        unitPriceCents: z.number().int().nonnegative(),
      }),
    )
    .min(1),
  deliveryAddress: z.object({
    line1: z.string().min(1),
    line2: z.string().optional(),
    city: z.string().min(1),
    postalCode: z.string().optional(),
    lat: z.number().optional(),
    lng: z.number().optional(),
  }),
  paymentMethod: z.string().min(1),
  customerName: z.string().min(1),
  customerPhone: z.string().min(1),
});

export type CreateOrderInput = z.infer<typeof InputSchema>;

export const createOrder = onCall(
  {
    region: "asia-south1",
    secrets: [PAYHERE_MERCHANT_SECRET],
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Sign in to place an order.");
    }

    const parsed = InputSchema.safeParse(req.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", parsed.error.message);
    }
    const input = parsed.data;
    const uid = req.auth.uid;

    // Re-fetch every product. This is the only price + availability source
    // the server trusts.
    const productRefs = input.items.map((i) =>
      db.collection("products").doc(i.productId),
    );
    const productSnaps = await db.getAll(...productRefs);

    let subtotalCents = 0;
    const orderItems: Array<{
      productId: string;
      name: string;
      qty: number;
      unitPriceCents: number;
    }> = [];

    for (let i = 0; i < input.items.length; i++) {
      const cartLine = input.items[i];
      const snap = productSnaps[i];

      if (!snap.exists) {
        throw new HttpsError(
          "failed-precondition",
          `Product ${cartLine.productId} not found.`,
        );
      }
      const product = snap.data() as {
        name: string;
        priceCents: number;
        available: boolean;
        stock: number;
      };

      if (!product.available) {
        throw new HttpsError(
          "failed-precondition",
          `${product.name} is not available.`,
        );
      }
      if (product.priceCents !== cartLine.unitPriceCents) {
        throw new HttpsError(
          "failed-precondition",
          `Price changed for ${product.name}. Refresh and try again.`,
        );
      }
      if ((product.stock ?? 0) < cartLine.qty) {
        throw new HttpsError(
          "failed-precondition",
          `Insufficient stock for ${product.name}.`,
        );
      }

      subtotalCents += product.priceCents * cartLine.qty;
      orderItems.push({
        productId: cartLine.productId,
        name: product.name,
        qty: cartLine.qty,
        unitPriceCents: product.priceCents,
      });
    }

    const totalCents = subtotalCents + DELIVERY_FEE_CENTS;

    const orderRef = db.collection("orders").doc();
    const orderId = orderRef.id;

    await orderRef.set({
      customerId: uid,
      items: orderItems,
      subtotalCents,
      deliveryFeeCents: DELIVERY_FEE_CENTS,
      totalCents,
      deliveryAddress: input.deliveryAddress,
      customerName: input.customerName,
      customerPhone: input.customerPhone,
      paymentMethod: input.paymentMethod,
      paymentStatus: "pending",
      status: "pending_payment",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Build the PayHere SDK payload. Hash is computed against the same
    // amount string PayHere will see — drift here breaks the signature.
    const merchantId = PAYHERE_MERCHANT_ID.value();
    const merchantSecret = PAYHERE_MERCHANT_SECRET.value();
    const notifyUrl = PAYHERE_NOTIFY_URL.value();
    const amount = formatAmount(totalCents);
    const currency = "LKR";

    const hash = buildPaymentHash({
      merchantId,
      merchantSecret,
      orderId,
      amount,
      currency,
    });

    const firstName = input.customerName.split(" ")[0] || "Customer";
    const lastName =
      input.customerName.split(" ").slice(1).join(" ") || firstName;

    return {
      orderId,
      payherePayload: {
        sandbox: true,
        merchant_id: merchantId,
        notify_url: notifyUrl,
        order_id: orderId,
        items: orderItems.map((i) => i.name).join(", "),
        amount,
        currency,
        first_name: firstName,
        last_name: lastName,
        email: req.auth.token.email ?? "",
        phone: input.customerPhone,
        address: input.deliveryAddress.line1,
        city: input.deliveryAddress.city,
        country: "Sri Lanka",
        hash,
      },
    };
  },
);
