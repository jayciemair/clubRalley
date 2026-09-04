# Security model

What "add security measures" means here, and where the boundaries are.

## Accounts (every teammate sets their own password)

- **Local mode:** accounts live in this browser's `localStorage`. Passwords are
  hashed with PBKDF2-SHA256 (210,000 iterations, per-account random salt) — never
  stored in plaintext. This is enough to build and demo the real flow, but it is
  **not a real security boundary**: the data sits unencrypted in the browser, so
  local mode is for evaluation only.
- **Shared mode (Phase 5):** real accounts via **Supabase Auth**. Supabase
  handles password hashing, storage, sessions, and reset emails server-side.
  Passwords never touch our code.

## The join code

The old app's single shared password (`ralley`) is now a **workspace join
code**, required only at sign-up. It stops a random person who finds the URL
from creating an account. It is:

- stored as a salted SHA-256 hash (`src/lib/gate.ts`), never plaintext in the
  built JS;
- changeable by any signed-in user in Settings;
- **not** a substitute for the per-account passwords — it's a front door lock,
  not the vault.

In Phase 5 the join code is checked by a Supabase `security definer` RPC so even
its hash never ships to the browser.

## Database access (Phase 5)

`supabase/schema.sql` sets Row Level Security so **every** table read and write
requires `auth.role() = 'authenticated'` — the anonymous key alone can't touch
data. Deletes are disabled at the policy level; messages use a `deleted` flag,
everything else is updated in place. Realtime is enabled only on the tables the
app subscribes to.

> The publishable / anon key is still visible in the built JS — that's by
> design. RLS is what protects the data, not the key's secrecy.

## Content safety

- The UI is React; message text and page content render as **text nodes and a
  fixed component set** — no `dangerouslySetInnerHTML` anywhere in `src/`.
- Markdown (`react-markdown`) runs **without `rehype-raw`**, so embedded HTML in
  a resource page is shown as text, not executed.
- Links from user content open with `rel="noopener noreferrer nofollow"` in a
  new tab.
- Inputs are length-capped (task names 120, notes 2000, messages 4000, etc.).
- `netlify.toml` can carry CSP / security headers — add them when you set up the
  Netlify site (a starting `[[headers]]` block is commented there).

## What this does NOT protect against

- A teammate with a valid account can read and edit everything — there are no
  per-channel or per-page permissions. Private DMs are private by convention
  (the query filters by member), not by RLS, until Phase 5 adds per-row checks.
- Local mode offers no protection at all beyond the browser itself.
- This is a small-team internal tool. Don't store anything you'd be unwilling to
  hand to everyone on the team.
