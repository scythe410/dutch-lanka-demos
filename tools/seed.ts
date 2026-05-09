/**
 * Seeds the Firestore + Auth emulators with sample data.
 *
 * Usage (from /functions): `npm run seed`
 * Or directly: `FIRESTORE_EMULATOR_HOST=localhost:8080
 *               FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
 *               tsx tools/seed.ts`
 *
 * Refuses to run unless the emulator env vars are set — never run this
 * against a real project unless you explicitly opt in by setting
 * ALLOW_DEPLOYED_SEED=1 plus GOOGLE_APPLICATION_CREDENTIALS pointing at a
 * service-account key for the target project.
 */

import * as admin from 'firebase-admin';

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

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT ?? 'dutch-lanka-dev'});

console.log(
  `[seed] target: ${usingEmulator ? 'EMULATOR' : 'DEPLOYED'} ` +
    `project=${process.env.GCLOUD_PROJECT ?? 'dutch-lanka-dev'}`
);
const db = admin.firestore();
const auth = admin.auth();

// All money in LKR cents (CLAUDE.md). 35000 = LKR 350.00.
type SeedProduct = {
  id: string;
  name: string;
  description: string;
  category: 'bread' | 'pastry' | 'cake';
  priceCents: number;
  stock: number;
  lowStockThreshold: number;
};

const products: SeedProduct[] = [
  {
    id: 'milk-bread-loaf',
    name: 'Milk Bread Loaf',
    description: 'Soft, slightly sweet white loaf — bakery staple.',
    category: 'bread',
    priceCents: 28000,
    stock: 30,
    lowStockThreshold: 5,
  },
  {
    id: 'kimbula-banis',
    name: 'Kimbula Banis',
    description: 'Crocodile-shaped sweet bun, sugar-glazed top.',
    category: 'bread',
    priceCents: 8000,
    stock: 60,
    lowStockThreshold: 10,
  },
  {
    id: 'seeni-sambol-bun',
    name: 'Seeni Sambol Bun',
    description: 'Soft bun stuffed with caramelised onion seeni sambol.',
    category: 'bread',
    priceCents: 12000,
    stock: 40,
    lowStockThreshold: 8,
  },
  {
    id: 'butter-croissant',
    name: 'Butter Croissant',
    description: 'Laminated, all-butter, baked fresh each morning.',
    category: 'pastry',
    priceCents: 35000,
    stock: 25,
    lowStockThreshold: 5,
  },
  {
    id: 'fish-bun',
    name: 'Fish Bun',
    description: 'Spiced tuna and potato wrapped in soft bread.',
    category: 'pastry',
    priceCents: 18000,
    stock: 50,
    lowStockThreshold: 10,
  },
  {
    id: 'chocolate-eclair',
    name: 'Chocolate Eclair',
    description: 'Choux pastry, vanilla cream, dark chocolate glaze.',
    category: 'pastry',
    priceCents: 32000,
    stock: 20,
    lowStockThreshold: 4,
  },
  {
    id: 'butter-cake-slice',
    name: 'Butter Cake (slice)',
    description: 'Dense, moist butter cake — a Sri Lankan tea-time classic.',
    category: 'cake',
    priceCents: 22000,
    stock: 35,
    lowStockThreshold: 6,
  },
  {
    id: 'chocolate-fudge-cake',
    name: 'Chocolate Fudge Cake (slice)',
    description: 'Three layers of chocolate sponge, fudge ganache.',
    category: 'cake',
    priceCents: 45000,
    stock: 15,
    lowStockThreshold: 3,
  },
  {
    id: 'love-cake-slice',
    name: 'Love Cake (slice)',
    description: 'Cashew, semolina, rose water — a Sri Lankan wedding cake.',
    category: 'cake',
    priceCents: 38000,
    stock: 10,
    lowStockThreshold: 2,
  },
  {
    id: 'birthday-cake-1lb',
    name: 'Birthday Cake — 1 lb',
    description: 'Vanilla sponge with buttercream. Custom message available.',
    category: 'cake',
    priceCents: 250000,
    stock: 8,
    lowStockThreshold: 2,
  },
];

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

  console.log('[seed] writing products…');
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
      customizable: p.id.startsWith('birthday-cake'),
      imagePath: `products/${p.id}/main.jpg`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`[seed] wrote ${products.length} products`);
  console.log('[seed] done.');
}

seed().catch((err) => {
  console.error('[seed] failed:', err);
  process.exit(1);
});
