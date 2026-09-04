import { Icon } from "./Icon";

export function Splash({ label, error }: { label: string; error?: boolean }) {
  return (
    <div
      style={{
        minHeight: "100%",
        display: "grid",
        placeItems: "center",
        padding: 24,
        textAlign: "center",
        color: error ? "var(--danger)" : "var(--muted)",
        fontSize: 13,
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 10, alignItems: "center" }}>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 10,
            background: "var(--accent-soft)",
            color: "var(--accent-ink)",
            display: "grid",
            placeItems: "center",
          }}
        >
          <Icon name={error ? "alert" : "hash"} size={17} />
        </div>
        {label}
      </div>
    </div>
  );
}
