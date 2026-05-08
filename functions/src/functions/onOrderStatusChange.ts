/**
 * onOrderStatusChange — Firestore trigger fired on every order update.
 * Filters out non-status edits, then:
 *
 *   1. Appends a `statusHistory/{eventId}` subdoc capturing the
 *      transition (status, previousStatus, changedAt).
 *   2. Pushes an FCM notification to the customer's device tokens.
 *
 * Recursion safety: this trigger does NOT update the order doc itself,
 * so it cannot loop on its own writes.
 */

import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import { db, messaging, FieldValue } from "../lib/admin";

const CUSTOMER_LABELS: Record<string, string> = {
  paid: "Payment confirmed",
  preparing: "Your order is being prepared",
  dispatched: "Your order is on the way",
  delivered: "Order delivered",
  cancelled: "Order cancelled",
};

export const onOrderStatusChange = onDocumentUpdated(
  {
    document: "orders/{orderId}",
    region: "asia-south1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prev = before.status as string | undefined;
    const next = after.status as string | undefined;
    if (!next || prev === next) return;

    const orderId = event.params.orderId;
    const customerId = (after.customerId ?? before.customerId) as string;

    await db
      .collection("orders")
      .doc(orderId)
      .collection("statusHistory")
      .add({
        status: next,
        previousStatus: prev ?? null,
        changedAt: FieldValue.serverTimestamp(),
      });

    if (!customerId) return;

    const customerSnap = await db.collection("users").doc(customerId).get();
    const tokens = customerSnap.data()?.fcmTokens as unknown;
    if (!Array.isArray(tokens) || tokens.length === 0) {
      logger.info("onOrderStatusChange: no customer tokens", { orderId });
      return;
    }
    const validTokens = tokens.filter(
      (t): t is string => typeof t === "string" && t.length > 0,
    );
    if (validTokens.length === 0) return;

    try {
      await messaging.sendEachForMulticast({
        tokens: validTokens,
        notification: {
          title: CUSTOMER_LABELS[next] ?? `Order ${next}`,
          body: `Order #${orderId.slice(0, 6)}`,
        },
        data: { orderId, type: "order_status", status: next },
      });
    } catch (err) {
      logger.error("onOrderStatusChange: FCM send failed", { orderId, err });
    }
  },
);
