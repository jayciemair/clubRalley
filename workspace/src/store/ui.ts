import { create } from "zustand";
import { BOARD_ID } from "@/config";
import { firstOfMonth, todayNum } from "@/lib/dates";

/* Per-viewer view preferences. localStorage only, never synced. */

const KEY = `cr:ui:${BOARD_ID}`;

type Theme = "system" | "light" | "dark";

interface Persisted {
  theme: Theme;
  hiddenCategories: string[];
  hideDone: boolean;
  mineOnly: boolean;
  calCursor: number;
}

function read(): Persisted {
  const base: Persisted = {
    theme: "system",
    hiddenCategories: [],
    hideDone: true,
    mineOnly: false,
    calCursor: firstOfMonth(todayNum()),
  };
  try {
    return { ...base, ...JSON.parse(localStorage.getItem(KEY) || "{}") };
  } catch {
    return base;
  }
}

interface UiState extends Persisted {
  setTheme: (t: Theme) => void;
  toggleCategory: (id: string, allIds: string[]) => void;
  showAllCategories: () => void;
  setHideDone: (v: boolean) => void;
  setMineOnly: (v: boolean) => void;
  setCalCursor: (n: number) => void;
}

function persist(s: Persisted) {
  try {
    localStorage.setItem(KEY, JSON.stringify(s));
  } catch {
    /* ignore */
  }
}

function applyTheme(t: Theme) {
  const root = document.documentElement;
  if (t === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", t);
}

export const useUi = create<UiState>((set, get) => {
  const initial = read();
  applyTheme(initial.theme);

  const save = () => {
    const { theme, hiddenCategories, hideDone, mineOnly, calCursor } = get();
    persist({ theme, hiddenCategories, hideDone, mineOnly, calCursor });
  };

  return {
    ...initial,
    setTheme: (theme) => {
      applyTheme(theme);
      set({ theme });
      save();
    },
    toggleCategory: (cat, allIds) => {
      const hidden = new Set(get().hiddenCategories);
      const visible = allIds.filter((n) => !hidden.has(n));
      if (hidden.has(cat)) hidden.delete(cat);
      else if (visible.length <= 1) hidden.clear();
      else {
        hidden.clear();
        allIds.forEach((n) => n !== cat && hidden.add(n));
      }
      set({ hiddenCategories: [...hidden] });
      save();
    },
    showAllCategories: () => {
      set({ hiddenCategories: [] });
      save();
    },
    setHideDone: (v) => {
      set({ hideDone: v });
      save();
    },
    setMineOnly: (v) => {
      set({ mineOnly: v });
      save();
    },
    setCalCursor: (n) => {
      set({ calCursor: n });
      save();
    },
  };
});
