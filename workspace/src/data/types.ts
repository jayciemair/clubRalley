/* The whole workspace, normalised. One Snapshot is what an adapter loads and
   keeps in sync. Client-only state (locked identity, per-channel last-seen, UI
   prefs) lives in localStorage and is never part of a Snapshot. */

export interface Settings {
  title: string;
  subtitle: string;
  /** base64 of the shared password — a light gate, not real security. */
  gatehash: string;
  zoom: "weeks" | "days";
}

export interface Member {
  name: string;
  /** hex colour, or "" to fall back to a hashed hue */
  color: string;
}

export interface Category {
  id: string;
  name: string;
  color: string;
}

export interface Todo {
  id: string;
  text: string;
  done: boolean;
  /** member names tagged for attention on this to-do */
  tag: string[];
}

export interface Task {
  id: string;
  name: string;
  owners: string[];
  categoryId: string;
  /** ISO date yyyy-mm-dd */
  start: string;
  end: string;
  /** 0..100, step 5 */
  progress: number;
  milestone: boolean;
  notes: string;
  todos: Todo[];
  /** manual sort order in the rail */
  order: number;
}

export interface ResourceNode {
  id: string;
  parentId: string | null;
  /** category id, or "" for the pinned "Start here" area */
  categoryId: string;
  title: string;
  /** markdown */
  body: string;
  order: number;
  /** pinned pages show on the Resources home */
  pinned?: boolean;
}

export type ChannelKind = "chat" | "activity" | "dm";

export interface Channel {
  id: string;
  name: string;
  kind: ChannelKind;
  /** for dm channels: the member names in the conversation */
  members?: string[];
  order: number;
  /** channels can be archived, not deleted */
  archived?: boolean;
}

export type RefKind = "task" | "resource";

export interface Ref {
  type: RefKind;
  id: string;
}

export interface Message {
  id: string;
  channelId: string;
  /** null for a top-level message, else the message it replies to */
  parentId: string | null;
  author: string;
  at: number;
  body: string;
  mentions: string[];
  refs: Ref[];
  /** emoji -> member names who reacted */
  reactions: Record<string, string[]>;
  editedAt?: number;
  deleted?: boolean;
}

export type ActivityKind =
  | "add"
  | "remove"
  | "done"
  | "reopen"
  | "progress"
  | "dates"
  | "category"
  | "milestone"
  | "owners"
  | "todo_add"
  | "todo_done"
  | "todo_tag"
  | "rename"
  | "notes"
  | "res_add"
  | "res_rename";

export interface ActivityEvent {
  id: string;
  who: string;
  at: number;
  kind: ActivityKind;
  task?: string;
  from?: string;
  to?: string | number;
  on?: boolean;
  added?: string[];
  removed?: string[];
  tag?: string[];
  text?: string;
  title?: string;
}

export interface Snapshot {
  settings: Settings;
  members: Member[];
  categories: Category[];
  tasks: Task[];
  resources: ResourceNode[];
  channels: Channel[];
  messages: Message[];
  activity: ActivityEvent[];
}

export type SnapshotPatch = Partial<Snapshot>;
