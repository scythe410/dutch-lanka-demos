/**
 * Unit tests for the PayHere hash + status helpers. These are pure
 * functions; no emulator required.
 *
 * Reference vector taken from PayHere's docs:
 *   merchant_id   = "1211149"
 *   merchant_secret = "MyMerchantSecret"
 *   order_id      = "OrderId123"
 *   amount        = "1000.00"
 *   currency      = "LKR"
 * The expected hash is recomputed directly so the tests don't drift if
 * the doc example changes — what matters is symmetry between
 * buildPaymentHash and buildNotifyHash.
 */

import * as crypto from "crypto";
import {
  buildPaymentHash,
  buildNotifyHash,
  formatAmount,
  mapStatusCode,
} from "../src/lib/payhere";

const md5Upper = (s: string) =>
  crypto.createHash("md5").update(s).digest("hex").toUpperCase();

describe("payhere helpers", () => {
  describe("formatAmount", () => {
    it("formats integer cents to 2-decimal string", () => {
      expect(formatAmount(1)).toBe("0.01");
      expect(formatAmount(100)).toBe("1.00");
      expect(formatAmount(35000)).toBe("350.00");
      expect(formatAmount(250000)).toBe("2500.00");
    });
  });

  describe("buildPaymentHash", () => {
    it("matches the documented PayHere formula", () => {
      const merchantId = "1211149";
      const merchantSecret = "MyMerchantSecret";
      const orderId = "OrderId123";
      const amount = "1000.00";
      const currency = "LKR";

      const expected = md5Upper(
        merchantId + orderId + amount + currency + md5Upper(merchantSecret),
      );

      expect(
        buildPaymentHash({
          merchantId,
          merchantSecret,
          orderId,
          amount,
          currency,
        }),
      ).toBe(expected);
    });

    it("is deterministic for identical inputs", () => {
      const args = {
        merchantId: "M",
        merchantSecret: "S",
        orderId: "O",
        amount: "10.00",
        currency: "LKR",
      };
      expect(buildPaymentHash(args)).toBe(buildPaymentHash(args));
    });
  });

  describe("buildNotifyHash", () => {
    it("matches the documented notify formula (includes status_code)", () => {
      const merchantId = "1211149";
      const merchantSecret = "MyMerchantSecret";
      const orderId = "OrderId123";
      const amount = "1000.00";
      const currency = "LKR";
      const statusCode = "2";

      const expected = md5Upper(
        merchantId +
          orderId +
          amount +
          currency +
          statusCode +
          md5Upper(merchantSecret),
      );

      expect(
        buildNotifyHash({
          merchantId,
          merchantSecret,
          orderId,
          amount,
          currency,
          statusCode,
        }),
      ).toBe(expected);
    });

    it("differs from payment hash for the same other inputs", () => {
      const base = {
        merchantId: "M",
        merchantSecret: "S",
        orderId: "O",
        amount: "10.00",
        currency: "LKR",
      };
      const payment = buildPaymentHash(base);
      const notify = buildNotifyHash({ ...base, statusCode: "2" });
      expect(payment).not.toBe(notify);
    });
  });

  describe("mapStatusCode", () => {
    it("maps 2 to paid + paid", () => {
      expect(mapStatusCode("2")).toEqual({
        paymentStatus: "paid",
        orderStatus: "paid",
      });
    });
    it("maps 0 to pending + null (no order transition)", () => {
      expect(mapStatusCode("0")).toEqual({
        paymentStatus: "pending",
        orderStatus: null,
      });
    });
    it("maps -1 (cancelled) to failed + cancelled", () => {
      expect(mapStatusCode("-1")).toEqual({
        paymentStatus: "failed",
        orderStatus: "cancelled",
      });
    });
    it("maps -2 (failed) to failed + cancelled", () => {
      expect(mapStatusCode("-2")).toEqual({
        paymentStatus: "failed",
        orderStatus: "cancelled",
      });
    });
    it("maps -3 (chargedback) to refunded + null (manager handles)", () => {
      expect(mapStatusCode("-3")).toEqual({
        paymentStatus: "refunded",
        orderStatus: null,
      });
    });
    it("falls back to pending + null on unknown codes", () => {
      expect(mapStatusCode("99")).toEqual({
        paymentStatus: "pending",
        orderStatus: null,
      });
      expect(mapStatusCode("")).toEqual({
        paymentStatus: "pending",
        orderStatus: null,
      });
    });
  });
});
