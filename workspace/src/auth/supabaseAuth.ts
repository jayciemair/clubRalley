import { createClient, type Session as SbSession, type SupabaseClient } from "@supabase/supabase-js";
import type { AuthProvider, AuthResult, Session } from "./types";
import { passwordProblem } from "./hash";

/* Real accounts on Club Ralley's own Supabase project.

   - The join code never ships to the browser: sign-up calls the
     `check_join_code` RPC (security definer, supabase/schema.sql), which
     checks a salted hash server-side.
   - Passwords are Supabase's problem from here — hashed and stored server-side,
     never touch this file.
   - Password reset: `resetPasswordForEmail` emails a link that signs the user
     back in (Supabase's standard flow). There's no separate "code" step like
     local mode — `completeReset` isn't used in this mode; the UI should just
     ask them to check email, then set a new password from Account once
     they're back in. */
export class SupabaseAuth implements AuthProvider {
  readonly kind = "supabase" as const;
  private sb: SupabaseClient;
  private session: Session | null = null;
  private listeners = new Set<(s: Session | null) => void>();

  constructor(url: string, anonKey: string) {
    this.sb = createClient(url, anonKey);
    this.sb.auth.onAuthStateChange((_event, sbSession) => {
      this.session = toSession(sbSession);
      for (const l of this.listeners) l(this.session);
    });
  }

  async init(): Promise<Session | null> {
    const { data } = await this.sb.auth.getSession();
    this.session = toSession(data.session);
    return this.session;
  }

  current() {
    return this.session;
  }

  onChange(cb: (s: Session | null) => void) {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  async signUp(input: {
    email: string;
    password: string;
    displayName: string;
    joinCode: string;
  }): Promise<AuthResult> {
    if (!input.displayName.trim()) return { ok: false, error: "Add your name." };
    const pwProblem = passwordProblem(input.password);
    if (pwProblem) return { ok: false, error: pwProblem };

    const code = await this.sb.rpc("check_join_code", { candidate: input.joinCode });
    if (code.error) return { ok: false, error: "Couldn't verify the join code right now." };
    if (!code.data) return { ok: false, error: "That workspace join code isn't right." };

    const { error } = await this.sb.auth.signUp({
      email: input.email.trim(),
      password: input.password,
      options: { data: { display_name: input.displayName.trim() } },
    });
    if (error) return { ok: false, error: friendlyError(error.message) };
    return { ok: true };
  }

  async signIn(email: string, password: string): Promise<AuthResult> {
    const { error } = await this.sb.auth.signInWithPassword({ email: email.trim(), password });
    if (error) return { ok: false, error: "Email or password is wrong." };
    return { ok: true };
  }

  async signOut() {
    await this.sb.auth.signOut();
  }

  async updatePassword(currentPassword: string, newPassword: string): Promise<AuthResult> {
    if (!this.session) return { ok: false, error: "Not signed in." };
    const problem = passwordProblem(newPassword);
    if (problem) return { ok: false, error: problem };
    // Re-verify the current password before changing it (Supabase trusts the
    // active session and won't ask on its own).
    const check = await this.sb.auth.signInWithPassword({
      email: this.session.email,
      password: currentPassword,
    });
    if (check.error) return { ok: false, error: "Current password is wrong." };
    const { error } = await this.sb.auth.updateUser({ password: newPassword });
    if (error) return { ok: false, error: friendlyError(error.message) };
    return { ok: true };
  }

  async requestReset(email: string) {
    const { error } = await this.sb.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: window.location.origin,
    });
    // Don't reveal whether the account exists either way.
    if (error && !/user not found/i.test(error.message)) {
      return { ok: false as const, error: friendlyError(error.message) };
    }
    return { ok: true as const };
  }

  async completeReset(): Promise<AuthResult> {
    return {
      ok: false,
      error: "Use the link in the email we sent — it signs you in, then set a new password from Account.",
    };
  }
}

function toSession(sbSession: SbSession | null): Session | null {
  if (!sbSession?.user) return null;
  const u = sbSession.user;
  return {
    userId: u.id,
    email: u.email ?? "",
    displayName: (u.user_metadata?.display_name as string | undefined) || u.email || "",
  };
}

function friendlyError(msg: string): string {
  if (/already registered/i.test(msg)) return "An account with that email already exists — sign in instead.";
  if (/rate limit/i.test(msg)) return "Too many attempts — wait a bit and try again.";
  return msg;
}
