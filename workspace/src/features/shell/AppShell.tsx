import { useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "@/auth/useAuth";
import { useWorkspace } from "@/store/workspaceStore";
import { useSeen } from "@/store/identity";
import { useUi } from "@/store/ui";
import { runtimeMode } from "@/config";
import { Icon } from "@/ui/Icon";
import { Avatar } from "@/ui/Avatar";
import { unreadFor } from "@/features/chat/unread";
import { AccountDialog } from "./AccountDialog";
import "./shell.css";

export function AppShell() {
  const settings = useWorkspace((s) => s.snap?.settings);
  const channels = useWorkspace((s) => s.snap?.channels ?? []);
  const messages = useWorkspace((s) => s.snap?.messages ?? []);
  const activity = useWorkspace((s) => s.snap?.activity ?? []);
  const seen = useSeen((s) => s.seen);
  const session = useAuth((s) => s.session);
  const { theme, setTheme } = useUi();
  const [accountOpen, setAccountOpen] = useState(false);

  const chatUnread = channels
    .filter((c) => !c.archived)
    .reduce(
      (n, c) => n + unreadFor(c, messages, activity, seen[c.id] ?? 0, session?.displayName ?? ""),
      0,
    );

  const nextTheme = theme === "system" ? "light" : theme === "light" ? "dark" : "system";

  return (
    <div className="shell">
      <nav className="shell-nav">
        <div className="shell-brand">
          <div className="shell-glyph">
            <Icon name="hash" size={15} />
          </div>
          <div className="shell-brand-txt">
            <strong className="display">{settings?.title ?? "Club Ralley"}</strong>
            <span>{settings?.subtitle}</span>
          </div>
        </div>

        <div className="shell-links">
          <NavLink to="/" end className="shell-link">
            <Icon name="timeline" /> Roadmap
          </NavLink>
          <NavLink to="/resources" className="shell-link">
            <Icon name="book" /> Resources
          </NavLink>
          <NavLink to="/chat" className="shell-link">
            <Icon name="chat" /> Chat
            {chatUnread > 0 && <span className="shell-badge">{chatUnread}</span>}
          </NavLink>
        </div>

        <div className="shell-foot">
          <button className="shell-acct" onClick={() => setAccountOpen(true)}>
            <Avatar name={session?.displayName ?? "?"} size={24} />
            <span>{session?.displayName}</span>
            <Icon name="chevDown" size={13} />
          </button>
          <button
            className="btn ghost shell-theme"
            onClick={() => setTheme(nextTheme)}
            title={`Theme: ${theme}`}
          >
            <Icon name="sun" /> {theme}
          </button>
          {runtimeMode === "local" && (
            <span className="shell-mode" title="Data stays in this browser until Supabase is connected">
              local mode
            </span>
          )}
        </div>
      </nav>

      <main className="shell-main">
        <Outlet />
      </main>

      {accountOpen && <AccountDialog onClose={() => setAccountOpen(false)} />}
    </div>
  );
}
