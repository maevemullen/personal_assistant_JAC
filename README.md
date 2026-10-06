# Planner

**Maeve Mullen** · UMID: `49762477`

A personal planner for coursework deadlines and a daily task list, written
entirely in [Jac](https://www.jaseci.org/). One server holds all your tasks;
a web app, a mobile app and a command-line tool all read and write the same
data.

In short: add tasks with a due date, priority, time estimate and category; see
them by day, on a calendar or by category; check them off from any of the three
interfaces; and keep yourself going with a weekly **Progress** dashboard
(streaks, on-time rate, hours by category, personal bests). The web app is
designed like a printed newspaper page.

## Features

- **Add a task** from the web, the mobile app, or the CLI. Each task has a
  title, due date (defaults to today), priority, time needed
  (`<30 min`, `1hr`, `2hr` or `3+hr`; default `1hr`), an optional category,
  and a progress status.
- **Mark complete** from all three: the round button on the web, tapping a
  task on mobile, or `done <number>` in the CLI. Each one can be undone.
- **Four web views**, switched with tabs at the top of the task list:
  - **List**: tasks grouped under their due date (with today, tomorrow and
    overdue labels; finished tasks go last within a day), or switch to
    **By category** to group tasks with the same category together.
  - **Calendar**: a month grid with each task on its due date. Click a day to
    see its tasks and check them off. On a phone-width screen each day shows a
    count instead.
  - **Completed**: finished tasks grouped by week, month or year, with counts
    for this week, month and year. Undoing a task here moves it back to open.
  - **Progress**: a motivation dashboard for the current week (Monday to
    Sunday). It has a short written recap; tasks and estimated hours done
    compared with last week; your day streak and best streak; the share
    finished on time; high-priority tasks and quick wins done; your best week
    (with a "Best week yet" banner when you beat it); a day-by-day bar chart;
    hours by category; today's quick tasks under 30 minutes; your oldest open
    high-priority task ("Eat the frog"); and everything finished this week.
    Hours are estimates from each task's time (`<30 min` counts as 0.5).
- **Due-soon highlights and nudges:** open tasks due today are highlighted in
  yellow and tomorrow's in a lighter yellow. Tasks under 30 minutes get a short
  encouraging note. Within a day, higher-priority tasks are listed first.
- **Editorial design:** the web app is styled like a printed page: warm paper,
  black ink, serif type, a newspaper-style masthead with today's date, and thin
  rules in place of cards.
- **Search** (web): a search box above the task list filters the List,
  Calendar and Completed views as you type. Every word you type must match the task's title, category,
  priority, time, due date or status (so `calc quiz`, `high`, `3+hr`,
  `2026-10-07` or `done` all work). `Esc` or **Clear** resets it.
- **Edit a task** from the web (any view): click the pencil icon to change its
  title, due date, priority, time, category or progress status (todo, doing,
  done). Tasks marked "doing" show an **in progress** tag.
- **Delete a task** from the web (any view): click the trash icon, then confirm.
  Deleting is permanent.
- **One shared list:** a task added in any interface shows up in the other two.
- **Persists across restarts:** tasks are nodes on the Jac graph, which the
  server saves automatically.
- **Clear errors:** bad input (an empty title, a malformed date) is rejected
  with a message, and the CLI tells you to start the server if it isn't running.

Planned next: automatic categorization of new tasks with a local AI model.

## Prerequisites

1. **Jac 0.37.23** (macOS or Linux):

   ```bash
   curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.37.23
   jac --version          # should print: jac 0.37.23
   ```

   The first `jac run` downloads the web build tools on its own. No other
   install step is needed.

2. **AI model setup:** not needed yet. It will be documented here when the
   auto-categorize feature is added.

No API keys or accounts are needed.

## Run it

From the repository root:

```bash
jac run
```

This starts the server and the web app:

- Web app: <http://localhost:8000>
- API: <http://localhost:8001>

If those ports are taken, Jac picks the next free ones and prints the URLs it
used. Stop it with `Ctrl+C`. Your tasks are still there the next time you start
it.

### Troubleshooting

- **"Could not reach the planner server" in the web app:** first make sure
  `jac run` is still running. If it is, the web app's build cache may be stale
  (left over from an older version of the code). Stop `jac run`, clear the
  cache, and start again:

  ```bash
  rm -rf .jac/client/web    # generated build output only; your tasks are kept
  jac run
  ```

- **Changed server code (`core/`) but nothing changed:** restart `jac run`.
  Web files reload on their own; server code does not.

### Web app

Open <http://localhost:8000>. Fill in a task and press **Add task**. Leave the
due date blank to use today. Pick a **Time** estimate, and choose a
**Category** from the dropdown of categories you've already used, or pick
**+ New category…** to write one in. (A new category that matches an existing
one ignoring case, like `eecs 449` and `EECS 449`, joins the existing one.)
Type in the **search box** to filter tasks in the List, Calendar and Completed
views. Below the form, the **List**, **Calendar**, **Completed** and **Progress**
tabs switch views; the URL keeps the open tab (for example
`#calendar`). Click the circle next to a task to mark it complete, and click it
again to undo. The pencil icon opens an edit dialog (`Esc` cancels). The trash icon deletes a task after a confirm. A task completed before completion times were recorded is
filed in **Completed** under its due date.

### CLI

With the server running (`jac run` in another terminal):

```bash
jac run cli -- add "Read chapter 4"
jac run cli -- add "Problem set 3" --due 2026-10-06 --priority high --time "<30min" --category "EECS 449"
# --time is one of <30min, 1hr, 2hr, 3+hr (quote <30min so the shell doesn't redirect)
jac run cli -- list            # numbered by due date, then priority
jac run cli -- done 2          # mark task 2 from `list` complete
jac run cli -- done 2 --undo   # mark it not done again
jac run cli -- --help
```

A task keeps its number when you complete it, so `done 2` then
`done 2 --undo` always refer to the same task. Everything after `--` goes to the
planner CLI. By default it connects to
`http://localhost:8001`. To use a different server, set
`JAC_APP_PLANNER_URL`.

Exit codes: `0` ok, `2` bad input, `3` server not reachable, `4` timeout,
`1` other failure.

### Mobile app

The mobile app is a React Native app (Expo) written with Jac's `@jac/mobui`
components, styled to match the web app (paper and ink, serif type, the same
masthead). It shows your tasks grouped by due date, with the same Today,
Tomorrow and Overdue labels, yellow highlights for today and tomorrow, "days
late" tags and quick-task notes. You can add a task (due today) and tap a task
to mark it complete. It is a frontend
only: it talks to the planner server, and its dev mode starts that server for
you.

**Mobile preview in a browser** (no phone tools needed):

```bash
# stop `jac run` first: the web app and the mobile preview can't run at the same time
jac build mobile --platform web      # on a fresh checkout, and again after changing mobile/ code
jac run --dev --platform web mobile
```

Open <http://localhost:8000>. You'll see the phone layout. Type a task and
press **Add**. Tap a task to mark it complete, and tap it again to undo. The
CLI works with this server too.

**On a phone or simulator:**

```bash
jac run --dev mobile
```

This starts Metro and the API, and prints a QR code. Open it in the
[Expo Go](https://expo.dev/go) app on a phone on the same Wi-Fi network, or
press `i` (iOS Simulator, needs Xcode) or `a` (Android emulator, needs
Android Studio). Jac points the app at your computer's LAN address
automatically; `JAC_RN_DEV_HOST` overrides it.

> Only the browser preview has been tested. The native build has not been
> tried on a real device or simulator yet.

## How the pieces fit together

```
            ┌───────────────────────────────┐
            │ planner service (core/)       │
            │ add_task, list_tasks,         │
            │ mark_complete, edit_task,     │
            │ delete_task, progress_report  │
            │ Task nodes on the Jac graph   │  ← persisted by Jac
            └──────▲──────────▲──────────▲──┘
                   │          │          │   typed calls over HTTP
            ┌──────┴───┐ ┌────┴─────┐ ┌──┴───────┐
            │ web      │ │ mobile   │ │ cli      │
            │ (React)  │ │ (RN/Expo)│ │ argparse │
            └──────────┘ └──────────┘ └──────────┘
```

- `core/planner.jac` is the **planner service app**. It holds all planning
  logic as `def:pub` functions and stores each task as a `node` attached to
  `root`. The graph is the database; there is no separate one.
- `core/task_rules.jac` holds the shared validation rules (title, date
  format, levels). `core/progress_rules.jac` holds the date and hours helpers
  behind the weekly progress report.
- `web/`, `mobile/` and `cli/` each simply `import from core.planner { add_task, ... }`.
  Jac compiles those imports into typed, awaited network calls to the
  service, so none of the three reimplements the planning logic.
- There's no login, so every client uses the same shared graph. That is
  what makes one task list show up everywhere.
- `jac run` loads the planner service into the web server's process. The same
  code could run as a separate service without changes.

## What makes it impressive

- **One language for the whole stack.** The server, the web app, the mobile
  app and the CLI are all Jac, with no glue code. A client calls the server by
  importing a function (`add_task`, `progress_report`), and Jac turns that into
  a typed network call, and `jac check` type-checks those calls against the
  server's code across all three clients.
- **The graph is the database.** Tasks are nodes attached to `root`, and Jac
  saves them automatically. There is no SQL, ORM or migration code, yet data
  survives restarts.
- **Logic lives in one place.** Validation, sort order (by date, then open
  before done, then priority) and every number on the Progress dashboard are
  computed once in `core/`. The web, mobile and CLI can't disagree.
- **It's built to motivate, not just to list.** The Progress dashboard tracks
  streaks, personal bests, on-time rate and hours by category. Today's tasks
  are highlighted, quick tasks get an encouraging note, and the dashboard
  points you at your oldest high-priority task.
- **It's designed and accessible.** The editorial paper-and-ink theme has
  designed empty and overdue states, visible keyboard focus, labelled controls,
  and no motion for people who turn on "reduce motion". The layout works at
  phone width.
- **It's tested.** `jac test` runs 34 tests covering validation, the planner
  functions, the weekly progress numbers and the CLI.

| Path | What it is |
|---|---|
| `jac.toml` | Declares the four apps: `web` (default), `planner`, `mobile`, `cli` |
| `core/planner.jac` | Server: `Task` node, `add_task`, `list_tasks`, `mark_complete`, `edit_task`, `delete_task`, `progress_report` |
| `core/task_rules.jac` | Input validation and defaults |
| `core/progress_rules.jac` | Week, streak and hours helpers for the progress report |
| `web/` | Web app: `main.jac`, `PlannerPage.jac` (form and tabs), `EditTaskDialog.jac`, `Fields.jac` (shared form fields), `TaskList.jac` (task rows, date helpers), `CalendarView.jac`, `CompletedView.jac`, `ProgressView.jac`, `styles.css` |
| `mobile/` | Mobile app: `main.jac` (screen), `theme.jac` (colours, fonts, styles), `dates.jac` (date helpers) |
| `cli/` | CLI: `main.jac` (arguments), `tasks.jac` (commands) |

## Tests

```bash
jac test       # validation, planner functions, progress report, CLI parsing and output
jac check      # type-check every app
```
