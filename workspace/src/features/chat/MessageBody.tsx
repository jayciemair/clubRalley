import { useNavigate } from "react-router-dom";
import { useWorkspace } from "@/store/workspaceStore";
import { me } from "@/store/identity";
import { segmentMessage } from "@/lib/mentions";

export function MessageBody({ text }: { text: string }) {
  const snap = useWorkspace((s) => s.snap!);
  const nav = useNavigate();
  const roster = snap.members.map((m) => m.name);
  const segs = segmentMessage(text, roster);

  return (
    <span className="msg-body">
      {segs.map((seg, i) => {
        if (seg.kind === "text") return <span key={i}>{seg.value}</span>;
        if (seg.kind === "mention")
          return (
            <span key={i} className={`mention${seg.name === me() ? " me" : ""}`}>
              @{seg.name}
            </span>
          );
        if (seg.kind === "link")
          return (
            <a key={i} href={seg.href} target="_blank" rel="noopener noreferrer nofollow">
              {seg.label}
            </a>
          );
        // ref chip
        if (seg.ref.type === "task") {
          const t = snap.tasks.find((x) => x.id === seg.ref.id);
          return (
            <button
              key={i}
              className="ref-chip task"
              onClick={() => nav(`/?task=${seg.ref.id}`)}
              title="Roadmap task"
            >
              ◷ {t ? t.name : "task"}
            </button>
          );
        }
        const r = snap.resources.find((x) => x.id === seg.ref.id);
        return (
          <button
            key={i}
            className="ref-chip res"
            onClick={() =>
              nav(
                r?.pinned
                  ? `/resources/_pinned/${seg.ref.id}`
                  : `/resources/${r?.categoryId ?? ""}/${seg.ref.id}`,
              )
            }
            title="Resource page"
          >
            ▤ {r ? r.title : "page"}
          </button>
        );
      })}
    </span>
  );
}
