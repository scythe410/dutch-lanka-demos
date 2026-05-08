/**
 * Integration tests for the `createOrder` callable Function. Runs against
 * the Firestore emulator (started by `firebase emulators:exec`).
 *
 * Strategy: seed a product, invoke `createOrder` via firebase-functions-test
 * wrap, assert the returned payload + the persisted order doc.
 */

import { buildPaymentHash, formatAmount } from "../src/lib/payhere";
import { clearFirestore, seedProduct } from "./helpers/emulator";

import functionsTest from "firebase-functions-test";

const ftest = functionsTest();
import { createOrder } from "../src/functions/createOrder";

// `wrap` types the request more strictly than firebase-functions-test
// constructs at runtime — cast to a permissive callable.
const wrapped = ftest.wrap(createOrder) as unknown as (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  req: {data: any; auth?: any}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
) => Promise<any>;

const baseAuth = {
  uid: "u-cust-1",
  token: {
    email: "alice@dutchlanka.test",
    firebase: { sign_in_provider: "password" },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } as any,
  rawToken: "test-raw-token",
};

const baseAddress = {
  line1: "12 Galle Road",
  city: "Colombo",
  postalCode: "00300",
};

afterAll(async () => {
  ftest.cleanup();
});

beforeEach(async () => {
  await clearFirestore();
});

describe("createOrder", () => {
  it("happy path: writes order with pending_payment and returns valid hash", async () => {
    await seedProduct("croissant", {
      name: "Butter Croissant",
      priceCents: 35000,
      stock: 25,
      lowStockThreshold: 5,
      available: true,
    });

    const result = await wrapped({
      data: {
        items: [{ productId: "croissant", qty: 2, unitPriceCents: 35000 }],
        deliveryAddress: baseAddress,
        paymentMethod: "card",
        customerName: "Alice Perera",
        customerPhone: "0771234567",
      },
      auth: baseAuth,
    });

    expect(result.orderId).toBeTruthy();
    const subtotal = 35000 * 2;
    const total = subtotal + 30000; // 30000 = flat delivery fee
    expect(result.payherePayload.amount).toBe(formatAmount(total));
    expect(result.payherePayload.currency).toBe("LKR");
    expect(result.payherePayload.merchant_id).toBe("test-merchant");

    // Hash must match what the helper would build from the same inputs.
    const expectedHash = buildPaymentHash({
      merchantId: "test-merchant",
      merchantSecret: "test-secret",
      orderId: result.orderId,
      amount: formatAmount(total),
      currency: "LKR",
    });
    expect(result.payherePayload.hash).toBe(expectedHash);

    // Order doc was written with pending_payment.
    const admin = await import("firebase-admin");
    const orderSnap = await admin
      .firestore()
      .collection("orders")
      .doc(result.orderId)
      .get();
    expect(orderSnap.exists).toBe(true);
    const order = orderSnap.data()!;
    expect(order.status).toBe("pending_payment");
    expect(order.paymentStatus).toBe("pending");
    expect(order.subtotalCents).toBe(subtotal);
    expect(order.totalCents).toBe(total);
    expect(order.customerId).toBe("u-cust-1");
    expect(order.items).toHaveLength(1);
    expect(order.items[0]).toMatchObject({
      productId: "croissant",
      name: "Butter Croissant",
      qty: 2,
      unitPriceCents: 35000,
    });
  });

  it("rejects when client price does not match Firestore (price mismatch)", async () => {
    await seedProduct("eclair", {
      name: "Chocolate Eclair",
      priceCents: 32000, // server truth
      stock: 10,
      lowStockThreshold: 2,
      available: true,
    });

    await expect(
      wrapped({
        data: {
          items: [
            { productId: "eclair", qty: 1, unitPriceCents: 25000 }, // stale
          ],
          deliveryAddress: baseAddress,
          paymentMethod: "card",
          customerName: "Alice",
          customerPhone: "0771234567",
        },
        auth: baseAuth,
      }),
    ).rejects.toThrow(/price changed/i);
  });

  it("rejects unauthenticated callers", async () => {
    await seedProduct("loaf", {
      name: "Milk Bread",
      priceCents: 28000,
      stock: 10,
      lowStockThreshold: 2,
      available: true,
    });

    await expect(
      wrapped({
        data: {
          items: [{ productId: "loaf", qty: 1, unitPriceCents: 28000 }],
          deliveryAddress: baseAddress,
          paymentMethod: "card",
          customerName: "Alice",
          customerPhone: "0771234567",
        },
        // No auth
      }),
    ).rejects.toThrow(/sign in/i);
  });
});
