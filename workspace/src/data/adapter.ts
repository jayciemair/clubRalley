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

/** Everything the app needs from a backend. Two implementations:
    - LocalAdapter  — localStorage + BroadcastChannel (default, offline, per-browser)
    - SupabaseAdapter — shared Postgres + realtime (when env vars are set) */
export interface WorkspaceAdapter {
  readonly kind: "local" | "supabase";

  load(): Promise<Snapshot>;
  /** Called with a partial snapshot whenever data changes elsewhere. Returns an
      unsubscribe fn. */
  subscribe(cb: (patch: SnapshotPatch) => void): () => void;

  upsertTask(t: Task): Promise<void>;
  deleteTask(id: string): Promise<void>;

  upsertResource(r: ResourceNode): Promise<void>;
  deleteResource(id: string): Promise<void>;

  upsertChannel(c: Channel): Promise<void>;

  postMessage(m: Message): Promise<void>;
  patchMessage(id: string, patch: Partial<Message>): Promise<void>;

  addActivity(e: ActivityEvent): Promise<void>;

  updateSettings(patch: Partial<Settings>): Promise<void>;
  updateMembers(members: Member[]): Promise<void>;
  updateCategories(categories: Category[]): Promise<void>;

  /** Wholesale replace — used by "import from old board". */
  replaceAll(snapshot: Snapshot): Promise<void>;
}
