import type { WorkspaceAdapter } from "./data/adapter";
import { LocalAdapter } from "./data/localAdapter";

const url = (import.meta.env.VITE_SUPABASE_URL ?? "").trim();
const anonKey = (import.meta.env.VITE_SUPABASE_ANON_KEY ?? "").trim();

export const BOARD_ID = (import.meta.env.VITE_BOARD_ID ?? "clubralley").trim();

export const supabaseConfigured =
  /^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/i.test(url) &&
  anonKey.length > 20 &&
  !anonKey.includes("YOUR-");

export const supabaseCreds = { url, anonKey };

let cached: Promise<WorkspaceAdapter> | null = null;

/** Pick the backend. Supabase when it's configured, else the local mock.
    Cached so React StrictMode's double-invoke doesn't create two adapters. */
export function makeAdapter(): Promise<WorkspaceAdapter> {
  if (!cached) {
    cached = (async () => {
      if (supabaseConfigured) {
        const { SupabaseAdapter } = await import("./data/supabaseAdapter");
        return new SupabaseAdapter(url, anonKey, BOARD_ID);
      }
      return new LocalAdapter();
    })();
  }
  return cached;
}

export const runtimeMode: "local" | "supabase" = supabaseConfigured
  ? "supabase"
  : "local";
