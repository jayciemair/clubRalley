import { useEffect, useRef } from "react";
import {
  DndContext,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { restrictToVerticalAxis } from "@dnd-kit/modifiers";
import type { Category, Task } from "@/data/types";
import { useWorkspace } from "@/store/workspaceStore";
import { dnum, mondayOnOrBefore, weekday } from "@/lib/dates";
import { Icon } from "@/ui/Icon";
import { AvatarStack } from "@/ui/Avatar";
import { computeLayout, type Zoom } from "./layout";
import { useBarDrag } from "./useBarDrag";
import { isDone, isOverdue } from "./selectors";

export function Timeline({
  tasks,
  zoom,
  onOpenTask,
}: {
  tasks: Task[];
  zoom: Zoom;
  onOpenTask: (id: string) => void;
}) {
  const categories = useWorkspace((s) => s.snap!.categories);
  const reorderTasks = useWorkspace((s) => s.reorderTasks);
  const allTasks = useWorkspace((s) => s.snap!.tasks);
  const boardRef = useRef<HTMLDivElement>(null);
  const didCenter = useRef(false);

  const L = computeLayout(tasks.length ? tasks : allTasks, zoom);

  useEffect(() => {
    if (didCenter.current || !boardRef.current) return;
    didCenter.current = true;
    boardRef.current.scrollLeft = Math.max(0, (L.today - L.gridStart) * L.dayW - 240);
  }, [L.today, L.gridStart, L.dayW]);

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }));

  function onDragEnd(e: DragEndEvent) {
    const { active, over } = e;
    if (!over || active.id === over.id) return;
    const ids = tasks.map((t) => t.id);
    const from = ids.indexOf(String(active.id));
    const to = ids.indexOf(String(over.id));
    if (from < 0 || to < 0) return;
    ids.splice(to, 0, ids.splice(from, 1)[0]);
    void reorderTasks(ids);
  }

  const months = monthSegments(L.gridStart, L.totalDays, L.dayW);
  const cols = columnTicks(L.gridStart, L.totalDays, zoom);

  return (
    <div className="board" ref={boardRef}>
      <div className="board-inner" style={{ width: `calc(var(--rail-w) + ${L.width}px)` }}>
        <div className="grid-head" style={{ width: L.width, marginLeft: "var(--rail-w)" }}>
          <div className="months">
            {months.map((m) => (
              <div key={m.start} className="month" style={{ left: m.left, width: m.width }}>
                {m.label}
              </div>
            ))}
          </div>
          <div className="cols">
            {cols.map((c) => (
              <div key={c.n} className="col-tick" style={{ left: (c.n - L.gridStart) * L.dayW }}>
                {c.label}
              </div>
            ))}
          </div>
        </div>

        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          modifiers={[restrictToVerticalAxis]}
          onDragEnd={onDragEnd}
        >
          <SortableContext items={tasks.map((t) => t.id)} strategy={verticalListSortingStrategy}>
            <div className="rows">
              <div
                className="today-line"
                style={{ left: `calc(var(--rail-w) + ${(L.today - L.gridStart) * L.dayW}px)` }}
              />
              {tasks.length === 0 && (
                <div className="rows-empty">No tasks match the filters.</div>
              )}
              {tasks.map((t) => (
                <Row
                  key={t.id}
                  task={t}
                  category={categories.find((c) => c.id === t.categoryId)}
                  layout={L}
                  onOpen={() => onOpenTask(t.id)}
                />
              ))}
            </div>
          </SortableContext>
        </DndContext>
      </div>
    </div>
  );
}

function Row({
  task,
  category,
  layout: L,
  onOpen,
}: {
  task: Task;
  category?: Category;
  layout: ReturnType<typeof computeLayout>;
  onOpen: () => void;
}) {
  const saveTask = useWorkspace((s) => s.saveTask);
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: task.id,
  });
  const busyRef = useRef(false);

  const drag = useBarDrag({
    task,
    dayW: L.dayW,
    onCommit: (patch) => void saveTask({ ...task, ...patch }),
    onBusyChange: (b) => (busyRef.current = b),
  });

  const color = category?.color ?? "var(--faint)";
  const s = dnum(task.start);
  const e = dnum(task.end || task.start);
  const left = (s - L.gridStart) * L.dayW;
  const width = Math.max(L.dayW, (e - s + 1) * L.dayW);
  const done = isDone(task);
  const overdue = isOverdue(task);
  const todoTotal = task.todos.length;
  const todoDone = task.todos.filter((d) => d.done).length;

  return (
    <div
      ref={setNodeRef}
      className={`row${isDragging ? " row-dragging" : ""}`}
      style={{ transform: CSS.Transform.toString(transform), transition }}
    >
      <div className="rail-row">
        <button className="drag-h" {...attributes} {...listeners} aria-label="Reorder">
          <Icon name="grip" size={14} />
        </button>
        <button className="rail-name" onClick={onOpen}>
          <span className="dot" style={{ background: color }} />
          <span className={`rail-title${done ? " done" : ""}`}>{task.name}</span>
          {todoTotal > 0 && (
            <span className="rail-todo">
              {todoDone}/{todoTotal}
            </span>
          )}
        </button>
        <AvatarStack names={task.owners} size={20} />
      </div>

      <div className="lane" onClick={onOpen}>
        {task.milestone ? (
          <div
            className="ms"
            style={{ left: left + L.dayW / 2, background: color }}
            title={task.name}
          />
        ) : (
          <div
            className={`bar${overdue ? " overdue" : ""}`}
            style={{
              left,
              width,
              background: `color-mix(in srgb, ${color} ${done ? "34%" : "88%"}, var(--surface))`,
              borderColor: color,
            }}
            onClick={(ev) => {
              if (drag.didDrag()) ev.stopPropagation();
            }}
            {...drag.bodyHandlers}
          >
            <span className="bar-edge left" {...drag.edgeHandlers("start")} />
            <span className="bar-fill" style={{ width: `${task.progress}%`, background: color }} />
            <span className="bar-label">{task.name}</span>
            <span className="bar-edge right" {...drag.edgeHandlers("end")} />
          </div>
        )}
      </div>
    </div>
  );
}

function monthSegments(gridStart: number, totalDays: number, dayW: number) {
  const out: { start: number; left: number; width: number; label: string }[] = [];
  let n = gridStart;
  while (n < gridStart + totalDays) {
    const d = new Date(n * 86_400_000);
    const monthEnd = Math.floor(
      Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1) / 86_400_000,
    );
    const segEnd = Math.min(monthEnd, gridStart + totalDays);
    out.push({
      start: n,
      left: (n - gridStart) * dayW,
      width: (segEnd - n) * dayW,
      label: d.toLocaleDateString(undefined, { month: "short", year: "numeric", timeZone: "UTC" }),
    });
    n = segEnd;
  }
  return out;
}

function columnTicks(gridStart: number, totalDays: number, zoom: Zoom) {
  const out: { n: number; label: string }[] = [];
  const step = zoom === "weeks" ? 7 : 1;
  let n = mondayOnOrBefore(gridStart);
  if (n < gridStart) n += 7;
  for (; n < gridStart + totalDays; n += step) {
    if (zoom === "days" && weekday(n) !== 0) continue;
    const d = new Date(n * 86_400_000);
    out.push({ n, label: `${d.getUTCDate()}` });
  }
  return out;
}
