import type { Ref } from "@/data/types";

function reEsc(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Names (longest first) found as `@Name` in the text. */
export function parseMentions(text: string, roster: string[]): string[] {
  const hits: string[] = [];
  const ordered = [...roster].sort((a, b) => b.length - a.length);
  for (const n of ordered) {
    if (!n) continue;
    const re = new RegExp("@" + reEsc(n) + "(?![\\w'-])", "i");
    if (re.test(text) && !hits.includes(n)) hits.push(n);
  }
  return hits;
}

const REF_RE = /\[\[(task|resource):([A-Za-z0-9_-]+)\]\]/g;

/** Ref tokens `[[task:id]]` / `[[resource:id]]` found in the text. */
export function parseRefs(text: string): Ref[] {
  const out: Ref[] = [];
  let m: RegExpExecArray | null;
  REF_RE.lastIndex = 0;
  while ((m = REF_RE.exec(text))) {
    const type = m[1].toLowerCase() as Ref["type"];
    if (!out.some((r) => r.type === type && r.id === m![2]))
      out.push({ type, id: m[2] });
  }
  return out;
}

export function refToken(ref: Ref): string {
  return `[[${ref.type}:${ref.id}]]`;
}

/** Split a message body into typed segments for rendering. */
export type Segment =
  | { kind: "text"; value: string }
  | { kind: "mention"; name: string }
  | { kind: "ref"; ref: Ref }
  | { kind: "link"; href: string; label: string };

export function segmentMessage(text: string, roster: string[]): Segment[] {
  const names = [...roster].sort((a, b) => b.length - a.length).map(reEsc);
  const nameAlt = names.length ? names.join("|") : "\\u0000";
  const master = new RegExp(
    `\\[\\[(task|resource):([A-Za-z0-9_-]+)\\]\\]` +
      `|@(${nameAlt})(?![\\w'-])` +
      `|(https?:\\/\\/[^\\s<>()]+)`,
    "gi",
  );
  const out: Segment[] = [];
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = master.exec(text))) {
    if (m.index > last) out.push({ kind: "text", value: text.slice(last, m.index) });
    if (m[1]) {
      out.push({ kind: "ref", ref: { type: m[1].toLowerCase() as Ref["type"], id: m[2] } });
    } else if (m[3]) {
      out.push({ kind: "mention", name: m[3] });
    } else if (m[4]) {
      out.push({ kind: "link", href: m[4], label: m[4].replace(/^https?:\/\//, "") });
    }
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push({ kind: "text", value: text.slice(last) });
  return out;
}
