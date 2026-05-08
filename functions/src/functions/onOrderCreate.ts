/**
 * onOrderCreate — Firestore trigger fired when a new order doc is written
 * by `createOrder`. Per architecture.md §4.5:
 *
 *   1. Atomically decrement `products/{id}.stock` for each line item.
 *      Done in a single transaction so two concurrent orders cannot
 *      oversell.
 *   2. Write a `lowStockAlerts/{alertId}` doc when an item crosses its
 *      threshold (i.e. stock was above before, at-or-below after).
 *   3. Push an FCM message to every manager device token.
 *
 * Stock failures throw; the trigger framework retries with backoff. The
 * order doc itself is left intact — the manager surfaces oversells from
 * the alert.
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import { db, messaging, FieldValue } from "../lib/admin";

interface OrderLine {
  productId: string;
  name: string;
  qty: number;
  unitPriceCents: number;
}

export const onOrderCreate = onDocumentCreated(
  {
    document: "orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data() as {
      items: OrderLine[];
      totalCents: number;
    };
    const orderId = event.params.orderId;
    const items = order.items ?? [];
    if (items.length === 0) return;

    // Run stock decrements + alert writes in a single transaction. Reads
    // come first (Firestore txn rule); writes batched at the end.
    const alertsToWrite: Array<{
      productId: string;
      productName: string;
      currentStock: number;
      threshold: number;
    }> = [];

    await db.runTransaction(async (txn) => {
      const refs = items.map((i) => db.collection("products").doc(i.productId));
      const snaps = await Promise.all(refs.map((r) => txn.get(r)));

      // Reset alert collector — txn may retry.
      alertsToWrite.length = 0;

      for (let i = 0; i < items.length; i++) {
        const productSnap = snaps[i];
        if (!productSnap.exists) {
          throw new Error(`Product ${items[i].productId} not found`);
        }
        const productData = productSnap.data() as {
          name: string;
          stock?: number;
          lowStockThreshold?: number;
        };
        const stock = productData.stock ?? 0;
        const threshold = productData.lowStockThreshold ?? 0;
        const newStock = stock - items[i].qty;

        if (newStock < 0) {
          throw new Error(
            `Insufficient stock for ${productData.name} ` +
              `(have ${stock}, need ${items[i].qty})`,
          );
        }

        txn.update(refs[i], {
          stock: newStock,
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Alert only on the threshold crossing — avoids spamming a fresh
        // alert for every order while a product is already low.
        if (stock > threshold && newStock <= threshold) {
          alertsToWrite.push({
            productId: items[i].productId,
            productName: productData.name,
            currentStock: newStock,
            threshold,
          });
        }
      }

      for (const alert of alertsToWrite) {
        const alertRef = db.collection("lowStockAlerts").doc();
        txn.set(alertRef, {
          ...alert,
          acknowledged: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    });

    logger.info("onOrderCreate: stock decremented", {
      orderId,
      lineCount: items.length,
      alerts: alertsToWrite.length,
    });

    // FCM to managers — runs only after the txn commits, so a stock
    // failure won't notify anyone.
    const managersSnap = await db
      .collection("users")
      .where("role", "==", "manager")
      .get();

    const tokens: string[] = [];
    managersSnap.forEach((doc) => {
      const t = doc.data().fcmTokens;
      if (Array.isArray(t)) {
        for (const token of t) {
          if (typeof token === "string" && token.length > 0) tokens.push(token);
        }
      }
    });

    if (tokens.length === 0) {
      logger.info("onOrderCreate: no manager FCM tokens", { orderId });
      return;
    }

    try {
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "New order received",
          body: `Order #${orderId.slice(0, 6)} — ` +
            `LKR ${(order.totalCents / 100).toFixed(2)}`,
        },
        data: { orderId, type: "new_order" },
      });
    } catch (err) {
      logger.error("onOrderCreate: FCM send failed", { orderId, err });
    }
  },
);
