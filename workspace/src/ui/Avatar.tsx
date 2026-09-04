import { useWorkspace } from "@/store/workspaceStore";
import { initials, memberColor } from "@/lib/people";

function roster(names: string[]): string[] {
  return names;
}

export function Avatar({ name, size = 22 }: { name: string; size?: number }) {
  const members = useWorkspace((s) => s.snap?.members ?? []);
  const names = members.map((m) => m.name);
  return (
    <span
      className="avatar"
      title={name}
      style={{
        width: size,
        height: size,
        fontSize: Math.round(size * 0.42),
        background: memberColor(name, members),
      }}
    >
      {initials(name, roster(names))}
    </span>
  );
}

export function AvatarStack({ names, size = 22 }: { names: string[]; size?: number }) {
  if (!names.length) return null;
  const shown = names.slice(0, 3);
  const extra = names.length - shown.length;
  return (
    <span className="avstack" style={{ display: "inline-flex" }}>
      {shown.map((n) => (
        <Avatar key={n} name={n} size={size} />
      ))}
      {extra > 0 && (
        <span
          className="avatar"
          title={names.slice(3).join(", ")}
          style={{
            width: size,
            height: size,
            fontSize: Math.round(size * 0.4),
            background: "var(--faint)",
          }}
        >
          +{extra}
        </span>
      )}
    </span>
  );
}
