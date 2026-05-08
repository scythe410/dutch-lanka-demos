/**
 * setManagerRole — callable Cloud Function. Per architecture.md §6:
 *
 *   - Only an existing manager can promote another user to `manager` or
 *     `staff`. (The first manager has to be created out-of-band — see the
 *     bootstrap notes in docs/progress.md / README.)
 *   - Sets the `role` custom claim on the target user (`manager` / `staff`
 *     / `customer`) and mirrors it onto `/users/{uid}.role` for UI
 *     convenience. The claim is the source of truth.
 *
 * Inputs are validated by Zod. The caller's claim is read straight from
 * `request.auth.token.role` (the verified claim Firebase already attached
 * to the call), so no extra DB round-trip is needed.
 */

import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

import { admin, db } from "../lib/admin";

const InputSchema = z.object({
  targetUid: z.string().min(1),
  role: z.enum(["manager", "staff", "customer"]),
});

export type SetManagerRoleInput = z.infer<typeof InputSchema>;

export const setManagerRole = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const callerRole = request.auth.token.role;
    if (callerRole !== "manager") {
      throw new HttpsError(
        "permission-denied",
        "Only managers can change roles."
      );
    }

    const parsed = InputSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", parsed.error.message);
    }
    const { targetUid, role } = parsed.data;

    // Refuse self-demotion — a sole manager could otherwise lock the
    // organization out of role management entirely. Architecture doesn't
    // mandate this, but it's the minimum safety rail.
    if (targetUid === request.auth.uid && role !== "manager") {
      throw new HttpsError(
        "failed-precondition",
        "You cannot remove your own manager role."
      );
    }

    // Set the claim. `setCustomUserClaims` replaces the entire claims
    // object — re-read existing claims and merge so we don't drop other
    // claims that may exist later.
    const target = await admin.auth().getUser(targetUid);
    const existingClaims = target.customClaims ?? {};
    await admin.auth().setCustomUserClaims(targetUid, {
      ...existingClaims,
      role,
    });

    // Mirror to /users/{uid}.role for UI lists. Bypasses the `update`
    // rule (which forbids writing `role`) by virtue of running on the
    // admin SDK.
    await db.collection("users").doc(targetUid).set(
      { role, uid: targetUid },
      { merge: true }
    );

    return { ok: true, targetUid, role };
  }
);
