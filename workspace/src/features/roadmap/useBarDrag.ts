import { useRef } from "react";
import type { Task } from "@/data/types";
import { dnum, nstr } from "@/lib/dates";

type Mode = "move" | "start" | "end";

interface Args {
  task: Task;
  dayW: number;
  onCommit: (patch: { start: string; end: string }) => void;
  onBusyChange?: (busy: boolean) => void;
}

/** Pointer-drag for a timeline bar: drag body to move, edges to resize.
    Ported from the original makeDraggable(). Returns handlers to spread. */
export function useBarDrag({ task, dayW, onCommit, onBusyChange }: Args) {
  const state = useRef<{
    mode: Mode;
    startX: number;
    origStart: number;
    origEnd: number;
    moved: boolean;
  } | null>(null);
  const preview = useRef<{ start: number; end: number } | null>(null);
  const elRef = useRef<HTMLElement | null>(null);

  function down(e: React.PointerEvent<HTMLElement>, mode: Mode) {
    if (e.button !== 0 || task.milestone) return;
    const el = e.currentTarget;
    elRef.current = el;
    el.setPointerCapture(e.pointerId);
    state.current = {
      mode,
      startX: e.clientX,
      origStart: dnum(task.start),
      origEnd: dnum(task.end || task.start),
      moved: false,
    };
  }

  function move(e: React.PointerEvent<HTMLElement>) {
    const st = state.current;
    if (!st) return;
    const deltaDays = Math.round((e.clientX - st.startX) / dayW);
    if (!st.moved && Math.abs(e.clientX - st.startX) > 3) {
      st.moved = true;
      onBusyChange?.(true);
      elRef.current?.classList.add("dragging");
    }
    if (!st.moved) return;

    let s = st.origStart;
    let en = st.origEnd;
    if (st.mode === "move") {
      s += deltaDays;
      en += deltaDays;
    } else if (st.mode === "start") {
      s = Math.min(st.origStart + deltaDays, en);
    } else {
      en = Math.max(st.origEnd + deltaDays, s);
    }
    preview.current = { start: s, end: en };
    const el = elRef.current;
    if (el) {
      el.style.setProperty("--bar-start", String(s));
      el.style.setProperty("--bar-days", String(en - s + 1));
    }
  }

  function up(e: React.PointerEvent<HTMLElement>) {
    const st = state.current;
    state.current = null;
    elRef.current?.classList.remove("dragging");
    try {
      elRef.current?.releasePointerCapture(e.pointerId);
    } catch {
      /* ignore */
    }
    if (st?.moved && preview.current) {
      onCommit({ start: nstr(preview.current.start), end: nstr(preview.current.end) });
    }
    preview.current = null;
    // let the trailing click be swallowed by the caller via a small delay
    setTimeout(() => onBusyChange?.(false), 60);
    return st?.moved ?? false;
  }

  return {
    bodyHandlers: {
      onPointerDown: (e: React.PointerEvent<HTMLElement>) => down(e, "move"),
      onPointerMove: move,
      onPointerUp: up,
    },
    edgeHandlers: (which: "start" | "end") => ({
      onPointerDown: (e: React.PointerEvent<HTMLElement>) => {
        e.stopPropagation();
        down(e, which);
      },
      onPointerMove: move,
      onPointerUp: up,
    }),
    didDrag: () => state.current?.moved ?? false,
  };
}
