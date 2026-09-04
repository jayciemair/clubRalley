/* The shared-password gate.

   This is deliberately a LIGHT gate — it keeps casual visitors out of a
   public URL. It is not a substitute for real auth: anyone technical who has
   the Supabase anon key (it's in the built JS) can read the database directly.
   See SECURITY.md for the model and the upgrade path to Supabase Auth.

   Improvement over the old app: we store a salted SHA-256 hash, never the
   password itself, so the password is not sitting in the page source. */

const SALT = "clubralley::v1::gate";

export async function hashPassword(pw: string): Promise<string> {
  const data = new TextEncoder().encode(SALT + "|" + pw.trim().toLowerCase());
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export async function checkPassword(pw: string, hash: string): Promise<boolean> {
  if (!hash) return true; // no gate set
  // Back-compat: the old app stored base64(password). Accept that too.
  try {
    if (typeof atob === "function") {
      const legacy = decodeURIComponent(escape(atob(hash)));
      if (legacy && legacy.trim().toLowerCase() === pw.trim().toLowerCase())
        return true;
    }
  } catch {
    /* not legacy base64 — fine */
  }
  return (await hashPassword(pw)) === hash;
}

const UNLOCKED_KEY = "cr:unlocked";

export function markUnlocked(boardId: string): void {
  try {
    sessionStorage.setItem(UNLOCKED_KEY + ":" + boardId, "1");
  } catch {
    /* private mode */
  }
}

export function isUnlocked(boardId: string): boolean {
  try {
    return sessionStorage.getItem(UNLOCKED_KEY + ":" + boardId) === "1";
  } catch {
    return false;
  }
}
