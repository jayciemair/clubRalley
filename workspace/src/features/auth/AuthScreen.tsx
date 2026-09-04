import { useState } from "react";
import { useAuth } from "@/auth/useAuth";
import { runtimeMode } from "@/config";
import { Icon } from "@/ui/Icon";
import "./auth.css";

type Mode = "in" | "up" | "reset";

export function AuthScreen() {
  const [mode, setMode] = useState<Mode>("in");
  const { signIn, signUp, requestReset, completeReset } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [joinCode, setJoinCode] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // reset flow — local mode: ask -> code -> done. Supabase mode: ask -> sent
  // (the emailed link signs them in directly; no code step applies).
  const [resetStage, setResetStage] = useState<"ask" | "code" | "sent">("ask");
  const [code, setCode] = useState("");
  const [devCode, setDevCode] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setBusy(true);
    try {
      if (mode === "in") {
        setErr(await signIn(email, password));
      } else if (mode === "up") {
        setErr(await signUp({ email, password, displayName: name, joinCode }));
      } else if (resetStage === "ask") {
        const r = await requestReset(email);
        if (typeof r === "string") setErr(r);
        else if (runtimeMode === "supabase") {
          setResetStage("sent");
        } else {
          setResetStage("code");
          setDevCode(r.devCode ?? null);
        }
      } else if (resetStage === "code") {
        const r = await completeReset(email, code, password);
        if (r) setErr(r);
        else {
          setMode("in");
          setResetStage("ask");
          setErr(null);
        }
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-wrap">
      <form className="auth-card" onSubmit={submit}>
        <div className="auth-glyph">
          <Icon name="lock" size={18} />
        </div>
        <h1 className="display">Club Ralley</h1>
        <p className="hint auth-sub">
          {mode === "in" && "Sign in to the workspace."}
          {mode === "up" && "Create your account. You'll need the team join code."}
          {mode === "reset" && resetStage === "ask" &&
            (runtimeMode === "supabase"
              ? "Enter your email and we'll send you a reset link."
              : "Enter your email and we'll send a reset code.")}
          {mode === "reset" && resetStage === "code" && "Enter the code and your new password."}
          {mode === "reset" && resetStage === "sent" &&
            "Check your email for a reset link. Opening it signs you back in — from there, set a new password under your account menu."}
        </p>

        {mode === "up" && (
          <label className="auth-field">
            <span>Your name</span>
            <input
              className="field"
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={40}
              autoComplete="name"
              required
            />
            <small className="hint">Shown on everything you post — can't be changed later.</small>
          </label>
        )}

        {resetStage !== "sent" && (
          <label className="auth-field">
            <span>Email</span>
            <input
              className="field"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              required
            />
          </label>
        )}

        {mode !== "reset" && (
          <label className="auth-field">
            <span>Password</span>
            <div className="auth-pw">
              <input
                className="field"
                type={showPw ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete={mode === "in" ? "current-password" : "new-password"}
                minLength={8}
                required
              />
              <button
                type="button"
                className="btn icon ghost"
                onClick={() => setShowPw((v) => !v)}
                aria-label={showPw ? "Hide password" : "Show password"}
              >
                <Icon name="eye" />
              </button>
            </div>
            {mode === "up" && (
              <small className="hint">At least 8 characters, with a letter and a number.</small>
            )}
          </label>
        )}

        {mode === "reset" && resetStage === "code" && (
          <label className="auth-field">
            <span>New password</span>
            <div className="auth-pw">
              <input
                className="field"
                type={showPw ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="new-password"
                minLength={8}
                required
              />
              <button
                type="button"
                className="btn icon ghost"
                onClick={() => setShowPw((v) => !v)}
                aria-label={showPw ? "Hide password" : "Show password"}
              >
                <Icon name="eye" />
              </button>
            </div>
          </label>
        )}

        {mode === "reset" && resetStage === "code" && (
          <label className="auth-field">
            <span>Reset code</span>
            <input
              className="field mono"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              inputMode="numeric"
              required
            />
            {devCode && (
              <small className="hint">
                Local mode has no email — your code is <strong>{devCode}</strong>.
              </small>
            )}
          </label>
        )}

        {mode === "up" && (
          <label className="auth-field">
            <span>Team join code</span>
            <input
              className="field"
              value={joinCode}
              onChange={(e) => setJoinCode(e.target.value)}
              required
            />
            <small className="hint">Ask a founder for this. Keeps outsiders from making accounts.</small>
          </label>
        )}

        {err && <p className="auth-err">{err}</p>}

        {resetStage !== "sent" && (
          <button className="btn primary auth-submit" disabled={busy}>
            {busy
              ? "…"
              : mode === "in"
                ? "Sign in"
                : mode === "up"
                  ? "Create account"
                  : resetStage === "ask"
                    ? runtimeMode === "supabase"
                      ? "Send reset link"
                      : "Send reset code"
                    : "Set new password"}
          </button>
        )}

        <div className="auth-switch">
          {mode !== "in" && (
            <button
              type="button"
              className="linky"
              onClick={() => {
                setMode("in");
                setResetStage("ask");
                setErr(null);
              }}
            >
              Back to sign in
            </button>
          )}
          {mode === "in" && (
            <>
              <button type="button" className="linky" onClick={() => { setMode("up"); setErr(null); }}>
                Create an account
              </button>
              <button type="button" className="linky" onClick={() => { setMode("reset"); setErr(null); }}>
                Forgot password
              </button>
            </>
          )}
        </div>

        {runtimeMode === "local" && (
          <p className="auth-local">
            <Icon name="alert" size={13} /> Local mode — accounts &amp; data stay in this
            browser only. Real accounts start once Supabase is connected.
          </p>
        )}
      </form>
    </div>
  );
}
