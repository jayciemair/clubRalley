import { useEffect } from "react";
import { createBrowserRouter, Navigate, RouterProvider } from "react-router-dom";
import { useAuth } from "@/auth/useAuth";
import { useWorkspace } from "@/store/workspaceStore";
import { AuthScreen } from "@/features/auth/AuthScreen";
import { AppShell } from "@/features/shell/AppShell";
import { RoadmapPage } from "@/features/roadmap/RoadmapPage";
import { ResourcesPage } from "@/features/resources/ResourcesPage";
import { ChatPage } from "@/features/chat/ChatPage";
import { Splash } from "@/ui/Splash";

const router = createBrowserRouter([
  {
    path: "/",
    element: <AppShell />,
    children: [
      { index: true, element: <RoadmapPage /> },
      { path: "resources/*", element: <ResourcesPage /> },
      { path: "chat/*", element: <ChatPage /> },
      { path: "*", element: <Navigate to="/" replace /> },
    ],
  },
]);

export default function App() {
  const authReady = useAuth((s) => s.ready);
  const session = useAuth((s) => s.session);
  const initAuth = useAuth((s) => s.init);

  const wsReady = useWorkspace((s) => s.ready);
  const wsError = useWorkspace((s) => s.error);
  const initWs = useWorkspace((s) => s.init);

  useEffect(() => {
    void initAuth();
  }, [initAuth]);

  useEffect(() => {
    if (session && !wsReady) void initWs();
  }, [session, wsReady, initWs]);

  // First time someone with a brand-new account opens the workspace, add them
  // to the member roster — otherwise they'd have no avatar colour and
  // couldn't be assigned to tasks or @-tagged.
  useEffect(() => {
    if (!session || !wsReady) return;
    const snap = useWorkspace.getState().snap;
    if (!snap) return;
    if (snap.members.some((m) => m.name === session.displayName)) return;
    void useWorkspace.getState().updateMembers([...snap.members, { name: session.displayName, color: "" }]);
  }, [session, wsReady]);

  if (!authReady) return <Splash label="Starting up…" />;
  if (!session) return <AuthScreen />;
  if (wsError) return <Splash label={`Couldn't load the workspace: ${wsError}`} error />;
  if (!wsReady) return <Splash label="Loading the workspace…" />;

  return <RouterProvider router={router} />;
}
