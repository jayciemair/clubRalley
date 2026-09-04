import { useMemo, useState } from "react";
import type { Task, Todo } from "@/data/types";
import { useWorkspace } from "@/store/workspaceStore";
import { Dialog } from "@/ui/Dialog";
import { Avatar } from "@/ui/Avatar";
import { Icon } from "@/ui/Icon";
import { id } from "@/lib/ids";
import { clampProgress, nstr, todayNum } from "@/lib/dates";
import "./task-dialog.css";

export function TaskDialog({
  taskId,
  onClose,
}: {
  taskId: string | "new";
  onClose: () => void;
}) {
  const snap = useWorkspace((s) => s.snap!);
  const saveTask = useWorkspace((s) => s.saveTask);
  const deleteTask = useWorkspace((s) => s.deleteTask);

  const existing = taskId !== "new" ? snap.tasks.find((t) => t.id === taskId) : undefined;

  const base: Task = useMemo(
    () =>
      existing ?? {
        id: id("t"),
        name: "",
        owners: [],
        categoryId: snap.categories[0]?.id ?? "",
        start: nstr(todayNum()),
        end: nstr(todayNum() + 4),
        progress: 0,
        milestone: false,
        notes: "",
        todos: [],
        order: snap.tasks.length,
      },
    [existing, snap.categories, snap.tasks.length],
  );

  const [draft, setDraft] = useState<Task>(base);
  const [todoText, setTodoText] = useState("");
  const [tagOpen, setTagOpen] = useState<string | null>(null);

  const set = <K extends keyof Task>(k: K, v: Task[K]) => setDraft((d) => ({ ...d, [k]: v }));

  function toggleOwner(name: string) {
    set(
      "owners",
      draft.owners.includes(name)
        ? draft.owners.filter((o) => o !== name)
        : [...draft.owners, name],
    );
  }

  function addTodo() {
    const t = todoText.trim();
    if (!t) return;
    set("todos", [...draft.todos, { id: id("d"), text: t, done: false, tag: [] }]);
    setTodoText("");
  }
  function patchTodo(tid: string, patch: Partial<Todo>) {
    set(
      "todos",
      draft.todos.map((d) => (d.id === tid ? { ...d, ...patch } : d)),
    );
  }

  function save() {
    const end =
      draft.milestone || draft.end < draft.start ? draft.start : draft.end;
    void saveTask({
      ...draft,
      name: draft.name.trim() || "Untitled",
      progress: clampProgress(draft.progress),
      end,
      todos: draft.todos.filter((d) => d.text.trim()),
    });
    onClose();
  }

  return (
    <Dialog
      title={existing ? "Edit task" : "New task"}
      onClose={onClose}
      width={480}
      footer={
        <>
          {existing && (
            <button
              className="btn ghost"
              style={{ color: "var(--danger)" }}
              onClick={() => {
                void deleteTask(existing.id);
                onClose();
              }}
            >
              Delete
            </button>
          )}
          <span className="spacer" />
          <button className="btn" onClick={onClose}>
            Cancel
          </button>
          <button className="btn primary" onClick={save}>
            Save
          </button>
        </>
      }
    >
      <label className="tf">
        <span>Task name</span>
        <input
          className="field"
          value={draft.name}
          maxLength={120}
          autoFocus
          onChange={(e) => set("name", e.target.value)}
        />
      </label>

      <div className="tf">
        <span>People</span>
        <div className="people">
          {snap.members.map((m) => (
            <button
              key={m.name}
              type="button"
              className={`ppl${draft.owners.includes(m.name) ? " on" : ""}`}
              onClick={() => toggleOwner(m.name)}
            >
              <Avatar name={m.name} size={17} />
              {m.name}
            </button>
          ))}
        </div>
      </div>

      <div className="tf-row">
        <label className="tf">
          <span>Category</span>
          <select
            className="field"
            value={draft.categoryId}
            onChange={(e) => set("categoryId", e.target.value)}
          >
            {snap.categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="tf">
          <span>Progress · {clampProgress(draft.progress)}%</span>
          <input
            type="range"
            min={0}
            max={100}
            step={5}
            value={draft.progress}
            onChange={(e) => set("progress", Number(e.target.value))}
          />
        </label>
      </div>

      <div className="tf-row">
        <label className="tf">
          <span>Start</span>
          <input
            className="field"
            type="date"
            value={draft.start}
            onChange={(e) => set("start", e.target.value)}
          />
        </label>
        <label className="tf">
          <span>End</span>
          <input
            className="field"
            type="date"
            value={draft.end}
            disabled={draft.milestone}
            onChange={(e) => set("end", e.target.value)}
          />
        </label>
      </div>

      <label className="tf-check">
        <input
          type="checkbox"
          checked={draft.milestone}
          onChange={(e) => set("milestone", e.target.checked)}
        />
        Milestone (single day, shown as a diamond)
      </label>

      <label className="tf">
        <span>Description / notes</span>
        <textarea
          className="field"
          rows={3}
          maxLength={2000}
          value={draft.notes}
          onChange={(e) => set("notes", e.target.value)}
        />
      </label>

      <div className="tf">
        <span>To-do list</span>
        <div className="todos">
          {draft.todos.map((d) => (
            <div key={d.id} className="todo">
              <input
                type="checkbox"
                checked={d.done}
                onChange={(e) => patchTodo(d.id, { done: e.target.checked })}
              />
              <input
                className="todo-text"
                value={d.text}
                onChange={(e) => patchTodo(d.id, { text: e.target.value })}
              />
              <div className="todo-tag-wrap">
                <button
                  type="button"
                  className={`todo-tag${d.tag.length ? " on" : ""}`}
                  onClick={() => setTagOpen(tagOpen === d.id ? null : d.id)}
                >
                  {d.tag.length ? d.tag.join(", ") : "Tag"}
                </button>
                {tagOpen === d.id && (
                  <div className="tag-pop">
                    {snap.members.map((m) => (
                      <button
                        key={m.name}
                        type="button"
                        aria-pressed={d.tag.includes(m.name)}
                        onClick={() =>
                          patchTodo(d.id, {
                            tag: d.tag.includes(m.name)
                              ? d.tag.filter((n) => n !== m.name)
                              : [...d.tag, m.name],
                          })
                        }
                      >
                        {m.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <button
                type="button"
                className="btn icon ghost"
                onClick={() => set("todos", draft.todos.filter((x) => x.id !== d.id))}
              >
                <Icon name="x" size={13} />
              </button>
            </div>
          ))}
          <div className="todo-add">
            <input
              className="field"
              placeholder="Add a to-do…"
              value={todoText}
              maxLength={200}
              onChange={(e) => setTodoText(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  addTodo();
                }
              }}
            />
            <button type="button" className="btn" onClick={addTodo}>
              Add
            </button>
          </div>
        </div>
      </div>
    </Dialog>
  );
}
