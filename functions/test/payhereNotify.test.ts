/**
 * Integration tests for the `payhereNotify` HTTPS Function. Verifies:
 *   - bad MD5 → 401, no doc mutation
 *   - status_code "2"  → paymentStatus=paid,    status=paid
 *   - status_code "0"  → paymentStatus=pending, status unchanged
 *   - status_code "-1" → paymentStatus=failed,  status=cancelled
 *   - status_code "-2" → paymentStatus=failed,  status=cancelled
 *   - status_code "-3" → paymentStatus=refunded, status unchanged
 *
 * Calls the HTTPS handler directly with a fake req/res pair — that's the
 * Express-compatible signature firebase-functions v2 returns.
 */

import * as admin from "firebase-admin";
import { EventEmitter } from "events";

import { buildNotifyHash } from "../src/lib/payhere";
import { clearFirestore, db } from "./helpers/emulator";
import { handlePayhereNotify } from "../src/functions/payhereNotify";

const MERCHANT_ID = "test-merchant";
const MERCHANT_SECRET = "test-secret";

beforeEach(async () => {
  await clearFirestore();
});

// Minimal Express response mock. firebase-functions v2 wraps the user
// handler with logging that subscribes to the 'finish' event, so the
// stub must extend EventEmitter and emit on send().
class FakeRes extends EventEmitter {
  statusCode = 0;
  body = "";
  headersSent = false;
  status(code: number): this {
    this.statusCode = code;
    return this;
  }
  send(body: string): this {
    this.body = body;
    this.headersSent = true;
    this.emit("finish");
    return this;
  }
  setHeader(): this {
    return this;
  }
  end(): this {
    this.headersSent = true;
    this.emit("finish");
    return this;
  }
}

function makeRes(): FakeRes {
  return new FakeRes();
}

async function seedOrder(orderId: string, fields: Record<string, unknown> = {}) {
  await db
    .collection("orders")
    .doc(orderId)
    .set({
      customerId: "u-cust-1",
      totalCents: 100000,
      status: "pending_payment",
      paymentStatus: "pending",
      ...fields,
    });
}

function makeNotifyBody(args: {
  orderId: string;
  amount: string;
  statusCode: string;
  badSig?: boolean;
}) {
  const md5sig = args.badSig ?
    "DEADBEEFDEADBEEFDEADBEEFDEADBEEF" :
    buildNotifyHash({
      merchantId: MERCHANT_ID,
      merchantSecret: MERCHANT_SECRET,
      orderId: args.orderId,
      amount: args.amount,
      currency: "LKR",
      statusCode: args.statusCode,
    });

  return {
    merchant_id: MERCHANT_ID,
    order_id: args.orderId,
    payment_id: "ph-pay-001",
    payhere_amount: args.amount,
    payhere_currency: "LKR",
    status_code: args.statusCode,
    md5sig,
  };
}

async function callNotify(body: Record<string, string>) {
  const res = makeRes();
  const req = Object.assign(new EventEmitter(), {
    method: "POST",
    body,
    headers: { "content-type": "application/x-www-form-urlencoded" },
    rawBody: Buffer.from(""),
    url: "/payhereNotify",
  });
  await handlePayhereNotify(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    req as any,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    res as any,
    { merchantId: MERCHANT_ID, merchantSecret: MERCHANT_SECRET },
  );
  return res;
}

describe("payhereNotify", () => {
  it("rejects bad MD5 with 401 and does not mutate the order", async () => {
    await seedOrder("order-bad-sig");

    const res = await callNotify(
      makeNotifyBody({
        orderId: "order-bad-sig",
        amount: "1000.00",
        statusCode: "2",
        badSig: true,
      }),
    );

    expect(res.statusCode).toBe(401);
    const snap = await db.collection("orders").doc("order-bad-sig").get();
    expect(snap.data()?.paymentStatus).toBe("pending");
    expect(snap.data()?.status).toBe("pending_payment");
  });

  it("status_code 2 → paid (both paymentStatus and status)", async () => {
    await seedOrder("order-paid");

    const res = await callNotify(
      makeNotifyBody({
        orderId: "order-paid",
        amount: "1000.00",
        statusCode: "2",
      }),
    );

    expect(res.statusCode).toBe(200);
    const snap = await db.collection("orders").doc("order-paid").get();
    expect(snap.data()?.paymentStatus).toBe("paid");
    expect(snap.data()?.status).toBe("paid");
    expect(snap.data()?.paidAt).toBeDefined();
    expect(snap.data()?.payherePaymentId).toBe("ph-pay-001");
  });

  it("status_code 0 → pending, status unchanged", async () => {
    await seedOrder("order-pending");

    await callNotify(
      makeNotifyBody({
        orderId: "order-pending",
        amount: "1000.00",
        statusCode: "0",
      }),
    );

    const snap = await db.collection("orders").doc("order-pending").get();
    expect(snap.data()?.paymentStatus).toBe("pending");
    expect(snap.data()?.status).toBe("pending_payment");
  });

  it("status_code -1 (cancelled) → failed + cancelled", async () => {
    await seedOrder("order-cancelled");

    await callNotify(
      makeNotifyBody({
        orderId: "order-cancelled",
        amount: "1000.00",
        statusCode: "-1",
      }),
    );

    const snap = await db.collection("orders").doc("order-cancelled").get();
    expect(snap.data()?.paymentStatus).toBe("failed");
    expect(snap.data()?.status).toBe("cancelled");
  });

  it("status_code -2 (failed) → failed + cancelled", async () => {
    await seedOrder("order-failed");

    await callNotify(
      makeNotifyBody({
        orderId: "order-failed",
        amount: "1000.00",
        statusCode: "-2",
      }),
    );

    const snap = await db.collection("orders").doc("order-failed").get();
    expect(snap.data()?.paymentStatus).toBe("failed");
    expect(snap.data()?.status).toBe("cancelled");
  });

  it("status_code -3 (chargedback) → refunded, status unchanged", async () => {
    await seedOrder("order-chargedback", { status: "paid" });

    await callNotify(
      makeNotifyBody({
        orderId: "order-chargedback",
        amount: "1000.00",
        statusCode: "-3",
      }),
    );

    const snap = await db.collection("orders").doc("order-chargedback").get();
    expect(snap.data()?.paymentStatus).toBe("refunded");
    expect(snap.data()?.status).toBe("paid");
  });

  it("returns 200 (not 5xx) when the order is unknown — no PayHere retry storm", async () => {
    const res = await callNotify(
      makeNotifyBody({
        orderId: "order-does-not-exist",
        amount: "1000.00",
        statusCode: "2",
      }),
    );
    expect(res.statusCode).toBe(200);
  });

  it("rejects non-POST methods", async () => {
    const res = makeRes();
    const req = Object.assign(new EventEmitter(), {
      method: "GET",
      body: {},
      headers: {},
      rawBody: Buffer.from(""),
      url: "/payhereNotify",
    });
    await handlePayhereNotify(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      req as any,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      res as any,
      { merchantId: MERCHANT_ID, merchantSecret: MERCHANT_SECRET },
    );
    expect(res.statusCode).toBe(405);
  });

  // Touch admin import so ts/lint doesn't strip it.
  it("admin firestore is initialised against emulator", () => {
    expect(admin.apps.length).toBeGreaterThan(0);
  });
});
