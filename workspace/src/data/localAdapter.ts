import type { WorkspaceAdapter } from "./adapter";
import type {
  ActivityEvent,
  Category,
  Channel,
  Member,
  Message,
  ResourceNode,
  Settings,
  Snapshot,
  SnapshotPatch,
  Task,
} from "./types";
import { makeSeed } from "./seed";

/* Local, offline adapter. Persists the whole snapshot to localStorage and
   mirrors writes to other tabs on the same machine via BroadcastChannel, so
   you can demo realtime chat with two windows before Supabase is wired. */

const KEY = "cr:snapshot";
const CHAN = "clubralley-sync";

function upsertBy<T extends { id: string }>(list: T[], item: T): T[] {
  const i = list.findIndex((x) => x.id === item.id);
  if (i === -1) return [...list, item];
  const copy = list.slice();
  copy[i] = item;
  return copy;
}

export class LocalAdapter implements WorkspaceAdapter {
  readonly kind = "local" as const;
  private snap: Snapshot;
  private bc: BroadcastChannel | null = null;
  private listeners = new Set<(p: SnapshotPatch) => void>();

  constructor() {
    this.snap = this.read();
    try {
      this.bc = new BroadcastChannel(CHAN);
      this.bc.onmessage = (e: MessageEvent<SnapshotPatch>) => {
        this.snap = { ...this.snap, ...e.data };
        this.persist(false);
        this.emit(e.data);
      };
    } catch {
      /* no BroadcastChannel (old browser) — single-tab only */
    }
    window.addEventListener("storage", (e) => {
      if (e.key === KEY && e.newValue) {
        try {
          this.snap = JSON.parse(e.newValue);
          this.emit(this.snap);
        } catch {
          /* ignore */
        }
      }
    });
  }

  private read(): Snapshot {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) return migrate(JSON.parse(raw));
    } catch {
      /* fall through to seed */
    }
    const seed = makeSeed();
    try {
      localStorage.setItem(KEY, JSON.stringify(seed));
    } catch {
      /* private mode — in-memory only */
    }
    return seed;
  }

  private persist(broadcast: boolean, patch?: SnapshotPatch) {
    try {
      localStorage.setItem(KEY, JSON.stringify(this.snap));
    } catch {
      /* ignore quota / private mode */
    }
    if (broadcast && this.bc && patch) this.bc.postMessage(patch);
  }

  private emit(patch: SnapshotPatch) {
    for (const l of this.listeners) l(patch);
  }

  private commit(patch: SnapshotPatch) {
    this.snap = { ...this.snap, ...patch };
    this.persist(true, patch);
  }

  async load(): Promise<Snapshot> {
    return this.snap;
  }

  subscribe(cb: (patch: SnapshotPatch) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  async upsertTask(t: Task) {
    this.commit({ tasks: upsertBy(this.snap.tasks, t) });
  }
  async deleteTask(id: string) {
    this.commit({ tasks: this.snap.tasks.filter((x) => x.id !== id) });
  }
  async upsertResource(r: ResourceNode) {
    this.commit({ resources: upsertBy(this.snap.resources, r) });
  }
  async deleteResource(id: string) {
    const kill = new Set([id]);
    let grew = true;
    while (grew) {
      grew = false;
      for (const r of this.snap.resources) {
        if (r.parentId && kill.has(r.parentId) && !kill.has(r.id)) {
          kill.add(r.id);
          grew = true;
        }
      }
    }
    this.commit({ resources: this.snap.resources.filter((x) => !kill.has(x.id)) });
  }
  async upsertChannel(c: Channel) {
    this.commit({ channels: upsertBy(this.snap.channels, c) });
  }
  async postMessage(m: Message) {
    this.commit({ messages: [...this.snap.messages, m] });
  }
  async patchMessage(id: string, patch: Partial<Message>) {
    this.commit({
      messages: this.snap.messages.map((m) =>
        m.id === id ? { ...m, ...patch } : m,
      ),
    });
  }
  async addActivity(e: ActivityEvent) {
    const activity = [...this.snap.activity, e].slice(-400);
    this.commit({ activity });
  }
  async updateSettings(patch: Partial<Settings>) {
    this.commit({ settings: { ...this.snap.settings, ...patch } });
  }
  async updateMembers(members: Member[]) {
    this.commit({ members });
  }
  async updateCategories(categories: Category[]) {
    this.commit({ categories });
  }
  async replaceAll(snapshot: Snapshot) {
    this.snap = migrate(snapshot);
    this.persist(true, this.snap);
    this.emit(this.snap);
  }
}

/** Tolerate older / partial snapshots. */
function migrate(raw: unknown): Snapshot {
  const s = (raw ?? {}) as Record<string, unknown>;
  const seed = makeSeed();
  const arr = <T,>(v: unknown): T[] => (Array.isArray(v) ? (v as T[]) : []);

  const tasks = arr<Record<string, unknown>>(s.tasks).map((t, i) => ({
    id: String(t.id ?? `t${i}`),
    name: String(t.name ?? "Untitled"),
    owners: arr<string>(t.owners),
    categoryId: String(t.categoryId ?? seed.categories[0].id),
    start: String(t.start ?? ""),
    end: String(t.end ?? t.start ?? ""),
    progress: Number(t.progress) || 0,
    milestone: Boolean(t.milestone),
    notes: String(t.notes ?? ""),
    todos: arr<Record<string, unknown>>(t.todos).map((d, j) => ({
      id: String(d.id ?? `d${j}`),
      text: String(d.text ?? ""),
      done: Boolean(d.done),
      tag: arr<string>(d.tag),
    })),
    order: Number(t.order ?? i),
  }));

  const messages = arr<Record<string, unknown>>(s.messages).map((m, i) => ({
    id: String(m.id ?? `m${i}`),
    channelId: String(m.channelId ?? "general"),
    parentId: m.parentId ? String(m.parentId) : null,
    author: String(m.author ?? ""),
    at: Number(m.at) || Date.now(),
    body: String(m.body ?? ""),
    mentions: arr<string>(m.mentions),
    refs: arr<{ type: "task" | "resource"; id: string }>(m.refs),
    reactions: (m.reactions as Record<string, string[]>) ?? {},
    editedAt: m.editedAt ? Number(m.editedAt) : undefined,
    deleted: Boolean(m.deleted),
  }));

  return {
    settings: { ...seed.settings, ...(s.settings as object) },
    members: arr<{ name: string; color: string }>(s.members).length
      ? (s.members as Snapshot["members"])
      : seed.members,
    categories: arr(s.categories).length ? (s.categories as Snapshot["categories"]) : seed.categories,
    tasks,
    resources: arr(s.resources).length ? (s.resources as Snapshot["resources"]) : seed.resources,
    channels: arr(s.channels).length ? (s.channels as Snapshot["channels"]) : seed.channels,
    messages,
    activity: arr(s.activity) as Snapshot["activity"],
  };
}
