/**
 * Integration tests for the `setManagerRole` callable. Runs against the
 * Firestore emulator for the `/users/{uid}.role` mirror; the Auth side
 * is mocked because we don't need to spin up the auth emulator just to
 * verify the call surface.
 */

import * as admin from "firebase-admin";
import functionsTest from "firebase-functions-test";

import { db } from "./helpers/emulator";

const ftest = functionsTest();

import { setManagerRole } from "../src/functions/setManagerRole";

const wrapped = ftest.wrap(setManagerRole) as unknown as (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  req: { data: any; auth?: any }
// eslint-disable-next-line @typescript-eslint/no-explicit-any
) => Promise<any>;

interface ClaimsByUid {
  [uid: string]: Record<string, unknown>;
}

let setClaimsCalls: { uid: string; claims: Record<string, unknown> }[] = [];
let claimsByUid: ClaimsByUid = {};

beforeAll(() => {
  // Stub `admin.auth()` so getUser returns a stored claim set and
  // setCustomUserClaims records the call. We re-create the spy in
  // beforeAll so it survives across tests.
  jest.spyOn(admin, "auth").mockImplementation((() => ({
    getUser: async (uid: string) => ({
      uid,
      customClaims: claimsByUid[uid] ?? {},
    }),
    setCustomUserClaims: async (
      uid: string,
      claims: Record<string, unknown>
    ) => {
      setClaimsCalls.push({ uid, claims });
      claimsByUid[uid] = claims;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  })) as any);
});

afterAll(() => {
  ftest.cleanup();
  jest.restoreAllMocks();
});

// Each test uses a unique uid prefix so we don't collide with other test
// files that run in parallel against the same firestore emulator.
const uid = (name: string) => `smr-${name}-${Date.now().toString(36)}`;

beforeEach(() => {
  setClaimsCalls = [];
  claimsByUid = {};
});

afterEach(async () => {
  // Clean up only our own /users docs to keep the emulator tidy without
  // stomping on parallel test data.
  const snap = await db
    .collection("users")
    .where("uid", ">=", "smr-")
    .where("uid", "<", "smr.")
    .get();
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  if (snap.size > 0) await batch.commit();
});

const managerAuth = (uid: string) => ({
  uid,
  token: { role: "manager" },
  rawToken: "test",
});

describe("setManagerRole", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      wrapped({ data: { targetUid: uid("target"), role: "manager" } })
    ).rejects.toThrow(/Sign in required/);
  });

  it("rejects callers whose role claim is not 'manager'", async () => {
    const target = uid("target");
    await expect(
      wrapped({
        data: { targetUid: target, role: "manager" },
        auth: { uid: uid("customer"), token: { role: "customer" }, rawToken: "t" },
      })
    ).rejects.toThrow(/Only managers/);

    await expect(
      wrapped({
        data: { targetUid: target, role: "manager" },
        auth: { uid: uid("staff"), token: { role: "staff" }, rawToken: "t" },
      })
    ).rejects.toThrow(/Only managers/);

    expect(setClaimsCalls).toHaveLength(0);
  });

  it("rejects bad input shape", async () => {
    await expect(
      wrapped({
        data: { targetUid: uid("target"), role: "ceo" },
        auth: managerAuth(uid("mgr")),
      })
    ).rejects.toThrow();
  });

  it("manager can promote another user to manager and the claim updates", async () => {
    const target = uid("target");
    const mgr = uid("mgr");
    const result = await wrapped({
      data: { targetUid: target, role: "manager" },
      auth: managerAuth(mgr),
    });

    expect(result).toMatchObject({ ok: true, targetUid: target, role: "manager" });
    expect(setClaimsCalls).toEqual([
      { uid: target, claims: { role: "manager" } },
    ]);

    const mirror = await db.collection("users").doc(target).get();
    expect(mirror.data()).toMatchObject({ role: "manager", uid: target });
  });

  it("manager can promote a user to staff", async () => {
    const target = uid("target");
    await wrapped({
      data: { targetUid: target, role: "staff" },
      auth: managerAuth(uid("mgr")),
    });
    expect(claimsByUid[target]).toEqual({ role: "staff" });
    const mirror = await db.collection("users").doc(target).get();
    expect(mirror.data()).toMatchObject({ role: "staff" });
  });

  it("preserves existing custom claims when updating role", async () => {
    const target = uid("target");
    claimsByUid[target] = { region: "lk", flag: true };
    await wrapped({
      data: { targetUid: target, role: "manager" },
      auth: managerAuth(uid("mgr")),
    });
    expect(claimsByUid[target]).toEqual({
      region: "lk",
      flag: true,
      role: "manager",
    });
  });

  it("refuses self-demotion", async () => {
    const mgr = uid("mgr");
    await expect(
      wrapped({
        data: { targetUid: mgr, role: "customer" },
        auth: managerAuth(mgr),
      })
    ).rejects.toThrow(/cannot remove your own manager role/);
    expect(setClaimsCalls).toHaveLength(0);
  });

  it("manager may keep their own role at manager (idempotent)", async () => {
    const mgr = uid("mgr");
    await wrapped({
      data: { targetUid: mgr, role: "manager" },
      auth: managerAuth(mgr),
    });
    expect(claimsByUid[mgr]).toEqual({ role: "manager" });
  });
});
