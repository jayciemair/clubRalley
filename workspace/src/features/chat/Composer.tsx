import { useMemo, useRef, useState } from "react";
import { useWorkspace } from "@/store/workspaceStore";
import { refToken } from "@/lib/mentions";
import type { Ref } from "@/data/types";

type Suggestion =
  | { kind: "person"; label: string; insert: string }
  | { kind: "ref"; label: string; insert: string; ref: Ref };

export function Composer({
  placeholder,
  onSend,
}: {
  placeholder: string;
  onSend: (text: string) => void;
}) {
  const snap = useWorkspace((s) => s.snap!);
  const ref = useRef<HTMLTextAreaElement>(null);
  const [text, setText] = useState("");
  const [menu, setMenu] = useState<{ items: Suggestion[]; token: string; kind: "@" | "#" } | null>(
    null,
  );
  const [active, setActive] = useState(0);

  const people = useMemo(() => snap.members.map((m) => m.name), [snap.members]);

  function autosize() {
    const el = ref.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = Math.min(140, el.scrollHeight) + "px";
  }

  function refreshMenu(value: string, caret: number) {
    const before = value.slice(0, caret);
    const m = before.match(/(^|\s)([@#])([\w'-]*)$/);
    if (!m) {
      setMenu(null);
      return;
    }
    const kind = m[2] as "@" | "#";
    const q = m[3].toLowerCase();
    let items: Suggestion[] = [];
    if (kind === "@") {
      items = people
        .filter((n) => n.toLowerCase().startsWith(q))
        .map((n) => ({ kind: "person", label: n, insert: `@${n} ` }));
    } else {
      const tasks: Suggestion[] = snap.tasks
        .filter((t) => t.name.toLowerCase().includes(q))
        .slice(0, 6)
        .map((t) => ({
          kind: "ref",
          label: `◷ ${t.name}`,
          insert: refToken({ type: "task", id: t.id }) + " ",
          ref: { type: "task", id: t.id },
        }));
      const pages: Suggestion[] = snap.resources
        .filter((r) => r.title.toLowerCase().includes(q))
        .slice(0, 6)
        .map((r) => ({
          kind: "ref",
          label: `▤ ${r.title}`,
          insert: refToken({ type: "resource", id: r.id }) + " ",
          ref: { type: "resource", id: r.id },
        }));
      items = [...tasks, ...pages].slice(0, 8);
    }
    if (!items.length) {
      setMenu(null);
      return;
    }
    setActive(0);
    setMenu({ items, token: m[3], kind });
  }

  function applySuggestion(s: Suggestion) {
    const el = ref.current;
    if (!el) return;
    const caret = el.selectionStart;
    const before = text.slice(0, caret).replace(/([@#])[\w'-]*$/, "");
    const after = text.slice(caret);
    const next = before + s.insert + after;
    setText(next);
    setMenu(null);
    requestAnimationFrame(() => {
      el.focus();
      const pos = (before + s.insert).length;
      el.setSelectionRange(pos, pos);
      autosize();
    });
  }

  function send() {
    const v = text.trim();
    if (!v) return;
    onSend(v);
    setText("");
    setMenu(null);
    requestAnimationFrame(autosize);
  }

  return (
    <div className="composer">
      {menu && (
        <div className="composer-menu">
          {menu.items.map((it, i) => (
            <button
              key={i}
              className={i === active ? "on" : ""}
              onMouseDown={(e) => {
                e.preventDefault();
                applySuggestion(it);
              }}
            >
              {it.label}
            </button>
          ))}
        </div>
      )}
      <textarea
        ref={ref}
        className="field"
        rows={1}
        placeholder={placeholder}
        value={text}
        maxLength={4000}
        onChange={(e) => {
          setText(e.target.value);
          autosize();
          refreshMenu(e.target.value, e.target.selectionStart);
        }}
        onKeyDown={(e) => {
          if (menu) {
            if (e.key === "ArrowDown") {
              e.preventDefault();
              setActive((a) => (a + 1) % menu.items.length);
              return;
            }
            if (e.key === "ArrowUp") {
              e.preventDefault();
              setActive((a) => (a - 1 + menu.items.length) % menu.items.length);
              return;
            }
            if (e.key === "Enter" || e.key === "Tab") {
              e.preventDefault();
              applySuggestion(menu.items[active]);
              return;
            }
            if (e.key === "Escape") {
              setMenu(null);
              return;
            }
          }
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            send();
          }
        }}
        onBlur={() => setTimeout(() => setMenu(null), 150)}
      />
      <button className="btn primary" onClick={send} disabled={!text.trim()}>
        Send
      </button>
    </div>
  );
}
