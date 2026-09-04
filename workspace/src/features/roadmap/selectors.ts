import type { Snapshot, Task } from "@/data/types";
import { dnum, todayNum } from "@/lib/dates";

export function isDone(t: Task): boolean {
  return !t.milestone && t.progress >= 100;
}

export function isOverdue(t: Task): boolean {
  return !t.milestone && t.progress < 100 && dnum(t.end || t.start) < todayNum();
}

export function myTodos(t: Task, me: string) {
  return (t.todos || []).filter((d) => !d.done && d.tag.includes(me));
}

export function assignedToMe(t: Task, me: string): boolean {
  if (!me) return false;
  return t.owners.includes(me) || myTodos(t, me).length > 0;
}

export interface Filters {
  hiddenCategories: string[];
  hideDone: boolean;
  mineOnly: boolean;
  me: string;
}

export function visibleTasks(snap: Snapshot, f: Filters): Task[] {
  const hidden = new Set(f.hiddenCategories);
  return [...snap.tasks]
    .sort((a, b) => a.order - b.order)
    .filter((t) => {
      if (hidden.has(t.categoryId)) return false;
      if (f.hideDone && isDone(t)) return false;
      if (f.mineOnly && f.me && !assignedToMe(t, f.me)) return false;
      return true;
    });
}

export function doneCount(snap: Snapshot, hiddenCategories: string[]): number {
  const hidden = new Set(hiddenCategories);
  return snap.tasks.filter((t) => isDone(t) && !hidden.has(t.categoryId)).length;
}

export function spanBounds(tasks: Task[]): { min: number; max: number } {
  if (!tasks.length) {
    const t = todayNum();
    return { min: t, max: t + 28 };
  }
  let min = dnum(tasks[0].start);
  let max = min;
  for (const t of tasks) {
    const s = dnum(t.start);
    let e = dnum(t.end || t.start);
    if (e < s) e = s;
    if (s < min) min = s;
    if (e > max) max = e;
  }
  return { min, max };
}
