/**
 * Integration tests for the `onOrderCreate` Firestore trigger. Verifies:
 *   - stock decrements deterministically for a single order
 *   - low-stock alerts written when threshold is crossed
 *   - concurrent triggers do not oversell (transactional safety)
 *
 * The handler is invoked via firebase-functions-test wrap with a
 * synthesised Firestore event. FCM dispatch is exercised but with no
 * manager tokens seeded — the function logs and skips, leaving stock
 * behaviour as the assertable surface.
 */

import functionsTest from "firebase-functions-test";

const ftest = functionsTest();
import { onOrderCreate } from "../src/functions/onOrderCreate";
import { clearFirestore, db, seedProduct } from "./helpers/emulator";

const wrapped = ftest.wrap(onOrderCreate);

afterAll(() => {
  ftest.cleanup();
});

beforeEach(async () => {
  await clearFirestore();
});

async function makeOrderEvent(orderId: string, items: Array<{
  productId: string;
  name: string;
  qty: number;
  unitPriceCents: number;
}>) {
  const data = {
    customerId: "u-cust-1",
    items,
    totalCents: items.reduce(
      (sum, i) => sum + i.qty * i.unitPriceCents,
      0,
    ),
    status: "pending_payment",
    paymentStatus: "pending",
  };
  await db.collection("orders").doc(orderId).set(data);
  const snap = await db.collection("orders").doc(orderId).get();
  return ftest.firestore.makeDocumentSnapshot(snap.data()!, `orders/${orderId}`);
}

describe("onOrderCreate", () => {
  it("decrements stock for each line item", async () => {
    await seedProduct("croissant", {
      name: "Butter Croissant",
      priceCents: 35000,
      stock: 25,
      lowStockThreshold: 5,
      available: true,
    });

    const event = await makeOrderEvent("order-1", [
      { productId: "croissant", name: "Butter Croissant", qty: 3, unitPriceCents: 35000 },
    ]);

    await wrapped({ data: event, params: { orderId: "order-1" } });

    const product = await db.collection("products").doc("croissant").get();
    expect(product.data()?.stock).toBe(22);
  });

  it("writes a low-stock alert only when threshold is crossed", async () => {
    await seedProduct("eclair", {
      name: "Chocolate Eclair",
      priceCents: 32000,
      stock: 6, // threshold = 5; ordering 2 leaves 4 → crosses
      lowStockThreshold: 5,
      available: true,
    });

    const event = await makeOrderEvent("order-2", [
      { productId: "eclair", name: "Chocolate Eclair", qty: 2, unitPriceCents: 32000 },
    ]);
    await wrapped({ data: event, params: { orderId: "order-2" } });

    const alerts = await db.collection("lowStockAlerts").get();
    expect(alerts.size).toBe(1);
    const alert = alerts.docs[0].data();
    expect(alert.productId).toBe("eclair");
    expect(alert.currentStock).toBe(4);
    expect(alert.threshold).toBe(5);
    expect(alert.acknowledged).toBe(false);
  });

  it("does not write a duplicate alert for an already-low product", async () => {
    await seedProduct("loaf", {
      name: "Milk Bread",
      priceCents: 28000,
      stock: 3, // already below threshold
      lowStockThreshold: 5,
      available: true,
    });

    const event = await makeOrderEvent("order-3", [
      { productId: "loaf", name: "Milk Bread", qty: 1, unitPriceCents: 28000 },
    ]);
    await wrapped({ data: event, params: { orderId: "order-3" } });

    const alerts = await db.collection("lowStockAlerts").get();
    expect(alerts.size).toBe(0);
    const product = await db.collection("products").doc("loaf").get();
    expect(product.data()?.stock).toBe(2);
  });

  it("decrements atomically under concurrent triggers (no oversell)", async () => {
    await seedProduct("cake", {
      name: "Birthday Cake 1lb",
      priceCents: 250000,
      stock: 10,
      lowStockThreshold: 2,
      available: true,
    });

    // Fire ten orders for one cake each at the same time. Final stock
    // must be exactly zero — never negative — and never collide on a
    // shared read.
    const events = await Promise.all(
      Array.from({ length: 10 }, (_, i) =>
        makeOrderEvent(`order-c-${i}`, [
          {
            productId: "cake",
            name: "Birthday Cake 1lb",
            qty: 1,
            unitPriceCents: 250000,
          },
        ]),
      ),
    );

    await Promise.all(
      events.map((event, i) =>
        wrapped({ data: event, params: { orderId: `order-c-${i}` } }),
      ),
    );

    const product = await db.collection("products").doc("cake").get();
    expect(product.data()?.stock).toBe(0);
  });
});
