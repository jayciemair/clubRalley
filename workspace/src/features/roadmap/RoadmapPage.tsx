import { useState } from "react";
import { useWorkspace } from "@/store/workspaceStore";
import { useUi } from "@/store/ui";
import { me } from "@/store/identity";
import { PageHeader } from "@/ui/PageHeader";
import { Icon } from "@/ui/Icon";
import "@/ui/page.css";
import "./roadmap.css";
import { Timeline } from "./Timeline";
import { CalendarView } from "./CalendarView";
import { TaskDialog } from "./TaskDialog";
import { doneCount, visibleTasks } from "./selectors";

export function RoadmapPage() {
  const snap = useWorkspace((s) => s.snap!);
  const updateSettings = useWorkspace((s) => s.updateSettings);
  const {
    hiddenCategories,
    hideDone,
    mineOnly,
    calCursor,
    toggleCategory,
    showAllCategories,
    setHideDone,
    setMineOnly,
    setCalCursor,
  } = useUi();

  const [view, setView] = useState<"timeline" | "calendar">("timeline");
  const [editing, setEditing] = useState<string | "new" | null>(null);

  const tasks = visibleTasks(snap, { hiddenCategories, hideDone, mineOnly, me: me() });
  const nDone = doneCount(snap, hiddenCategories);
  const nMine = snap.tasks.filter(
    (t) => me() && (t.owners.includes(me()) || t.todos.some((d) => !d.done && d.tag.includes(me()))),
  ).length;
  const allCatIds = snap.categories.map((c) => c.id);

  return (
    <div className="roadmap">
      <PageHeader title="Roadmap">
        <div className="seg" role="group" aria-label="Zoom">
          <button
            aria-pressed={snap.settings.zoom === "weeks"}
            onClick={() => updateSettings({ zoom: "weeks" })}
          >
            Weeks
          </button>
          <button
            aria-pressed={snap.settings.zoom === "days"}
            onClick={() => updateSettings({ zoom: "days" })}
          >
            Days
          </button>
        </div>
        <div className="seg" role="group" aria-label="View">
          <button aria-pressed={view === "timeline"} onClick={() => setView("timeline")}>
            Timeline
          </button>
          <button aria-pressed={view === "calendar"} onClick={() => setView("calendar")}>
            Calendar
          </button>
        </div>
        <button className="btn primary" onClick={() => setEditing("new")}>
          <Icon name="plus" /> Add task
        </button>
      </PageHeader>

      <div className="filterbar">
        <span className="fb-label">Filter</span>
        {me() && (
          <button
            className="chip"
            aria-pressed={mineOnly}
            style={{ ["--chipc" as string]: "var(--accent)" }}
            onClick={() => setMineOnly(!mineOnly)}
          >
            <i /> Mine · {nMine}
          </button>
        )}
        {snap.categories.map((c) => (
          <button
            key={c.id}
            className="chip"
            aria-pressed={!hiddenCategories.includes(c.id)}
            style={{ ["--chipc" as string]: c.color }}
            onClick={() => toggleCategory(c.id, allCatIds)}
          >
            <i /> {c.name}
          </button>
        ))}
        {nDone > 0 && (
          <button
            className="chip"
            aria-pressed={!hideDone}
            style={{ ["--chipc" as string]: "var(--ok)" }}
            onClick={() => setHideDone(!hideDone)}
          >
            <i /> Done · {nDone}
          </button>
        )}
        {hiddenCategories.length > 0 && (
          <button className="fb-all" onClick={showAllCategories}>
            Show all
          </button>
        )}
      </div>

      {view === "timeline" ? (
        <Timeline tasks={tasks} zoom={snap.settings.zoom} onOpenTask={setEditing} />
      ) : (
        <CalendarView
          tasks={tasks}
          cursor={calCursor}
          setCursor={setCalCursor}
          onOpenTask={setEditing}
        />
      )}

      <div className="legend">
        {snap.categories.map((c) => (
          <span key={c.id}>
            <i style={{ background: c.color }} /> {c.name}
          </span>
        ))}
      </div>

      {editing && <TaskDialog taskId={editing} onClose={() => setEditing(null)} />}
    </div>
  );
}
