import { useState } from "react";
import { Dialog } from "@/ui/Dialog";
import { Avatar } from "@/ui/Avatar";
import { Icon } from "@/ui/Icon";
import { useAuth } from "@/auth/useAuth";
import { runtimeMode } from "@/config";

export function AccountDialog({ onClose }: { onClose: () => void }) {
  const { session, signOut, changePassword } = useAuth();
  const [cur, setCur] = useState("");
  const [next, setNext] = useState("");
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);
  const [busy, setBusy] = useState(false);

  async function doChange(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    const err = await changePassword(cur, next);
    setBusy(false);
    if (err) setMsg({ ok: false, text: err });
    else {
      setMsg({ ok: true, text: "Password updated." });
      setCur("");
      setNext("");
    }
  }

  return (
    <Dialog title="Your account" onClose={onClose} width={420}>
      <div className="acct-head">
        <Avatar name={session?.displayName ?? "?"} size={40} />
        <div>
          <strong>{session?.displayName}</strong>
          <div className="hint">{session?.email}</div>
        </div>
      </div>

      <form onSubmit={doChange} className="acct-form">
        <label className="auth-field">
          <span>Current password</span>
          <input
            className="field"
            type="password"
            value={cur}
            onChange={(e) => setCur(e.target.value)}
            autoComplete="current-password"
            required
          />
        </label>
        <label className="auth-field">
          <span>New password</span>
          <input
            className="field"
            type="password"
            value={next}
            onChange={(e) => setNext(e.target.value)}
            autoComplete="new-password"
            minLength={8}
            required
          />
        </label>
        {msg && (
          <p className={msg.ok ? "acct-ok" : "auth-err"}>{msg.text}</p>
        )}
        <button className="btn primary" disabled={busy}>
          {busy ? "…" : "Change password"}
        </button>
      </form>

      {runtimeMode === "local" && (
        <p className="hint">
          <Icon name="alert" size={12} /> Local mode: this account lives only in this
          browser.
        </p>
      )}

      <button
        className="btn"
        style={{ alignSelf: "flex-start" }}
        onClick={async () => {
          await signOut();
          onClose();
        }}
      >
        <Icon name="logout" /> Sign out
      </button>
    </Dialog>
  );
}
