import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import type { ResourceNode } from "@/data/types";
import { useWorkspace } from "@/store/workspaceStore";
import { MarkdownView } from "@/ui/MarkdownView";
import { Icon } from "@/ui/Icon";

interface TreeItem {
  node: ResourceNode;
  depth: number;
}

function buildTree(nodes: ResourceNode[]): TreeItem[] {
  const byParent = new Map<string | null, ResourceNode[]>();
  for (const n of nodes) {
    const k = n.parentId;
    if (!byParent.has(k)) byParent.set(k, []);
    byParent.get(k)!.push(n);
  }
  for (const list of byParent.values()) list.sort((a, b) => a.order - b.order);
  const out: TreeItem[] = [];
  const walk = (parent: string | null, depth: number) => {
    for (const n of byParent.get(parent) ?? []) {
      out.push({ node: n, depth });
      walk(n.id, depth + 1);
    }
  };
  walk(null, 0);
  return out;
}

export function CategoryView({
  categoryId,
  focusPageId,
  pinned,
}: {
  categoryId: string;
  focusPageId?: string;
  pinned?: boolean;
}) {
  const snap = useWorkspace((s) => s.snap!);
  const saveResource = useWorkspace((s) => s.saveResource);
  const deleteResource = useWorkspace((s) => s.deleteResource);
  const addResource = useWorkspace((s) => s.addResource);
  const nav = useNavigate();

  const category = snap.categories.find((c) => c.id === categoryId);
  const nodes = useMemo(
    () => snap.resources.filter((r) => (pinned ? r.pinned : r.categoryId === categoryId && !r.pinned)),
    [snap.resources, categoryId, pinned],
  );
  const tree = useMemo(() => (pinned ? nodes.map((n) => ({ node: n, depth: 0 })) : buildTree(nodes)), [nodes, pinned]);

  const selectedId = focusPageId ?? tree[0]?.node.id;
  const selected = snap.resources.find((r) => r.id === selectedId);

  const [editing, setEditing] = useState(false);
  const [body, setBody] = useState(selected?.body ?? "");
  const [title, setTitle] = useState(selected?.title ?? "");

  useEffect(() => {
    setEditing(false);
    setBody(selected?.body ?? "");
    setTitle(selected?.title ?? "");
  }, [selectedId, selected?.body, selected?.title]);

  function go(pageId: string) {
    nav(pinned ? `/resources/_pinned/${pageId}` : `/resources/${categoryId}/${pageId}`);
  }

  function saveEdits() {
    if (!selected) return;
    void saveResource({ ...selected, title: title.trim() || "Untitled", body });
    setEditing(false);
  }

  async function addChild(parentId: string | null) {
    const newId = await addResource(pinned ? "" : categoryId, parentId);
    if (newId) go(newId);
  }

  return (
    <div className="res-cat">
      <aside className="res-tree">
        <div className="res-tree-head">
          <strong>{pinned ? "Pinned" : category?.name}</strong>
          <button className="btn icon ghost" onClick={() => addChild(null)} title="Add page">
            <Icon name="plus" size={14} />
          </button>
        </div>
        {tree.length === 0 && <p className="hint" style={{ padding: "8px 10px" }}>No pages yet.</p>}
        {tree.map(({ node, depth }) => (
          <button
            key={node.id}
            className={`res-tree-item${node.id === selectedId ? " on" : ""}`}
            style={{ paddingLeft: 10 + depth * 14 }}
            onClick={() => go(node.id)}
          >
            <Icon name="note" size={13} />
            <span>{node.title}</span>
          </button>
        ))}
      </aside>

      <section className="res-page">
        {!selected ? (
          <div className="empty">
            <div className="empty-glyph">
              <Icon name="book" size={18} />
            </div>
            Nothing here yet.
            <button className="btn primary" onClick={() => addChild(null)}>
              <Icon name="plus" /> New page
            </button>
          </div>
        ) : editing ? (
          <>
            <input
              className="field res-title-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={120}
            />
            <div className="res-editor">
              <textarea
                className="field res-textarea"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Markdown — # headings, - lists, [links](url), | tables |, - [ ] checkboxes"
              />
              <div className="res-preview">
                <MarkdownView>{body}</MarkdownView>
              </div>
            </div>
            <div className="res-actions">
              <button className="btn primary" onClick={saveEdits}>
                Save
              </button>
              <button className="btn" onClick={() => setEditing(false)}>
                Cancel
              </button>
            </div>
          </>
        ) : (
          <>
            <div className="res-page-head">
              <h2>{selected.title}</h2>
              <div className="res-page-tools">
                <button className="btn" onClick={() => setEditing(true)}>
                  Edit
                </button>
                <button className="btn ghost" onClick={() => addChild(selected.id)} title="Add sub-page">
                  <Icon name="plus" size={14} /> Sub-page
                </button>
                {!selected.pinned && (
                  <button
                    className="btn ghost"
                    style={{ color: "var(--danger)" }}
                    onClick={() => {
                      if (confirm(`Delete "${selected.title}" and any sub-pages?`)) {
                        void deleteResource(selected.id);
                        nav(pinned ? "/resources" : `/resources/${categoryId}`);
                      }
                    }}
                  >
                    Delete
                  </button>
                )}
              </div>
            </div>
            <MarkdownView>{selected.body}</MarkdownView>
          </>
        )}
      </section>
    </div>
  );
}
