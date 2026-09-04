import type { Member } from "@/data/types";

function hue(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 360;
  return h;
}

export function memberColor(name: string, members: Member[]): string {
  const m = members.find((x) => x.name === name);
  if (m && m.color) return m.color;
  return `hsl(${hue(name || "")} 42% 45%)`;
}

/** One letter, unless another roster name shares the first letter — then two. */
export function initials(name: string, roster: string[]): string {
  if (!name) return "?";
  const n = name.trim();
  const first = (n[0] || "?").toUpperCase();
  const clash = roster.some(
    (o) => o !== n && o[0] && o[0].toUpperCase() === first,
  );
  return clash ? n.slice(0, 2).toUpperCase() : first;
}

export function esc(s: unknown): string {
  return String(s == null ? "" : s).replace(
    /[&<>"']/g,
    (c) =>
      ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      })[c] as string,
  );
}
