import { useState } from "react";
import { Navigate, Route, Routes, useNavigate, useParams } from "react-router-dom";
import { useWorkspace } from "@/store/workspaceStore";
import { useSeen, me } from "@/store/identity";
import { Icon } from "@/ui/Icon";
import "@/ui/page.css";
import "./chat.css";
import { ChannelView } from "./ChannelView";
import { unreadFor } from "./unread";

function ChannelList() {
  const snap = useWorkspace((s) => s.snap!);
  const createChannel = useWorkspace((s) => s.createChannel);
  const openDm = useWorkspace((s) => s.openDm);
  const seen = useSeen((s) => s.seen);
  const nav = useNavigate();
  const { channelId } = useParams();
  const [adding, setAdding] = useState(false);
  const [name, setName] = useState("");
  const [dmPick, setDmPick] = useState(false);

  const chat = snap.channels
    .filter((c) => c.kind === "chat" || c.kind === "activity")
    .sort((a, b) => a.order - b.order);
  const dms = snap.channels.filter((c) => c.kind === "dm");
  const others = snap.members.map((m) => m.name).filter((n) => n !== me());

  const renderItem = (c: (typeof snap.channels)[number]) => {
    const n = unreadFor(c, snap.messages, snap.activity, seen[c.id] ?? 0, me());
    return (
      <button
        key={c.id}
        className={`chan-item${c.id === channelId ? " on" : ""}`}
        onClick={() => nav(`/chat/${c.id}`)}
      >
        <Icon name={c.kind === "activity" ? "timeline" : c.kind === "dm" ? "people" : "hash"} size={13} />
        <span>{c.name}</span>
        {n > 0 && <em>{n}</em>}
      </button>
    );
  };

  return (
    <aside className="chan-list">
      <div className="chan-group">
        <span className="chan-group-h">Channels</span>
        {chat.map(renderItem)}
        {adding ? (
          <form
            className="chan-add"
            onSubmit={async (e) => {
              e.preventDefault();
              if (!name.trim()) return;
              const cid = await createChannel(name);
              setName("");
              setAdding(false);
              nav(`/chat/${cid}`);
            }}
          >
            <input
              className="field"
              autoFocus
              placeholder="channel-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              onBlur={() => !name && setAdding(false)}
            />
          </form>
        ) : (
          <button className="chan-item add" onClick={() => setAdding(true)}>
            <Icon name="plus" size={13} /> <span>Add channel</span>
          </button>
        )}
      </div>

      <div className="chan-group">
        <span className="chan-group-h">Direct messages</span>
        {dms.map(renderItem)}
        {dmPick ? (
          <div className="chan-dm-pick">
            {others.map((n) => (
              <button
                key={n}
                onClick={async () => {
                  const cid = await openDm([n]);
                  setDmPick(false);
                  nav(`/chat/${cid}`);
                }}
              >
                {n}
              </button>
            ))}
            <button className="cancel" onClick={() => setDmPick(false)}>
              cancel
            </button>
          </div>
        ) : (
          <button className="chan-item add" onClick={() => setDmPick(true)}>
            <Icon name="plus" size={13} /> <span>New message</span>
          </button>
        )}
      </div>
    </aside>
  );
}

function ChannelRoute() {
  const { channelId } = useParams();
  const snap = useWorkspace((s) => s.snap!);
  const ch = snap.channels.find((c) => c.id === channelId);
  if (!ch) return <Navigate to="/chat" replace />;
  return <ChannelView channel={ch} />;
}

function ChatIndex() {
  const snap = useWorkspace((s) => s.snap!);
  const first = snap.channels.find((c) => c.kind === "chat") ?? snap.channels[0];
  return <Navigate to={first ? `/chat/${first.id}` : "/chat"} replace />;
}

export function ChatPage() {
  return (
    <div className="chat">
      <ChannelList />
      <Routes>
        <Route index element={<ChatIndex />} />
        <Route path=":channelId" element={<ChannelRoute />} />
        <Route path="*" element={<Navigate to="/chat" replace />} />
      </Routes>
    </div>
  );
}
