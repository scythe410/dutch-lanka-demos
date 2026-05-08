/**
 * Test helpers for the firestore emulator. Imported by every integration
 * test so seed/clear logic stays consistent.
 */

import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "demo-test" });
}

export const db = admin.firestore();

interface SeedProductInput {
  name: string;
  priceCents: number;
  stock: number;
  lowStockThreshold: number;
  available?: boolean;
  category?: string;
}

/**
 * Write a product doc to the emulator. Caller supplies the doc id so
 * tests can reference it by name.
 * @param {string} id product id.
 * @param {SeedProductInput} input product fields.
 * @return {Promise<void>}
 */
export async function seedProduct(
  id: string,
  input: SeedProductInput,
): Promise<void> {
  await db
    .collection("products")
    .doc(id)
    .set({
      name: input.name,
      priceCents: input.priceCents,
      stock: input.stock,
      lowStockThreshold: input.lowStockThreshold,
      available: input.available ?? true,
      category: input.category ?? "pastry",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Wipe every collection used by the function tests. Cheaper than
 * restarting the emulator between cases.
 * @return {Promise<void>}
 */
export async function clearFirestore(): Promise<void> {
  for (const collection of [
    "orders",
    "products",
    "users",
    "lowStockAlerts",
  ]) {
    const snap = await db.collection(collection).get();
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    if (snap.size > 0) await batch.commit();
  }
}
