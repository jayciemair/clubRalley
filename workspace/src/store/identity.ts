import { create } from "zustand";
import { BOARD_ID } from "@/config";
import { useAuth } from "@/auth/useAuth";

/* "Who am I" now comes from the signed-in account (see @/auth). This store only
   tracks per-channel last-seen timestamps, for unread badges. localStorage
   only, never synced. */

const SEEN_KEY = `cr:seen:${BOARD_ID}`;

function readSeen(): Record<string, number> {
  try {
    return JSON.parse(localStorage.getItem(SEEN_KEY) || "{}");
  } catch {
    return {};
  }
}

interface SeenState {
  seen: Record<string, number>;
  markSeen: (channelId: string) => void;
  lastSeen: (channelId: string) => number;
}

export const useSeen = create<SeenState>((set, get) => ({
  seen: readSeen(),
  markSeen: (channelId) => {
    const seen = { ...get().seen, [channelId]: Date.now() };
    try {
      localStorage.setItem(SEEN_KEY, JSON.stringify(seen));
    } catch {
      /* ignore */
    }
    set({ seen });
  },
  lastSeen: (channelId) => get().seen[channelId] ?? 0,
}));

/** Convenience: the current signed-in display name. */
export function me(): string {
  return useAuth.getState().session?.displayName ?? "";
}
