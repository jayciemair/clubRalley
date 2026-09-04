export interface Session {
  userId: string;
  email: string;
  displayName: string;
}

export type AuthResult =
  | { ok: true }
  | { ok: false; error: string };

export interface AuthProvider {
  readonly kind: "local" | "supabase";

  /** Current session, or null. Resolves once the provider has checked storage. */
  init(): Promise<Session | null>;
  current(): Session | null;
  onChange(cb: (s: Session | null) => void): () => void;

  signUp(input: {
    email: string;
    password: string;
    displayName: string;
    joinCode: string;
  }): Promise<AuthResult>;

  signIn(email: string, password: string): Promise<AuthResult>;
  signOut(): Promise<void>;

  /** Change the password of the signed-in user. */
  updatePassword(currentPassword: string, newPassword: string): Promise<AuthResult>;

  /** Kick off a reset. Local mode returns a one-time code; Supabase emails a link. */
  requestReset(email: string): Promise<{ ok: true; devCode?: string } | { ok: false; error: string }>;
  completeReset(email: string, code: string, newPassword: string): Promise<AuthResult>;
}
