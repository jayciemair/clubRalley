import type { ActivityEvent, Snapshot, Task } from "@/data/types";
import { id } from "./ids";

/** Fields compared to decide what changed. */
type Snap = Pick<Snapshot, "tasks" | "resources"> & { notes: string };

export function snapshotForDiff(s: Snapshot): Snap {
  return {
    tasks: JSON.parse(JSON.stringify(s.tasks)),
    resources: JSON.parse(JSON.stringify(s.resources)),
    notes: pinnedNotes(s),
  };
}

/** The old "Team Notes" now lives as a pinned resource; track its body so edits
    still show up in the activity feed. */
function pinnedNotes(s: Snapshot): string {
  const n = s.resources.find((r) => r.pinned && r.title.toLowerCase().includes("note"));
  return n ? n.body : "";
}

function byId(tasks: Task[]): Record<string, Task> {
  const m: Record<string, Task> = {};
  for (const t of tasks) m[t.id] = t;
  return m;
}

/** Diff two snapshots and return the activity events `who` caused. */
export function diffActivity(a: Snap, b: Snap, who: string): ActivityEvent[] {
  if (!who) return [];
  const out: ActivityEvent[] = [];
  const push = (e: Omit<ActivityEvent, "id" | "who" | "at">) =>
    out.push({ ...e, id: id("a"), who, at: Date.now() });

  const A = byId(a.tasks);
  const B = byId(b.tasks);

  for (const t of b.tasks) if (!A[t.id]) push({ kind: "add", task: t.name });
  for (const t of a.tasks) if (!B[t.id]) push({ kind: "remove", task: t.name });

  for (const n of b.tasks) {
    const o = A[n.id];
    if (!o) continue;
    if (o.name !== n.name) push({ kind: "rename", task: n.name, from: o.name });
    const op = Number(o.progress) || 0;
    const np = Number(n.progress) || 0;
    if (op < 100 && np >= 100) push({ kind: "done", task: n.name });
    else if (op >= 100 && np < 100) push({ kind: "reopen", task: n.name });
    else if (op !== np) push({ kind: "progress", task: n.name, to: np });
    if (o.start !== n.start || o.end !== n.end) push({ kind: "dates", task: n.name });
    if (o.categoryId !== n.categoryId) push({ kind: "category", task: n.name });
    if (!!o.milestone !== !!n.milestone)
      push({ kind: "milestone", task: n.name, on: !!n.milestone });

    const added = n.owners.filter((x) => !o.owners.includes(x));
    const removed = o.owners.filter((x) => !n.owners.includes(x));
    if (added.length || removed.length)
      push({ kind: "owners", task: n.name, added, removed });

    const ot: Record<string, (typeof o.todos)[number]> = {};
    for (const d of o.todos) ot[d.id] = d;
    for (const d of n.todos) {
      const od = ot[d.id];
      if (!od) {
        push({ kind: "todo_add", task: n.name, text: d.text, tag: d.tag.slice() });
        continue;
      }
      if (!od.done && d.done) push({ kind: "todo_done", task: n.name, text: d.text });
      const newTags = d.tag.filter((x) => !od.tag.includes(x));
      if (newTags.length)
        push({ kind: "todo_tag", task: n.name, text: d.text, tag: newTags });
    }
  }

  if ((a.notes || "") !== (b.notes || "")) push({ kind: "notes" });

  const ar: Record<string, string> = {};
  for (const r of a.resources) ar[r.id] = r.title;
  for (const r of b.resources) {
    if (!(r.id in ar)) push({ kind: "res_add", title: r.title });
    else if (ar[r.id] !== r.title) push({ kind: "res_rename", title: r.title, from: ar[r.id] });
  }

  return out;
}

export function activityText(a: ActivityEvent): string {
  const t = a.task ? `"${a.task}"` : "the board";
  switch (a.kind) {
    case "add":
      return `added ${t}`;
    case "remove":
      return `deleted ${t}`;
    case "done":
      return `completed ${t}`;
    case "reopen":
      return `reopened ${t}`;
    case "progress":
      return `moved ${t} to ${a.to}%`;
    case "dates":
      return `rescheduled ${t}`;
    case "category":
      return `recategorised ${t}`;
    case "milestone":
      return `${a.on ? "flagged" : "unflagged"} ${t} as a milestone`;
    case "owners": {
      const bits: string[] = [];
      if (a.added?.length) bits.push(`assigned ${a.added.join(", ")}`);
      if (a.removed?.length) bits.push(`unassigned ${a.removed.join(", ")}`);
      return `${bits.join(" · ") || "changed people"} on ${t}`;
    }
    case "todo_add":
      return `added a to-do to ${t}${a.tag?.length ? ` and tagged ${a.tag.join(", ")}` : ""}`;
    case "todo_done":
      return `checked off a to-do in ${t}`;
    case "todo_tag":
      return `tagged ${(a.tag || []).join(", ")} on a to-do in ${t}`;
    case "rename":
      return `renamed ${a.from ? `"${a.from}"` : "a task"} to ${t}`;
    case "notes":
      return "edited the team notes";
    case "res_add":
      return `added a resource page, "${a.title}"`;
    case "res_rename":
      return `renamed a resource page to "${a.title}"`;
    default:
      return `updated ${t}`;
  }
}
