import type { Task } from "@/data/types";
import { useWorkspace } from "@/store/workspaceStore";
import { addMonths, dnum, firstOfMonth, monthLabel, weekday } from "@/lib/dates";
import { Icon } from "@/ui/Icon";

export function CalendarView({
  tasks,
  cursor,
  setCursor,
  onOpenTask,
}: {
  tasks: Task[];
  cursor: number;
  setCursor: (n: number) => void;
  onOpenTask: (id: string) => void;
}) {
  const categories = useWorkspace((s) => s.snap!.categories);
  const catColor = (id: string) => categories.find((c) => c.id === id)?.color ?? "var(--faint)";

  const first = firstOfMonth(cursor);
  const startPad = weekday(first);
  const daysInMonth = firstOfMonth(addMonths(first, 1)) - first;
  const cells: (number | null)[] = [];
  for (let i = 0; i < startPad; i++) cells.push(null);
  for (let d = 0; d < daysInMonth; d++) cells.push(first + d);
  while (cells.length % 7 !== 0) cells.push(null);

  function tasksOn(n: number) {
    return tasks.filter((t) => {
      const s = dnum(t.start);
      const e = dnum(t.end || t.start);
      return n >= s && n <= e;
    });
  }

  return (
    <div className="calendar">
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
        <button className="btn icon ghost" onClick={() => setCursor(addMonths(first, -1))}>
          <Icon name="chevL" />
        </button>
        <strong style={{ fontSize: 14 }}>{monthLabel(first)}</strong>
        <button className="btn icon ghost" onClick={() => setCursor(addMonths(first, 1))}>
          <Icon name="chevR" />
        </button>
      </div>
      <div className="cal-grid">
        {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
          <div key={d} className="cal-dow">
            {d}
          </div>
        ))}
        {cells.map((n, i) => {
          if (n == null) return <div key={i} className="cal-day dim" />;
          const on = tasksOn(n);
          const hasMs = on.some((t) => t.milestone && dnum(t.start) === n);
          return (
            <div key={i} className={`cal-day${hasMs ? " ms-day" : ""}`}>
              <div className="cal-num">{new Date(n * 86_400_000).getUTCDate()}</div>
              {on.slice(0, 4).map((t) => (
                <div
                  key={t.id}
                  className="cal-seg"
                  style={{ background: catColor(t.categoryId) }}
                  onClick={() => onOpenTask(t.id)}
                  title={t.name}
                >
                  {t.milestone ? "◆ " : ""}
                  {t.name}
                </div>
              ))}
              {on.length > 4 && <div className="hint">+{on.length - 4} more</div>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
