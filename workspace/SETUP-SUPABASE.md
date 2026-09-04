# Connecting the shared database (Phase 5)

Until this is done, the app runs in **local mode** — fully usable, but data lives
in each person's browser. This wires everyone to one live database with real
accounts.

> The `SupabaseAdapter` / `SupabaseAuth` classes are stubbed right now
> (`src/data/supabaseAdapter.ts`, `src/auth/supabaseAuth.ts`). Finishing them is
> the Phase 5 work — this file is the runbook for when you're ready.

## 1. Create Club Ralley's own Supabase project

<https://supabase.com> → **New project** (free plan is fine). This is separate
from anything else — its own database, its own dashboard.

## 2. Run the schema

SQL Editor → **New query** → paste all of [`supabase/schema.sql`](./supabase/schema.sql)
→ **Run**. It creates the tables, locks them to signed-in users, sets up realtime,
and seeds the join code as `ralley`.

To change the join code later, re-run just the last `insert … on conflict` line
with your new code.

## 3. Turn on email auth

Authentication → **Providers** → Email → enabled. For a small team, turn **off**
"Confirm email" so people can sign in immediately (Authentication → Settings).

## 4. Get the two values

Project Settings → **API**:

- **Project URL** — `https://xxxx.supabase.co`
- **anon / publishable key**

## 5. Point the app at it

Create `.env` (copy `.env.example`):

```
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=<the anon key>
VITE_BOARD_ID=clubralley
```

`npm run dev` — it now runs in shared mode. On Netlify, put these same three in
**Site config → Environment variables** and redeploy.

## 6. Move the old board's data over (optional)

If the current Netlify board has tasks worth keeping: open it →
**More → Share & password → Copy board data (JSON)**. In the new app, Settings →
**Import from old board** → paste. It maps the old shape into the new one.
