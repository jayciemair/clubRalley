import type { AuthProvider, AuthResult, Session } from "./types";
import { hashPassword, passwordProblem, verifyPassword } from "./hash";
import { BOARD_ID } from "@/config";
import { id } from "@/lib/ids";

/* Local, offline accounts. Stored in localStorage on this machine only.
   Good enough to build + demo the full sign-up / sign-in / reset flow;
   swapped for SupabaseAuth (real) once the project is wired. */

interface Account {
  userId: string;
  email: string;
  displayName: string;
  hash: string;
  resetCode?: string;
  resetExpires?: number;
}

const ACCT_KEY = `cr:accounts:${BOARD_ID}`;
const SESSION_KEY = `cr:session:${BOARD_ID}`;

function loadAccounts(): Record<string, Account> {
  try {
    return JSON.parse(localStorage.getItem(ACCT_KEY) || "{}");
  } catch {
    return {};
  }
}
function saveAccounts(a: Record<string, Account>) {
  try {
    localStorage.setItem(ACCT_KEY, JSON.stringify(a));
  } catch {
    /* ignore */
  }
}
const norm = (e: string) => e.trim().toLowerCase();

export class LocalAuth implements AuthProvider {
  readonly kind = "local" as const;
  private session: Session | null = null;
  private listeners = new Set<(s: Session | null) => void>();
  private joinCodeHash: string;

  constructor(joinCodeHash: string) {
    this.joinCodeHash = joinCodeHash;
  }

  async init(): Promise<Session | null> {
    try {
      const raw = localStorage.getItem(SESSION_KEY);
      this.session = raw ? JSON.parse(raw) : null;
    } catch {
      this.session = null;
    }
    return this.session;
  }

  current() {
    return this.session;
  }

  onChange(cb: (s: Session | null) => void) {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  private setSession(s: Session | null) {
    this.session = s;
    try {
      if (s) localStorage.setItem(SESSION_KEY, JSON.stringify(s));
      else localStorage.removeItem(SESSION_KEY);
    } catch {
      /* ignore */
    }
    for (const l of this.listeners) l(s);
  }

  async signUp(input: {
    email: string;
    password: string;
    displayName: string;
    joinCode: string;
  }): Promise<AuthResult> {
    const { checkPassword } = await import("@/lib/gate");
    if (!(await checkPassword(input.joinCode, this.joinCodeHash)))
      return { ok: false, error: "That workspace join code isn't right." };

    const pwProblem = passwordProblem(input.password);
    if (pwProblem) return { ok: false, error: pwProblem };
    if (!input.displayName.trim()) return { ok: false, error: "Add your name." };

    const accounts = loadAccounts();
    const email = norm(input.email);
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email))
      return { ok: false, error: "Enter a valid email." };
    if (accounts[email]) return { ok: false, error: "An account with that email already exists — sign in instead." };

    const acct: Account = {
      userId: id("u"),
      email,
      displayName: input.displayName.trim(),
      hash: await hashPassword(input.password),
    };
    accounts[email] = acct;
    saveAccounts(accounts);
    this.setSession({ userId: acct.userId, email, displayName: acct.displayName });
    return { ok: true };
  }

  async signIn(email: string, password: string): Promise<AuthResult> {
    const accounts = loadAccounts();
    const acct = accounts[norm(email)];
    if (!acct || !(await verifyPassword(password, acct.hash)))
      return { ok: false, error: "Email or password is wrong." };
    this.setSession({ userId: acct.userId, email: acct.email, displayName: acct.displayName });
    return { ok: true };
  }

  async signOut() {
    this.setSession(null);
  }

  async updatePassword(currentPassword: string, newPassword: string): Promise<AuthResult> {
    if (!this.session) return { ok: false, error: "Not signed in." };
    const accounts = loadAccounts();
    const acct = accounts[this.session.email];
    if (!acct || !(await verifyPassword(currentPassword, acct.hash)))
      return { ok: false, error: "Current password is wrong." };
    const problem = passwordProblem(newPassword);
    if (problem) return { ok: false, error: problem };
    acct.hash = await hashPassword(newPassword);
    saveAccounts(accounts);
    return { ok: true };
  }

  async requestReset(email: string) {
    const accounts = loadAccounts();
    const acct = accounts[norm(email)];
    // Don't reveal whether the account exists.
    if (!acct) return { ok: true as const };
    const code = String(Math.floor(100000 + Math.random() * 900000));
    acct.resetCode = code;
    acct.resetExpires = Date.now() + 15 * 60 * 1000;
    saveAccounts(accounts);
    return { ok: true as const, devCode: code };
  }

  async completeReset(email: string, code: string, newPassword: string): Promise<AuthResult> {
    const accounts = loadAccounts();
    const acct = accounts[norm(email)];
    if (!acct || acct.resetCode !== code || !acct.resetExpires || acct.resetExpires < Date.now())
      return { ok: false, error: "That reset code is wrong or expired." };
    const problem = passwordProblem(newPassword);
    if (problem) return { ok: false, error: problem };
    acct.hash = await hashPassword(newPassword);
    delete acct.resetCode;
    delete acct.resetExpires;
    saveAccounts(accounts);
    return { ok: true };
  }
}
