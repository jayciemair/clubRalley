import { createClient, type RealtimeChannel, type SupabaseClient } from "@supabase/supabase-js";
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

/* Shared Postgres + realtime, via Club Ralley's own Supabase project (see
   supabase/schema.sql). Every table but `settings`/`members`/`categories`
   stores its row as `{ id, data: <the typed object>, ... }` — reading is just
   `rows.map(r => r.data)`, writing is `upsert({ id: obj.id, data: obj })`.
   That uniform shape is what keeps this file short.

   RLS requires an authenticated session for every read and write (see
   SECURITY.md) — the client only ever needs the publishable/anon key, never a
   secret one. */

type DataRow<T> = { data: T };
type Realtime = { eventType: "INSERT" | "UPDATE" | "DELETE"; new: Record<string, unknown>; old: Record<string, unknown> };
type ArrayKey = "tasks" | "resources" | "channels" | "messages" | "activity";

export class SupabaseAdapter implements WorkspaceAdapter {
  readonly kind = "supabase" as const;
  private sb: SupabaseClient;
  private snap: Snapshot | null = null;
  private listeners = new Set<(patch: SnapshotPatch) => void>();
  private channel: RealtimeChannel | null = null;

  constructor(url: string, anonKey: string, private boardId: string) {
    this.sb = createClient(url, anonKey);
  }

  private throwIfError(error: { message: string } | null) {
    if (error) throw new Error(error.message);
  }

  async load(): Promise<Snapshot> {
    const settingsRes = await this.sb
      .from("settings")
      .select("data")
      .eq("id", this.boardId)
      .maybeSingle<DataRow<Partial<Settings>>>();
    this.throwIfError(settingsRes.error);

    if (!settingsRes.data) {
      const seed = makeSeed();
      await this.seedAll(seed);
      this.snap = seed;
      this.startRealtime();
      return seed;
    }

    const [members, categories, tasks, resources, channels, messages, activity] = await Promise.all([
      this.sb.from("members").select("name,color"),
      this.sb.from("categories").select("id,name,color").order("sort"),
      this.sb.from("tasks").select("data").returns<DataRow<Task>[]>(),
      this.sb.from("resources").select("data").returns<DataRow<ResourceNode>[]>(),
      this.sb.from("channels").select("data").returns<DataRow<Channel>[]>(),
      this.sb.from("messages").select("data").order("created_at").returns<DataRow<Message>[]>(),
      this.sb.from("activity").select("data").order("created_at").returns<DataRow<ActivityEvent>[]>(),
    ]);
    for (const r of [members, categories, tasks, resources, channels, messages, activity]) {
      this.throwIfError(r.error);
    }

    const snap: Snapshot = {
      settings: {
        title: "Club Ralley",
        subtitle: "",
        gatehash: "",
        zoom: "weeks",
        ...settingsRes.data,
      },
      members: (members.data ?? []) as Member[],
      categories: (categories.data ?? []) as Category[],
      tasks: (tasks.data ?? []).map((r) => r.data),
      resources: (resources.data ?? []).map((r) => r.data),
      channels: (channels.data ?? []).map((r) => r.data),
      messages: (messages.data ?? []).map((r) => r.data),
      activity: (activity.data ?? []).map((r) => r.data),
    };
    this.snap = snap;
    this.startRealtime();
    return snap;
  }

  private async seedAll(seed: Snapshot) {
    await Promise.all([
      this.sb.from("settings").upsert({
        id: this.boardId,
        data: { title: seed.settings.title, subtitle: seed.settings.subtitle, zoom: seed.settings.zoom },
      }),
      this.sb.from("members").upsert(seed.members.map((m) => ({ name: m.name, color: m.color }))),
      this.sb
        .from("categories")
        .upsert(seed.categories.map((c, i) => ({ id: c.id, name: c.name, color: c.color, sort: i }))),
      this.sb.from("tasks").upsert(seed.tasks.map((t) => ({ id: t.id, data: t }))),
      this.sb
        .from("resources")
        .upsert(seed.resources.map((r) => ({ id: r.id, parent_id: r.parentId, data: r }))),
      this.sb.from("channels").upsert(seed.channels.map((c) => ({ id: c.id, data: c }))),
    ]);
  }

  subscribe(cb: (patch: SnapshotPatch) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  private emit(patch: SnapshotPatch) {
    for (const l of this.listeners) l(patch);
  }

  private startRealtime() {
    if (this.channel) return;
    this.channel = this.sb
      .channel(`board:${this.boardId}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "tasks" }, (p) => this.onRow("tasks", p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "resources" }, (p) => this.onRow("resources", p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "channels" }, (p) => this.onRow("channels", p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "messages" }, (p) => this.onRow("messages", p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "activity" }, (p) => this.onRow("activity", p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "members" }, (p) => this.onMembers(p as unknown as Realtime))
      .on("postgres_changes", { event: "*", schema: "public", table: "categories" }, (p) => this.onCategories(p as unknown as Realtime))
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "settings", filter: `id=eq.${this.boardId}` },
        (p) => this.onSettings(p as unknown as Realtime),
      )
      .subscribe();
  }

  private onRow(key: ArrayKey, payload: Realtime) {
    if (!this.snap) return;
    const list = this.snap[key] as { id: string }[];
    let next: { id: string }[];
    if (payload.eventType === "DELETE") {
      const oldId = payload.old?.id as string | undefined;
      next = list.filter((x) => x.id !== oldId);
    } else {
      const obj = payload.new.data as { id: string };
      const i = list.findIndex((x) => x.id === obj.id);
      next = i === -1 ? [...list, obj] : Object.assign(list.slice(), { [i]: obj });
    }
    this.snap = { ...this.snap, [key]: next } as Snapshot;
    this.emit({ [key]: next } as SnapshotPatch);
  }

  private onMembers(payload: Realtime) {
    if (!this.snap) return;
    let list = this.snap.members.slice();
    if (payload.eventType === "DELETE") {
      list = list.filter((m) => m.name !== payload.old?.name);
    } else {
      const row = payload.new as { name: string; color: string };
      const i = list.findIndex((m) => m.name === row.name);
      const member: Member = { name: row.name, color: row.color ?? "" };
      if (i === -1) list.push(member);
      else list[i] = member;
    }
    this.snap = { ...this.snap, members: list };
    this.emit({ members: list });
  }

  private onCategories(payload: Realtime) {
    if (!this.snap) return;
    let list = this.snap.categories.slice();
    if (payload.eventType === "DELETE") {
      list = list.filter((c) => c.id !== payload.old?.id);
    } else {
      const row = payload.new as { id: string; name: string; color: string };
      const i = list.findIndex((c) => c.id === row.id);
      const cat: Category = { id: row.id, name: row.name, color: row.color };
      if (i === -1) list.push(cat);
      else list[i] = cat;
    }
    this.snap = { ...this.snap, categories: list };
    this.emit({ categories: list });
  }

  private onSettings(payload: Realtime) {
    if (!this.snap) return;
    const data = payload.new?.data as Partial<Settings> | undefined;
    if (!data) return;
    const settings = { ...this.snap.settings, ...data };
    this.snap = { ...this.snap, settings };
    this.emit({ settings });
  }

  async upsertTask(t: Task) {
    const { error } = await this.sb
      .from("tasks")
      .upsert({ id: t.id, data: t, updated_at: new Date().toISOString() });
    this.throwIfError(error);
  }
  async deleteTask(id: string) {
    const { error } = await this.sb.from("tasks").delete().eq("id", id);
    this.throwIfError(error);
  }

  async upsertResource(r: ResourceNode) {
    const { error } = await this.sb
      .from("resources")
      .upsert({ id: r.id, parent_id: r.parentId, data: r, updated_at: new Date().toISOString() });
    this.throwIfError(error);
  }
  async deleteResource(id: string) {
    const kill = new Set([id]);
    if (this.snap) {
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
    }
    const { error } = await this.sb.from("resources").delete().in("id", [...kill]);
    this.throwIfError(error);
  }

  async upsertChannel(c: Channel) {
    const { error } = await this.sb
      .from("channels")
      .upsert({ id: c.id, data: c, updated_at: new Date().toISOString() });
    this.throwIfError(error);
  }

  async postMessage(m: Message) {
    const { error } = await this.sb
      .from("messages")
      .insert({ id: m.id, channel_id: m.channelId, parent_id: m.parentId, data: m });
    this.throwIfError(error);
  }
  async patchMessage(id: string, patch: Partial<Message>) {
    const existing = this.snap?.messages.find((x) => x.id === id);
    if (!existing) return;
    const { error } = await this.sb.from("messages").update({ data: { ...existing, ...patch } }).eq("id", id);
    this.throwIfError(error);
  }

  async addActivity(e: ActivityEvent) {
    const { error } = await this.sb.from("activity").insert({ id: e.id, data: e });
    this.throwIfError(error);
  }

  async updateSettings(patch: Partial<Settings>) {
    const base = this.snap?.settings;
    const next = { ...base, ...patch };
    const { error } = await this.sb.from("settings").upsert({
      id: this.boardId,
      data: { title: next.title, subtitle: next.subtitle, zoom: next.zoom },
      updated_at: new Date().toISOString(),
    });
    this.throwIfError(error);
  }

  async updateMembers(members: Member[]) {
    const { error } = await this.sb
      .from("members")
      .upsert(members.map((m) => ({ name: m.name, color: m.color, updated_at: new Date().toISOString() })));
    this.throwIfError(error);
    if (this.snap) {
      const keep = new Set(members.map((m) => m.name));
      const removed = this.snap.members.filter((m) => !keep.has(m.name)).map((m) => m.name);
      if (removed.length) await this.sb.from("members").delete().in("name", removed);
    }
  }

  async updateCategories(categories: Category[]) {
    const { error } = await this.sb
      .from("categories")
      .upsert(categories.map((c, i) => ({ id: c.id, name: c.name, color: c.color, sort: i })));
    this.throwIfError(error);
  }

  async replaceAll(snapshot: Snapshot) {
    await Promise.all([
      this.sb.from("tasks").delete().not("id", "is", null),
      this.sb.from("resources").delete().not("id", "is", null),
      this.sb.from("channels").delete().not("id", "is", null),
    ]);
    await this.seedAll(snapshot);
    this.snap = snapshot;
  }
}
