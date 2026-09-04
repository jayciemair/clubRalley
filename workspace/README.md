# Club Ralley Workspace

The team's internal tool: **Roadmap** (timeline + calendar), **Resources**
(nested wiki), and **Chat** (Slack-style channels, threads, DMs) — one app,
one sign-in.

Built with Vite + React + TypeScript. It runs two ways:

| Mode | When | Data |
|---|---|---|
| **Local** | no Supabase env vars set | stays in your browser only — for trying it out |
| **Shared** | Supabase env vars set | one live database everyone shares (Phase 5) |

Right now it ships in **local mode**. Wiring the shared database is
[SETUP-SUPABASE.md](./SETUP-SUPABASE.md) (do that once Club Ralley's own
Supabase project exists).

---

## Run it locally

```bash
npm install
npm run dev          # http://localhost:5173
```

First visit: **Create an account** → your name, email, a password you choose,
and the **team join code** (default `ralley` — change it later in Settings).
Everything is stored in this browser only until Supabase is connected.

```bash
npm run build        # type-checks, then builds to dist/
npm run preview      # serve the production build
```

## Deploy

**Recommended — connect the repo to Netlify** so nobody needs Node after setup:

1. Push this folder to a Git repo.
2. Netlify → **Add new site → Import from Git** → pick the repo.
3. Build command `npm run build`, publish directory `dist` (already in
   `netlify.toml`).
4. Site config → **Environment variables** → add the three `VITE_*` values from
   [SETUP-SUPABASE.md](./SETUP-SUPABASE.md) once you have them.

**Or drag-and-drop:** `npm run build`, then drag the `dist/` folder onto
<https://app.netlify.com/drop>. You'll redo this on every change.

## Project layout

```
src/
  auth/        sign-in / accounts (LocalAuth now, SupabaseAuth in Phase 5)
  data/        types, the adapter interface, LocalAdapter, seed data
  store/       Zustand stores: workspace data, identity, per-viewer UI prefs
  lib/         dates, activity-feed diffing, @mention + ref parsing, hashing
  ui/          shared components (Icon, Dialog, Avatar, MarkdownView, …)
  features/
    auth/      the sign-in screen
    shell/     left nav + account menu
    roadmap/   timeline, calendar, task editor, filters
    resources/ category grid, page tree, markdown editor
    chat/      channel list, messages, composer, threads, reactions
supabase/schema.sql   run this in Club Ralley's Supabase SQL editor (Phase 5)
```

## How the data layer works

Everything goes through **`WorkspaceAdapter`** (`src/data/adapter.ts`). The app
never talks to storage directly. `LocalAdapter` persists a JSON snapshot to
`localStorage` and mirrors writes to other tabs via `BroadcastChannel`.
`SupabaseAdapter` (Phase 5) will map the same interface onto real Postgres
tables with realtime. Switching is one env-var check in `src/config.ts`.

## What's done / what's next

**Working now:** accounts + join code, roadmap timeline & calendar, drag bars,
filters, task editor with to-dos & @-tags, nested Resources wiki with Markdown,
chat channels + DMs + threads + reactions, @mentions and `#`-linked
task/resource chips in messages, the auto **#activity** feed, light/dark themes.

**Phase 5 (needs the Supabase project):** `SupabaseAdapter` + `SupabaseAuth`,
realtime sync, "import from the old board", password-reset emails.

**Polish backlog:** drag-to-reorder in the Resources tree, a mention
notification banner, CSV export, richer milestone styling.
