import type { ActivityEvent, Channel, Message } from "@/data/types";

/** Count of unseen items in a channel (messages not by me, or activity events). */
export function unreadFor(
  channel: Channel,
  messages: Message[],
  activity: ActivityEvent[],
  lastSeen: number,
  me: string,
): number {
  if (channel.kind === "activity") {
    return activity.filter((a) => a.at > lastSeen && a.who !== me).length;
  }
  return messages.filter(
    (m) => m.channelId === channel.id && !m.deleted && m.at > lastSeen && m.author !== me,
  ).length;
}

/** Messages in a channel that @-mention me and are unseen. */
export function unreadMentions(
  channel: Channel,
  messages: Message[],
  lastSeen: number,
  me: string,
): number {
  if (!me) return 0;
  return messages.filter(
    (m) =>
      m.channelId === channel.id &&
      !m.deleted &&
      m.at > lastSeen &&
      m.author !== me &&
      m.mentions.includes(me),
  ).length;
}
