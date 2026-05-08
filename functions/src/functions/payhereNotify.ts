/**
 * payhereNotify — HTTPS endpoint that PayHere posts to after a checkout.
 * THIS IS THE ONLY AUTHORITATIVE WRITER FOR `paymentStatus` (CLAUDE.md
 * rule 2). The PayHere SDK's success callback is NOT trusted; the client
 * shows "processing" and listens on the order doc until this endpoint
 * flips it to `paid`.
 *
 * Contract (form-urlencoded body, per PayHere docs):
 *   merchant_id, order_id, payment_id,
 *   payhere_amount, payhere_currency,
 *   status_code, md5sig, ...
 *
 * Status codes:
 *    "2" success | "0" pending | "-1" cancelled | "-2" failed | "-3" chargedback
 *
 * Mismatched signatures return 401. Anything else returns 200 so PayHere
 * doesn't retry-storm us; failures are logged via the structured logger.
 */

import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import type { Request, Response } from "express";

import { db, FieldValue } from "../lib/admin";
import { buildNotifyHash, mapStatusCode } from "../lib/payhere";

const PAYHERE_MERCHANT_ID = defineString("PAYHERE_MERCHANT_ID");
const PAYHERE_MERCHANT_SECRET = defineSecret("PAYHERE_MERCHANT_SECRET");

/**
 * Pure async handler — exported so Jest can drive it directly without
 * the cors / trace middleware that v2 onRequest wraps the user handler
 * with. The wrappers don't propagate the inner promise, which races
 * against the async Firestore update we issue here.
 * @param {Request} req incoming POST from PayHere.
 * @param {Response} res response to PayHere.
 * @param {object} cfg merchant config (injected for testability).
 * @return {Promise<void>}
 */
export async function handlePayhereNotify(
  req: Request,
  res: Response,
  cfg: {merchantId: string; merchantSecret: string},
): Promise<void> {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const body = req.body ?? {};
  const merchantId = String(body.merchant_id ?? "");
  const orderId = String(body.order_id ?? "");
  const paymentId = String(body.payment_id ?? "");
  const amount = String(body.payhere_amount ?? "");
  const currency = String(body.payhere_currency ?? "");
  const statusCode = String(body.status_code ?? "");
  const md5sig = String(body.md5sig ?? "");

  if (!merchantId || !orderId || !statusCode || !md5sig) {
    res.status(400).send("Missing required fields");
    return;
  }

  if (merchantId !== cfg.merchantId) {
    // Don't even hint at why — possible probe.
    res.status(401).send("Invalid signature");
    return;
  }

  const expected = buildNotifyHash({
    merchantId,
    merchantSecret: cfg.merchantSecret,
    orderId,
    amount,
    currency,
    statusCode,
  });

  if (md5sig !== expected) {
    logger.warn("payhereNotify: bad signature", { orderId });
    res.status(401).send("Invalid signature");
    return;
  }

  const { paymentStatus, orderStatus } = mapStatusCode(statusCode);

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    logger.warn("payhereNotify: unknown order", { orderId });
    res.status(200).send("OK");
    return;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const update: Record<string, any> = {
    paymentStatus,
    payherePaymentId: paymentId || null,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (orderStatus) {
    update.status = orderStatus;
    if (orderStatus === "paid") {
      update.paidAt = FieldValue.serverTimestamp();
    }
  }

  await orderRef.update(update);

  logger.info("payhereNotify: applied", {
    orderId,
    statusCode,
    paymentStatus,
    orderStatus,
  });

  res.status(200).send("OK");
}

export const payhereNotify = onRequest(
  {
    region: "asia-south1",
    secrets: [PAYHERE_MERCHANT_SECRET],
    cors: false,
  },
  (req, res) =>
    handlePayhereNotify(req, res, {
      merchantId: PAYHERE_MERCHANT_ID.value(),
      merchantSecret: PAYHERE_MERCHANT_SECRET.value(),
    }),
);
