# 12 Inches

A vinyl collection tracker. Pulls live prices from Discogs, logs what you listen to,
and records how records make you feel — including where in your body you felt it.

Runs as a Progressive Web App: static files on GitHub Pages, with Supabase for
accounts and sync. No build step, no framework, no server to run.

**Live:** https://pethav5.github.io/DiscPlus/

---

# THREE BIG DUDES

## Files

| File | What it is |
|---|---|
| `app.html` | The entire app — markup, styles, and logic in one file |
| `index.html` | Redirect to `app.html` (keeps iOS from saving a bad home-screen URL) |
| `manifest.json` | PWA manifest — app name, colors, icons |
| `icon-192.png` / `icon-512.png` | Home screen icons |
| `schema.sql` | Database setup — run once in Supabase, never deployed |
| `.gitignore` | Keeps local junk out of the repo |

Everything lives in `app.html` on purpose. It's a single-user app with no build
tooling, so one file means no import paths to break and no bundler to configure.

---

## First-time setup

### 1. Supabase (once)

Two things in the [dashboard](https://supabase.com/dashboard/project/evsyndvdzaryxmulrlbm):

**Run the schema.** SQL Editor → New query → paste all of `schema.sql` → Run.
Creates `records`, `listens`, and `settings` with row-level security so each
account can only read and write its own rows.

**Disable email confirmation.** Authentication → Sign In / Providers → Email →
uncheck "Confirm email" → Save. The free tier's mailer is rate-limited to a few
messages per hour, so leaving this on means signup emails silently never arrive.

### 2. Discogs token (once, in the app)

Get one at [discogs.com/settings/developers](https://www.discogs.com/settings/developers)
→ "Generate new token". Paste it into Settings in the app. Without it the app
still works but is rate-limited to 25 requests/minute instead of 60.

### 3. Add to your phone

Open the live URL in **Safari** (not Chrome — only Safari can install PWAs on iOS),
then Share → Add to Home Screen.

---

## Working on it in VS Code

```bash
git clone https://github.com/pethav5/DiscPlus.git
cd DiscPlus
code .
```

### Previewing changes

`app.html` needs to be served over HTTP, not opened as a `file://` URL — the
Supabase client and Discogs API calls both break otherwise. Easiest options:

**Live Server extension** (recommended) — install "Live Server" from the
Extensions panel, then right-click `app.html` → "Open with Live Server".
Auto-reloads on save.

**Or Python**, already on macOS:

```bash
python3 -m http.server 8000
# then open http://localhost:8000/app.html
```

### Deploying

GitHub Pages rebuilds automatically on every push. Takes 30–60 seconds.

```bash
git add .
git commit -m "what you changed"
git push
```

### If the phone shows a stale version

iOS caches aggressively. Delete the home screen icon, open the URL in Safari,
pull down to hard-refresh, then re-add to home screen.

---

## How it's put together

**Data flow.** Supabase is the source of truth. `localStorage` is a per-user
cache keyed by user ID, so the app paints instantly on open and then reconciles
against the server. Every mutation writes locally and pushes remotely.

**Rate limiting.** Discogs allows 60 requests/minute authenticated, 25
unauthenticated. Every API call goes through `dg()` and waits `gap()`
milliseconds between requests. Bulk operations like price refreshes and wantlist
checks are sequential by necessity, so a 300-record collection takes ~6 minutes
to fully reprice. It backs off 8 seconds on a 429.

**Suggestions** aren't a Discogs feature — there's no recommendation endpoint.
The app tallies the genres, styles, and artists in your collection, then pulls
three candidate sets: other releases by artists you own, well-collected releases
in your top styles, and a genre fallback. Candidates are scored by how many
signals they match and deduped against what you already have.

**The body map** is modeled on Nummenmaa et al.'s bodily-maps-of-emotions work
(PNAS, 2014), which is why chest, throat, and head are separate regions — those
are where music most often registers physically. `BODY_REGIONS` is a flat array
of 19 shape definitions; the same array drives both the tappable input diagram
and the aggregate heat map in the Feelings tab, so adding a region updates both.

**Colors** are Pitt royal blue (`#003594`) and gold (`#FFB81C`), defined as CSS
custom properties in `:root`. Change those six variables and the whole app
re-themes.

---

## Notes on the free tier

**Projects pause after 7 days of inactivity.** If you don't open the app for a
week, the first launch after that will fail to load. One button in the Supabase
dashboard resumes it, ~30 seconds.

**No automatic backups.** Settings → Download backup (JSON) exports everything.
Worth doing occasionally.

**The publishable key in `app.html` is meant to be public.** It only permits what
the row-level security policies allow. Do not put the *service role* key in this
file — that one bypasses RLS entirely.

---

## Known rough edges

- Wantlist marketplace checks need one API call per release, so a long wantlist is slow
- No offline support — the service worker was removed because iOS cached a 404 and served it indefinitely
- Listens are capped at the 1000 most recent
- Deleting a record leaves its listen history in place, which is deliberate but means the Feelings tab can reference records you no longer own
