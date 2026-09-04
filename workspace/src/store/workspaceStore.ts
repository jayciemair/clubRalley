import { create } from "zustand";
import type { WorkspaceAdapter } from "@/data/adapter";
import type {
  Category,
  Channel,
  Member,
  Message,
  ResourceNode,
  Settings,
  Snapshot,
  Task,
} from "@/data/types";
import { makeAdapter } from "@/config";
import { diffActivity, snapshotForDiff } from "@/lib/activity";
import { id } from "@/lib/ids";
import { me } from "./identity";

interface WorkspaceState {
  ready: boolean;
  error: string | null;
  adapter: WorkspaceAdapter | null;
  snap: Snapshot | null;

  init: () => Promise<void>;

  saveTask: (t: Task) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  reorderTasks: (orderedIds: string[]) => Promise<void>;

  saveResource: (r: ResourceNode) => Promise<void>;
  deleteResource: (id: string) => Promise<void>;
  addResource: (categoryId: string, parentId: string | null) => Promise<string>;

  createChannel: (name: string) => Promise<string>;
  openDm: (names: string[]) => Promise<string>;
  sendMessage: (m: Omit<Message, "id" | "at">) => Promise<void>;
  editMessage: (id: string, body: string) => Promise<void>;
  deleteMessage: (id: string) => Promise<void>;
  toggleReaction: (id: string, emoji: string) => Promise<void>;

  updateSettings: (patch: Partial<Settings>) => Promise<void>;
  updateMembers: (members: Member[]) => Promise<void>;
  updateCategories: (categories: Category[]) => Promise<void>;
  importSnapshot: (snapshot: Snapshot) => Promise<void>;
}

function upsert<T extends { id: string }>(list: T[], item: T): T[] {
  const i = list.findIndex((x) => x.id === item.id);
  if (i === -1) return [...list, item];
  const copy = list.slice();
  copy[i] = item;
  return copy;
}

let wsInit: Promise<void> | null = null;

export const useWorkspace = create<WorkspaceState>((set, get) => {
  /** Apply a snapshot update optimistically, persist it, then log to the
      activity feed whatever roadmap/resource fields changed. */
  async function applyAndLog(
    update: (snap: Snapshot) => Snapshot,
    persist: (a: WorkspaceAdapter, next: Snapshot) => Promise<void>,
  ) {
    const a = get().adapter;
    const cur = get().snap;
    if (!a || !cur) return;
    const before = snapshotForDiff(cur);
    const next = update(cur);
    set({ snap: next });
    await persist(a, next);
    const who = me();
    if (who) {
      const events = diffActivity(before, snapshotForDiff(next), who);
      for (const e of events) await a.addActivity(e);
    }
  }

  async function apply(
    update: (snap: Snapshot) => Snapshot,
    persist: (a: WorkspaceAdapter, next: Snapshot) => Promise<void>,
  ) {
    const a = get().adapter;
    const cur = get().snap;
    if (!a || !cur) return;
    const next = update(cur);
    set({ snap: next });
    await persist(a, next);
  }

  return {
    ready: false,
    error: null,
    adapter: null,
    snap: null,

    init() {
      if (!wsInit) {
        wsInit = (async () => {
          try {
            const adapter = await makeAdapter();
            const snap = await adapter.load();
            adapter.subscribe((patch) => {
              set((st) => (st.snap ? { snap: { ...st.snap, ...patch } } : st));
            });
            set({ adapter, snap, ready: true });
          } catch (e) {
            set({ error: e instanceof Error ? e.message : String(e), ready: true });
          }
        })();
      }
      return wsInit;
    },

    saveTask: (t) =>
      applyAndLog(
        (s) => ({ ...s, tasks: upsert(s.tasks, t) }),
        (a) => a.upsertTask(t),
      ),

    deleteTask: (taskId) =>
      applyAndLog(
        (s) => ({ ...s, tasks: s.tasks.filter((x) => x.id !== taskId) }),
        (a) => a.deleteTask(taskId),
      ),

    async reorderTasks(orderedIds) {
      const pos = new Map(orderedIds.map((x, i) => [x, i]));
      await apply(
        (s) => ({
          ...s,
          tasks: s.tasks.map((t) => ({ ...t, order: pos.get(t.id) ?? t.order })),
        }),
        async (a, next) => {
          for (const t of next.tasks) await a.upsertTask(t);
        },
      );
    },

    saveResource: (r) =>
      applyAndLog(
        (s) => ({ ...s, resources: upsert(s.resources, r) }),
        (a) => a.upsertResource(r),
      ),

    async deleteResource(resId) {
      const a = get().adapter;
      if (!a) return;
      await a.deleteResource(resId);
      set({ snap: await a.load() });
    },

    async addResource(categoryId, parentId) {
      const s = get().snap;
      if (!s) return "";
      const siblings = s.resources.filter(
        (r) => r.categoryId === categoryId && r.parentId === parentId,
      );
      const node: ResourceNode = {
        id: id("r"),
        parentId,
        categoryId,
        title: "New page",
        body: "",
        order: siblings.length,
      };
      await applyAndLog(
        (snap) => ({ ...snap, resources: [...snap.resources, node] }),
        (a) => a.upsertResource(node),
      );
      return node.id;
    },

    async createChannel(name) {
      const s = get().snap;
      if (!s) return "";
      const clean = name.trim().replace(/^#/, "").replace(/\s+/g, "-").toLowerCase();
      const existing = s.channels.find((c) => c.name === clean && c.kind === "chat");
      if (existing) return existing.id;
      const ch: Channel = {
        id: id("c"),
        name: clean || "channel",
        kind: "chat",
        order: s.channels.length,
      };
      await apply(
        (snap) => ({ ...snap, channels: [...snap.channels, ch] }),
        (a) => a.upsertChannel(ch),
      );
      return ch.id;
    },

    async openDm(names) {
      const s = get().snap;
      if (!s) return "";
      const who = me();
      const members = Array.from(new Set([who, ...names].filter(Boolean))).sort();
      const key = members.join("|");
      const existing = s.channels.find(
        (c) => c.kind === "dm" && (c.members ?? []).slice().sort().join("|") === key,
      );
      if (existing) return existing.id;
      const ch: Channel = {
        id: id("dm"),
        name: members.filter((n) => n !== who).join(", ") || "Notes to self",
        kind: "dm",
        members,
        order: 100 + s.channels.length,
      };
      await apply(
        (snap) => ({ ...snap, channels: [...snap.channels, ch] }),
        (a) => a.upsertChannel(ch),
      );
      return ch.id;
    },

    async sendMessage(m) {
      const full: Message = { ...m, id: id("m"), at: Date.now() };
      await apply(
        (s) => ({ ...s, messages: [...s.messages, full] }),
        (a) => a.postMessage(full),
      );
    },

    async editMessage(msgId, body) {
      const patch = { body, editedAt: Date.now() };
      await apply(
        (s) => ({
          ...s,
          messages: s.messages.map((x) => (x.id === msgId ? { ...x, ...patch } : x)),
        }),
        (a) => a.patchMessage(msgId, patch),
      );
    },

    async deleteMessage(msgId) {
      const patch = { deleted: true, body: "" };
      await apply(
        (s) => ({
          ...s,
          messages: s.messages.map((x) => (x.id === msgId ? { ...x, ...patch } : x)),
        }),
        (a) => a.patchMessage(msgId, patch),
      );
    },

    async toggleReaction(msgId, emoji) {
      const s = get().snap;
      const who = me();
      if (!s || !who) return;
      const msg = s.messages.find((x) => x.id === msgId);
      if (!msg) return;
      const current = msg.reactions[emoji] ?? [];
      const next = current.includes(who)
        ? current.filter((n) => n !== who)
        : [...current, who];
      const reactions = { ...msg.reactions };
      if (next.length) reactions[emoji] = next;
      else delete reactions[emoji];
      await apply(
        (snap) => ({
          ...snap,
          messages: snap.messages.map((x) => (x.id === msgId ? { ...x, reactions } : x)),
        }),
        (a) => a.patchMessage(msgId, { reactions }),
      );
    },

    updateSettings: (patch) =>
      apply(
        (s) => ({ ...s, settings: { ...s.settings, ...patch } }),
        (a) => a.updateSettings(patch),
      ),

    updateMembers: (members) =>
      apply(
        (s) => ({ ...s, members }),
        (a) => a.updateMembers(members),
      ),

    updateCategories: (categories) =>
      apply(
        (s) => ({ ...s, categories }),
        (a) => a.updateCategories(categories),
      ),

    async importSnapshot(snapshot) {
      const a = get().adapter;
      if (!a) return;
      await a.replaceAll(snapshot);
      set({ snap: await a.load() });
    },
  };
});
