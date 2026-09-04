import { useEffect, useMemo, useRef, useState } from "react";
import type { Channel, Message } from "@/data/types";
import { useWorkspace } from "@/store/workspaceStore";
import { useSeen, me } from "@/store/identity";
import { parseMentions, parseRefs } from "@/lib/mentions";
import { relTime } from "@/lib/dates";
import { activityText } from "@/lib/activity";
import { Avatar } from "@/ui/Avatar";
import { Icon } from "@/ui/Icon";
import { Composer } from "./Composer";
import { MessageBody } from "./MessageBody";

const EMOJI = ["👍", "🎉", "❤️", "✅", "👀", "🔥"];

export function ChannelView({ channel }: { channel: Channel }) {
  const snap = useWorkspace((s) => s.snap!);
  const sendMessage = useWorkspace((s) => s.sendMessage);
  const markSeen = useSeen((s) => s.markSeen);
  const [thread, setThread] = useState<string | null>(null);

  useEffect(() => {
    markSeen(channel.id);
    const t = setInterval(() => markSeen(channel.id), 4000);
    return () => clearInterval(t);
  }, [channel.id, markSeen, snap.messages.length]);

  useEffect(() => setThread(null), [channel.id]);

  if (channel.kind === "activity") return <ActivityChannel />;

  const roster = snap.members.map((m) => m.name);
  const top = snap.messages
    .filter((m) => m.channelId === channel.id && !m.parentId)
    .sort((a, b) => a.at - b.at);

  function post(text: string, parentId: string | null = null) {
    void sendMessage({
      channelId: channel.id,
      parentId,
      author: me(),
      body: text,
      mentions: parseMentions(text, roster),
      refs: parseRefs(text),
      reactions: {},
    });
  }

  const threadMsg = thread ? snap.messages.find((m) => m.id === thread) : null;

  return (
    <div className="channel">
      <div className={`channel-main${thread ? " with-thread" : ""}`}>
        <header className="channel-head">
          <Icon name={channel.kind === "dm" ? "people" : "hash"} size={15} />
          <strong>{channel.name}</strong>
          {channel.kind === "dm" && <span className="hint">Direct message</span>}
        </header>

        <MessageList
          messages={top}
          allMessages={snap.messages}
          onOpenThread={setThread}
        />

        <div className="channel-composer">
          <Composer placeholder={`Message ${channel.kind === "dm" ? channel.name : "#" + channel.name}`} onSend={(t) => post(t)} />
        </div>
      </div>

      {threadMsg && (
        <ThreadPanel
          root={threadMsg}
          replies={snap.messages
            .filter((m) => m.parentId === threadMsg.id)
            .sort((a, b) => a.at - b.at)}
          onClose={() => setThread(null)}
          onReply={(t) => post(t, threadMsg.id)}
        />
      )}
    </div>
  );
}

function MessageList({
  messages,
  allMessages,
  onOpenThread,
}: {
  messages: Message[];
  allMessages: Message[];
  onOpenThread: (id: string) => void;
}) {
  const bottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ block: "end" });
  }, [messages.length]);

  if (!messages.length)
    return (
      <div className="channel-body">
        <p className="chat-empty">No messages yet. Say hi 👋</p>
        <div ref={bottomRef} />
      </div>
    );

  return (
    <div className="channel-body">
      {messages.map((m) => (
        <MessageItem
          key={m.id}
          msg={m}
          replyCount={allMessages.filter((x) => x.parentId === m.id).length}
          onOpenThread={() => onOpenThread(m.id)}
        />
      ))}
      <div ref={bottomRef} />
    </div>
  );
}

export function MessageItem({
  msg,
  replyCount = 0,
  onOpenThread,
  compact,
}: {
  msg: Message;
  replyCount?: number;
  onOpenThread?: () => void;
  compact?: boolean;
}) {
  const toggleReaction = useWorkspace((s) => s.toggleReaction);
  const editMessage = useWorkspace((s) => s.editMessage);
  const deleteMessage = useWorkspace((s) => s.deleteMessage);
  const [picker, setPicker] = useState(false);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(msg.body);
  const mine = msg.author === me();

  return (
    <div className={`chat-msg${mine ? " mine" : ""}${msg.mentions.includes(me()) && !mine ? " ping" : ""}`}>
      <Avatar name={msg.author} size={26} />
      <div className="chat-msg-main">
        <div className="chat-msg-meta">
          <strong>{msg.author}</strong>
          <span className="chat-time">{relTime(msg.at)}</span>
          {msg.editedAt && <span className="chat-time">(edited)</span>}
        </div>

        {msg.deleted ? (
          <em className="chat-deleted">message deleted</em>
        ) : editing ? (
          <div className="chat-edit">
            <textarea
              className="field"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              rows={2}
            />
            <div>
              <button
                className="btn primary"
                onClick={() => {
                  void editMessage(msg.id, draft.trim() || msg.body);
                  setEditing(false);
                }}
              >
                Save
              </button>
              <button className="btn" onClick={() => setEditing(false)}>
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <div className="chat-msg-text">
            <MessageBody text={msg.body} />
          </div>
        )}

        {!msg.deleted && (
          <div className="chat-reactions">
            {Object.entries(msg.reactions).map(([emoji, names]) => (
              <button
                key={emoji}
                className={`reaction${names.includes(me()) ? " on" : ""}`}
                onClick={() => void toggleReaction(msg.id, emoji)}
                title={names.join(", ")}
              >
                {emoji} {names.length}
              </button>
            ))}
            <div className="chat-msg-tools">
              <button className="tool" onClick={() => setPicker((v) => !v)} title="React">
                <Icon name="smile" size={14} />
              </button>
              {!compact && onOpenThread && (
                <button className="tool" onClick={onOpenThread} title="Reply in thread">
                  <Icon name="reply" size={14} />
                </button>
              )}
              {mine && (
                <>
                  <button className="tool" onClick={() => { setDraft(msg.body); setEditing(true); }} title="Edit">
                    ✏️
                  </button>
                  <button className="tool" onClick={() => void deleteMessage(msg.id)} title="Delete">
                    <Icon name="x" size={13} />
                  </button>
                </>
              )}
            </div>
            {picker && (
              <div className="emoji-pop">
                {EMOJI.map((e) => (
                  <button
                    key={e}
                    onClick={() => {
                      void toggleReaction(msg.id, e);
                      setPicker(false);
                    }}
                  >
                    {e}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        {!compact && replyCount > 0 && (
          <button className="thread-open" onClick={onOpenThread}>
            <Icon name="reply" size={12} /> {replyCount} {replyCount === 1 ? "reply" : "replies"}
          </button>
        )}
      </div>
    </div>
  );
}

function ThreadPanel({
  root,
  replies,
  onClose,
  onReply,
}: {
  root: Message;
  replies: Message[];
  onClose: () => void;
  onReply: (text: string) => void;
}) {
  return (
    <div className="thread-panel">
      <header className="channel-head">
        <strong>Thread</strong>
        <button className="btn icon ghost" onClick={onClose} style={{ marginLeft: "auto" }}>
          <Icon name="x" />
        </button>
      </header>
      <div className="channel-body">
        <MessageItem msg={root} compact />
        <div className="thread-divider">
          {replies.length} {replies.length === 1 ? "reply" : "replies"}
        </div>
        {replies.map((r) => (
          <MessageItem key={r.id} msg={r} compact />
        ))}
      </div>
      <div className="channel-composer">
        <Composer placeholder="Reply…" onSend={onReply} />
      </div>
    </div>
  );
}

function ActivityChannel() {
  const activity = useWorkspace((s) => s.snap!.activity);
  const sorted = useMemo(() => [...activity].sort((a, b) => b.at - a.at), [activity]);
  return (
    <div className="channel">
      <div className="channel-main">
        <header className="channel-head">
          <Icon name="timeline" size={15} />
          <strong>activity</strong>
          <span className="hint">Every change to the roadmap, automatically</span>
        </header>
        <div className="channel-body">
          {!sorted.length && <p className="chat-empty">No activity yet.</p>}
          {sorted.map((a) => (
            <div key={a.id} className="activity-row">
              <Avatar name={a.who} size={20} />
              <span>
                <strong>{a.who}</strong> {activityText(a)}{" "}
                <span className="chat-time">· {relTime(a.at)}</span>
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
