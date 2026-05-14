/**
 * Seeds the Firestore + Auth emulators with real Dutch Lanka menu data from
 * scraper/menu.json. Also uploads product images to Firebase Storage if
 * scraper/images/ is present alongside this script.
 *
 * Usage (from /functions): `npm run seed`
 * Or directly:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 \
 *   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
 *   FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199 \
 *   GCLOUD_PROJECT=dutch-lanka-dev \
 *   tsx ../tools/seed.ts
 *
 * Refuses to run unless the emulator env vars are set — never run this
 * against a real project unless you explicitly opt in by setting
 * ALLOW_DEPLOYED_SEED=1 plus GOOGLE_APPLICATION_CREDENTIALS pointing at a
 * service-account key for the target project.
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

const usingEmulator =
  !!process.env.FIRESTORE_EMULATOR_HOST && !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
const allowDeployedSeed = process.env.ALLOW_DEPLOYED_SEED === '1';

if (!usingEmulator && !allowDeployedSeed) {
  console.error(
    '\n[seed] Refusing to run: FIRESTORE_EMULATOR_HOST and ' +
      'FIREBASE_AUTH_EMULATOR_HOST must both be set.\n' +
      '       Run via `npm run seed` from /functions, or start the emulator first.\n' +
      '       To seed a deployed project on purpose, set ALLOW_DEPLOYED_SEED=1\n' +
      '       and GOOGLE_APPLICATION_CREDENTIALS to a service-account key path.\n'
  );
  process.exit(1);
}

if (allowDeployedSeed && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    '\n[seed] ALLOW_DEPLOYED_SEED=1 set, but GOOGLE_APPLICATION_CREDENTIALS\n' +
      '       is missing — refusing to run anonymously against a real project.\n'
  );
  process.exit(1);
}

const projectId = process.env.GCLOUD_PROJECT ?? 'dutch-lanka-dev';
const storageBucket = process.env.STORAGE_BUCKET ?? `${projectId}.firebasestorage.app`;

admin.initializeApp({projectId, storageBucket});

console.log(
  `[seed] target: ${usingEmulator ? 'EMULATOR' : 'DEPLOYED'} ` +
    `project=${projectId}`
);

const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

// ---------------------------------------------------------------------------
// Menu data
// ---------------------------------------------------------------------------

interface RawMenuItem {
  name: string;
  description: string | null;
  price: number;
  imageUrl: string;
}

interface SeedProduct {
  id: string;
  name: string;
  description: string;
  category: string;
  priceCents: number;
  stock: number;
  lowStockThreshold: number;
  imagePath: string;
}

function slugFromImageUrl(imageUrl: string): string {
  return path.basename(imageUrl, path.extname(imageUrl));
}

function normalizeCategory(raw: string): string {
  return raw
    .replace(/ \(One Portion\)/g, '')
    .replace(/Mangolian/g, 'Mongolian')
    .trim();
}

const menuPath = path.join(__dirname, '../scraper/menu.json');
const menuData = JSON.parse(fs.readFileSync(menuPath, 'utf-8')) as {
  categories: Array<{name: string; items: RawMenuItem[]}>;
};

// Collect unique products — first occurrence per slug wins (stable dedup).
const seenSlugs = new Set<string>();
const products: SeedProduct[] = [];

for (const cat of menuData.categories) {
  const category = normalizeCategory(cat.name);
  for (const item of cat.items) {
    const slug = slugFromImageUrl(item.imageUrl);
    if (seenSlugs.has(slug)) continue;
    seenSlugs.add(slug);
    products.push({
      id: slug,
      name: item.name,
      description: item.description ?? '',
      category,
      priceCents: Math.round(item.price * 100),
      stock: 100,
      lowStockThreshold: 10,
      imagePath: `products/${slug}/main.jpg`,
    });
  }
}

// ---------------------------------------------------------------------------
// Image upload
// ---------------------------------------------------------------------------

async function uploadImages(): Promise<void> {
  const imagesDir = path.join(__dirname, '../scraper/images');
  if (!fs.existsSync(imagesDir)) {
    console.log('[seed] scraper/images not found — skipping image upload');
    return;
  }

  let uploaded = 0;
  let skipped = 0;
  let failed = 0;

  for (const product of products) {
    const localPath = path.join(imagesDir, `${product.id}.jpeg`);
    if (!fs.existsSync(localPath)) {
      console.warn(`[seed] image missing: ${product.id}.jpeg`);
      skipped++;
      continue;
    }
    try {
      await bucket.upload(localPath, {
        destination: product.imagePath,
        metadata: {contentType: 'image/jpeg'},
        resumable: false,
      });
      uploaded++;
    } catch (err) {
      console.warn(`[seed] upload failed for ${product.id}.jpeg:`, (err as Error).message);
      failed++;
    }
  }

  console.log(
    `[seed] images — uploaded: ${uploaded}, skipped: ${skipped}, failed: ${failed}`
  );
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

async function ensureUser(opts: {
  uid: string;
  email: string;
  password: string;
  displayName: string;
  role: 'customer' | 'manager';
}): Promise<void> {
  try {
    await auth.getUser(opts.uid);
    await auth.updateUser(opts.uid, {
      email: opts.email,
      password: opts.password,
      displayName: opts.displayName,
      emailVerified: true,
    });
  } catch {
    await auth.createUser({
      uid: opts.uid,
      email: opts.email,
      password: opts.password,
      displayName: opts.displayName,
      emailVerified: true,
    });
  }
  await auth.setCustomUserClaims(opts.uid, {role: opts.role});
  await db.collection('users').doc(opts.uid).set({
    email: opts.email,
    emailVerified: true,
    name: opts.displayName,
    role: opts.role,
    fcmTokens: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`[seed] user ${opts.role}: ${opts.email}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function seed(): Promise<void> {
  console.log('[seed] writing demo users…');
  await ensureUser({
    uid: 'demo-customer',
    email: 'customer@dutchlanka.test',
    password: 'password123',
    displayName: 'Demo Customer',
    role: 'customer',
  });
  await ensureUser({
    uid: 'demo-manager',
    email: 'manager@dutchlanka.test',
    password: 'password123',
    displayName: 'Demo Manager',
    role: 'manager',
  });

  console.log('[seed] uploading product images…');
  await uploadImages();

  console.log('[seed] writing products…');
  // Firestore batch limit is 500 writes; ~60 items fits in one batch.
  const batch = db.batch();
  for (const p of products) {
    batch.set(db.collection('products').doc(p.id), {
      name: p.name,
      description: p.description,
      category: p.category,
      priceCents: p.priceCents,
      stock: p.stock,
      lowStockThreshold: p.lowStockThreshold,
      available: true,
      customizable: false,
      imagePath: p.imagePath,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  console.log(`[seed] wrote ${products.length} products across categories:`);
  const cats = [...new Set(products.map((p) => p.category))].sort();
  for (const cat of cats) {
    const count = products.filter((p) => p.category === cat).length;
    console.log(`  ${cat}: ${count}`);
  }
  console.log('[seed] done.');
}

seed().catch((err) => {
  console.error('[seed] failed:', err);
  process.exit(1);
});
