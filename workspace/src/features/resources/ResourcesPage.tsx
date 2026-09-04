import { Navigate, Route, Routes, useNavigate, useParams } from "react-router-dom";
import { useWorkspace } from "@/store/workspaceStore";
import { PageHeader } from "@/ui/PageHeader";
import { Icon } from "@/ui/Icon";
import "@/ui/page.css";
import "./resources.css";
import { CategoryView } from "./CategoryView";

function ResourcesHome() {
  const snap = useWorkspace((s) => s.snap!);
  const nav = useNavigate();
  const pinned = snap.resources.filter((r) => r.pinned);

  return (
    <div className="page-body">
      <div className="res-pinned">
        {pinned.map((p) => (
          <button key={p.id} className="res-pin" onClick={() => nav(`/resources/_pinned/${p.id}`)}>
            <Icon name="note" />
            <div>
              <strong>{p.title}</strong>
              <span className="hint">
                {p.body.slice(0, 90).replace(/[#*_>\n]/g, " ").trim() || "—"}
              </span>
            </div>
          </button>
        ))}
      </div>

      <h2 className="res-h2">Categories</h2>
      <div className="res-grid">
        {snap.categories.map((c) => {
          const count = snap.resources.filter((r) => r.categoryId === c.id).length;
          return (
            <button
              key={c.id}
              className="res-card"
              style={{ ["--cc" as string]: c.color }}
              onClick={() => nav(`/resources/${c.id}`)}
            >
              <span className="res-card-dot" />
              <strong>{c.name}</strong>
              <span className="hint">
                {count} {count === 1 ? "page" : "pages"}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function PinnedRoute() {
  const { pageId } = useParams();
  return <CategoryView categoryId="" focusPageId={pageId} pinned />;
}

function CategoryRoute() {
  const { categoryId, pageId } = useParams();
  const snap = useWorkspace((s) => s.snap!);
  if (!snap.categories.some((c) => c.id === categoryId)) return <Navigate to="/resources" replace />;
  return <CategoryView categoryId={categoryId!} focusPageId={pageId} />;
}

export function ResourcesPage() {
  return (
    <div className="roadmap">
      <PageHeader title="Resources">
        <BackToResources />
      </PageHeader>
      <Routes>
        <Route index element={<ResourcesHome />} />
        <Route path="_pinned/:pageId" element={<PinnedRoute />} />
        <Route path=":categoryId" element={<CategoryRoute />} />
        <Route path=":categoryId/:pageId" element={<CategoryRoute />} />
        <Route path="*" element={<Navigate to="/resources" replace />} />
      </Routes>
    </div>
  );
}

function BackToResources() {
  const nav = useNavigate();
  const loc = window.location.pathname;
  if (loc === "/resources" || loc === "/resources/") return null;
  return (
    <button className="btn" onClick={() => nav("/resources")}>
      <Icon name="chevL" /> All categories
    </button>
  );
}
