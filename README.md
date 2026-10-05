# Planner

**Maeve Mullen** · UMID: `TODO-UMID`

A personal planner for coursework deadlines and a daily task list, written
entirely in [Jac](https://www.jaseci.org/). One server holds all your tasks;
a web app, a mobile app and a command-line tool all read and write the same
data.

## Features

Done so far:

- **Add a task** from the web, the mobile app, or the CLI. Each task has a
  title, due date (defaults to today), priority, time needed
  (`<30 min`, `1hr`, `2hr` or `3+hr`; default `1hr`), an optional category,
  and a progress status.
- **Mark complete** from all three: the round button on the web, tapping a
  task on mobile, or `done <number>` in the CLI. Each one can be undone.
- **Three web views**, switched with tabs at the top of the task list:
  - **List**: tasks grouped under their due date (with today, tomorrow and
    overdue labels; finished tasks go last within a day), or switch to
    **By category** to group tasks with the same category together.
  - **Calendar**: a month grid with each task on its due date. Click a day to
    see its tasks and check them off. On a phone-width screen each day shows a
    count instead.
  - **Completed**: finished tasks grouped by week, month or year, with counts
    for this week, month and year. Undoing a task here moves it back to open.
- **Animated background:** a WebGL backdrop behind the web app (Originkit's
  "Mosaic Lens", rewritten in Jac). Tiles sharpen around the mouse pointer.
- **Search** (web): a search box above the task list filters all three views as
  you type. Every word you type must match the task's title, category,
  priority, time, due date or status (so `calc quiz`, `high`, `3+hr`,
  `2026-10-07` or `done` all work). `Esc` or **Clear** resets it.
- **Delete a task** from the web (any view): click the trash icon, then confirm.
  Deleting is permanent.
- **One shared list:** a task added in any interface shows up in the other two.
- **Persists across restarts:** tasks are nodes on the Jac graph, which the
  server saves automatically.
- **Clear errors:** bad input (an empty title, a malformed date) is rejected
  with a message, and the CLI tells you to start the server if it isn't running.

Planned next: view today's tasks, edit on the web, and automatic categorization of new tasks with a local AI model.

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

Stop it with `Ctrl+C`. Your tasks are still there the next time you start it.

### Web app

Open <http://localhost:8000>. Fill in a task and press **Add task**. Leave the
due date blank to use today. Pick a **Time** estimate, and choose a
**Category** from the dropdown of categories you've already used, or pick
**+ New category…** to write one in. (A new category that matches an existing
one ignoring case, like `eecs 449` and `EECS 449`, joins the existing one.)
Type in the **search box** to filter tasks in any view. Below the form, the **List**, **Calendar** and
**Completed** tabs switch views; the URL keeps the open tab (for example
`#calendar`). Click the circle next to a task to mark it complete, and click it
again to undo. The trash icon deletes a task after a confirm. A task completed before completion times were recorded is
filed in **Completed** under its due date.

### CLI

With the server running (`jac run` in another terminal):

```bash
jac run cli -- add "Read chapter 4"
jac run cli -- add "Problem set 3" --due 2026-10-06 --priority high --time "<30min" --category "EECS 449"
# --time is one of <30min, 1hr, 2hr, 3+hr (quote <30min so the shell doesn't redirect)
jac run cli -- list            # numbered, by due date
jac run cli -- done 2          # mark task 2 from `list` complete
jac run cli -- done 2 --undo   # mark it not done again
jac run cli -- --help
```

Everything after `--` goes to the planner CLI. By default it connects to
`http://localhost:8001`. To use a different server, set
`JAC_APP_PLANNER_URL`.

Exit codes: `0` ok, `2` bad input, `3` server not reachable, `4` timeout,
`1` other failure.

### Mobile app

The mobile app is a React Native app (Expo) written with Jac's `@jac/mobui`
components. It is a frontend only: it talks to the planner server, and its dev
mode starts that server for you.

**Mobile preview in a browser** (no phone tools needed):

```bash
# stop `jac run` first: the web app and the mobile preview can't run at the same time
jac build mobile --platform web      # once, on a fresh checkout
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
            │ mark_complete, delete_task    │
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
  format, levels).
- `web/`, `mobile/` and `cli/` each simply `import from core.planner { add_task, ... }`.
  Jac compiles those imports into typed, awaited network calls to the
  service, so none of the three reimplements the planning logic.
- There's no login, so every client uses the same shared graph. That is
  what makes one task list show up everywhere.
- `jac run` loads the planner service into the web server's process. The same
  code could run as a separate service without changes.

| Path | What it is |
|---|---|
| `jac.toml` | Declares the four apps: `web` (default), `planner`, `mobile`, `cli` |
| `core/planner.jac` | Server: `Task` node, `add_task`, `list_tasks`, `mark_complete`, `delete_task` |
| `core/task_rules.jac` | Input validation and defaults |
| `web/` | Web app: `main.jac`, `PlannerPage.jac` (form and tabs), `TaskList.jac` (task rows, date helpers), `CalendarView.jac`, `CompletedView.jac`, `MosaicBackground.jac`, `styles.css` |
| `mobile/main.jac` | Mobile app screen |
| `cli/` | CLI: `main.jac` (arguments), `tasks.jac` (commands) |

## Tests

```bash
jac test       # validation rules, add_task, CLI argument parsing and output
jac check      # type-check every app
```
