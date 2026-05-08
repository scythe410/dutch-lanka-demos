/**
 * Firestore security-rules tests. Run via `npm run test:rules` which spins
 * up the Firestore emulator with `firebase emulators:exec` so the rules
 * file is loaded and exercised against real client requests.
 */

import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "dutch-lanka-test",
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "..", "..", "firestore.rules"),
        "utf8"
      ),
      host: "localhost",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

const customer = (uid: string) =>
  testEnv.authenticatedContext(uid, { role: "customer" });
const manager = (uid: string) =>
  testEnv.authenticatedContext(uid, { role: "manager" });

describe("orders", () => {
  it("customer cannot read another customer's order", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "orders/o-alice"), {
        customerId: "alice",
        total: 1000,
      });
    });

    const bob = customer("bob");
    await assertFails(getDoc(doc(bob.firestore(), "orders/o-alice")));
  });

  it("customer can read their own order", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "orders/o-alice"), {
        customerId: "alice",
        total: 1000,
      });
    });

    const alice = customer("alice");
    await assertSucceeds(getDoc(doc(alice.firestore(), "orders/o-alice")));
  });

  it("nobody can write directly to /orders — even managers", async () => {
    const alice = customer("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "orders/o-new"), {
        customerId: "alice",
        total: 1000,
      })
    );

    const boss = manager("boss");
    await assertFails(
      setDoc(doc(boss.firestore(), "orders/o-new-2"), {
        customerId: "alice",
        total: 1000,
      })
    );
  });
});

describe("products", () => {
  it("customer cannot write to /products", async () => {
    const alice = customer("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "products/p1"), {
        name: "Hacked",
        priceCents: 1,
      })
    );
  });

  it("manager can write to /products", async () => {
    const boss = manager("boss");
    await assertSucceeds(
      setDoc(doc(boss.firestore(), "products/p1"), {
        name: "Croissant",
        priceCents: 35000,
        stock: 10,
      })
    );
  });
});
