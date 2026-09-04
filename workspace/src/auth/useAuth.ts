import { create } from "zustand";
import type { AuthProvider, Session } from "./types";
import { LocalAuth } from "./localAuth";
import { makeSeed } from "@/data/seed";
import { BOARD_ID, supabaseConfigured, supabaseCreds } from "@/config";

/** Local mode needs the join-code hash before the workspace loads; read it from
    the persisted snapshot, or fall back to the seed default. */
function joinCodeHash(): string {
  try {
    const raw = localStorage.getItem("cr:snapshot");
    if (raw) {
      const s = JSON.parse(raw);
      if (s?.settings?.gatehash) return s.settings.gatehash as string;
    }
  } catch {
    /* ignore */
  }
  return makeSeed().settings.gatehash;
}

async function makeAuthProvider(): Promise<AuthProvider> {
  if (supabaseConfigured) {
    const { SupabaseAuth } = await import("./supabaseAuth");
    return new SupabaseAuth(supabaseCreds.url, supabaseCreds.anonKey);
  }
  return new LocalAuth(joinCodeHash());
}

interface AuthState {
  ready: boolean;
  provider: AuthProvider | null;
  session: Session | null;
  init: () => Promise<void>;
  signIn: (email: string, password: string) => Promise<string | null>;
  signUp: (i: {
    email: string;
    password: string;
    displayName: string;
    joinCode: string;
  }) => Promise<string | null>;
  signOut: () => Promise<void>;
  changePassword: (current: string, next: string) => Promise<string | null>;
  requestReset: (email: string) => Promise<{ devCode?: string } | string>;
  completeReset: (email: string, code: string, next: string) => Promise<string | null>;
}

let authInit: Promise<void> | null = null;

export const useAuth = create<AuthState>((set, get) => ({
  ready: false,
  provider: null,
  session: null,

  init() {
    if (!authInit) {
      authInit = (async () => {
        const provider = await makeAuthProvider();
        const session = await provider.init();
        provider.onChange((s) => set({ session: s }));
        set({ provider, session, ready: true });
      })();
    }
    return authInit;
  },

  async signIn(email, password) {
    const p = get().provider;
    if (!p) return "Auth not ready.";
    const r = await p.signIn(email, password);
    if (!r.ok) return r.error;
    set({ session: p.current() });
    return null;
  },

  async signUp(input) {
    const p = get().provider;
    if (!p) return "Auth not ready.";
    const r = await p.signUp(input);
    if (!r.ok) return r.error;
    set({ session: p.current() });
    return null;
  },

  async signOut() {
    await get().provider?.signOut();
    set({ session: null });
  },

  async changePassword(current, next) {
    const p = get().provider;
    if (!p) return "Auth not ready.";
    const r = await p.updatePassword(current, next);
    return r.ok ? null : r.error;
  },

  async requestReset(email) {
    const p = get().provider;
    if (!p) return "Auth not ready.";
    const r = await p.requestReset(email);
    if (!r.ok) return r.error;
    return { devCode: r.devCode };
  },

  async completeReset(email, code, next) {
    const p = get().provider;
    if (!p) return "Auth not ready.";
    const r = await p.completeReset(email, code, next);
    return r.ok ? null : r.error;
  },
}));

/** The signed-in display name, or "" — used for attribution everywhere. */
export function currentName(): string {
  return useAuth.getState().session?.displayName ?? "";
}

export { BOARD_ID };
