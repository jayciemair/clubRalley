import type { Task } from "@/data/types";
import { mondayOnOrBefore, todayNum } from "@/lib/dates";
import { spanBounds } from "./selectors";

export const ZOOM = { weeks: 20, days: 34 } as const;
export type Zoom = keyof typeof ZOOM;

export interface Layout {
  gridStart: number;
  totalDays: number;
  dayW: number;
  today: number;
  width: number;
}

export function computeLayout(tasks: Task[], zoom: Zoom): Layout {
  const b = spanBounds(tasks);
  const today = todayNum();
  let gridStart = mondayOnOrBefore(b.min) - 7;
  let gEnd = mondayOnOrBefore(b.max) + 20;
  if (today < gridStart) gridStart = mondayOnOrBefore(today) - 7;
  if (today > gEnd) gEnd = mondayOnOrBefore(today) + 13;
  const totalDays = gEnd - gridStart + 1;
  const dayW = ZOOM[zoom];
  return { gridStart, totalDays, dayW, today, width: totalDays * dayW };
}
