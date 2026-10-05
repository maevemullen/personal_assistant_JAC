"""Task rows, day groups and date helpers shared by the list, calendar and
completed views. Dates travel as YYYY-MM-DD strings in the browser's local time."""

import from core.planner { Task }

def pad2(n: float) -> str {
    text = str(int(n));
    return ("0" + text) if len(text) < 2 else text;
}

def:pub iso_of(d: any) -> str {
    return str(int(d.getFullYear())) + "-" + pad2(d.getMonth() + 1) + "-" + pad2(
        d.getDate()
    );
}

"""Local midnight on an ISO day (a bare `new Date("2026-10-04")` would be UTC)."""
def:pub parse_day(iso: str) -> any {
    return new(Date, iso + "T00:00:00");
}

"""ISO date for today plus `offset` days."""
def:pub local_iso(offset: int) -> str {
    d = new(Date);
    d.setDate(d.getDate() + offset);
    return iso_of(d);
}

def:pub add_days(iso: str, days: int) -> str {
    d = parse_day(iso);
    d.setDate(d.getDate() + days);
    return iso_of(d);
}

"""Monday of the week containing `iso`."""
def:pub week_start(iso: str) -> str {
    d = parse_day(iso);
    return add_days(iso, -((d.getDay() + 6) % 7));
}

def format_day(iso: str, opts: dict[str, str]) -> str {
    return parse_day(iso).toLocaleDateString("en-US", opts);
}

def:pub pretty_date(iso: str) -> str {
    return format_day(iso, {"weekday": "long", "month": "short", "day": "numeric"});
}

def:pub short_date(iso: str) -> str {
    return format_day(iso, {"month": "short", "day": "numeric"});
}

def:pub month_label(iso: str) -> str {
    return format_day(iso, {"month": "long", "year": "numeric"});
}

"""The day a done task counts as finished: when it was completed, or its due
date for tasks completed before completion times were recorded."""
def:pub done_day(task: Task) -> str {
    return task.completed_at[:10] if task.completed_at else task.due;
}

"""True if every word of `query` appears in the task's title, category, priority,
time, due date or status (case-insensitive). A blank query matches everything."""
def:pub matches_query(task: Task, query: str) -> bool {
    text = " ".join(
        [
            task.title,
            task.category,
            task.priority + " priority",
            task.duration,
            task.due,
            "done" if task.status == "done" else "todo open"
        ]
    ).lower();
    for word in query.strip().lower().split(" ") {
        if word and word not in text {
            return False;
        }
    }
    return True;
}

def:pub filter_tasks(tasks: list[Task], query: str) -> list[Task] {
    return [t for t in tasks if matches_query(t, query)];
}

"""Distinct categories in use (case-insensitive), A to Z, for the category picker."""
def:pub category_names(tasks: list[Task]) -> list[str] {
    names: list[str] = [];
    lowers: list[str] = [];
    for t in tasks {
        if t.category and t.category.lower() not in lowers {
            lowers.append(t.category.lower());
            names.append(t.category);
        }
    }
    return sorted(names, key=lambda (c: str) { c.lower(); });
}

"""One group per category (matched ignoring case), A to Z with uncategorised last.
Tasks stay in the order given, so date-sorted input stays date-sorted per group."""
def:pub group_by_category(tasks: list[Task]) -> list[dict[str, any]] {
    groups: list[dict[str, any]] = [];
    index: dict[str, int] = {};
    for t in tasks {
        key = t.category.lower();
        if key not in index {
            index[key] = len(groups);
            groups.append({"key": key, "label": t.category, "tasks": []});
        }
        groups[index[key]]["tasks"].append(t);
    }
    return sorted(
        groups,
        key=lambda (g: dict[str, any]) { ("1" if g["key"] == "" else "0" + g["key"]); }
    );
}

"""Split date-sorted tasks into one group per due date, keeping order."""
def:pub group_by_day(tasks: list[Task]) -> list[dict[str, any]] {
    groups: list[dict[str, any]] = [];
    for t in tasks {
        if len(groups) == 0 or groups[len(groups) - 1]["due"] != t.due {
            groups.append({"due": t.due, "tasks": []});
        }
        groups[len(groups) - 1]["tasks"].append(t);
    }
    return groups;
}

def:pub TaskRow(
    task: Task,
    busy: bool,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None],
    showDue: bool = False
) -> JsxElement {
    has confirming: bool = False;

    done = task.status == "done";
    <li className={"task done" if done else "task"}>
        <button
            type="button"
            className="check"
            disabled={busy}
            aria-pressed={done}
            aria-label={("Mark not done: " if done else "Mark complete: ") + task.title}
            onClick={lambda { onToggle(task); }}
        >
            {"✓" if done else ""}
        </button>
        <div className="task-body">
            <span className="task-title">{task.title}</span>
            <span className="task-tags">
                {(<span className="tag done-on">{"done " + short_date(done_day(task))}</span>)
                    if done else ""}
                {(<span className="tag">{"due " + short_date(task.due)}</span>)
                    if showDue else ""}
                <span className={"tag prio-" + task.priority}>
                    {task.priority + " priority"}
                </span>
                <span className="tag">{task.duration}</span>
                {(<span className="tag category">{task.category}</span>)
                    if task.category else ""}
            </span>
        </div>
        {(<div className="confirm" role="group" aria-label={"Delete " + task.title + "?"}>
            <span className="confirm-text">Delete?</span>
            <button
                type="button"
                className="danger"
                disabled={busy}
                onClick={lambda { onDelete(task); }}
            >
                Delete
            </button>
            <button
                type="button"
                className="ghost"
                onClick={lambda { confirming = False; }}
            >
                Cancel
            </button>
        </div>) if confirming else (
            <button
                type="button"
                className="icon-btn"
                aria-label={"Delete task: " + task.title}
                title="Delete task"
                disabled={busy}
                onClick={lambda { confirming = True; }}
            >
                <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
                    <path
                        d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V4h6v3"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    />
                </svg>
            </button>
        )}
    </li>
}

def:pub DayGroup(
    due: str,
    tasks: list[Task],
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None]
) -> JsxElement {
    today = local_iso(0);
    has_open = len([t for t in tasks if t.status != "done"]) > 0;
    badge = "Today" if due == today else (
        "Tomorrow" if due == local_iso(1) else (
            "Overdue" if due < today and has_open else ""
        )
    );
    <section className="day">
        <h3 className="day-heading">
            <span>{pretty_date(due)}</span>
            {(<span className={"badge badge-" + badge.lower()}>{badge}</span>)
                if badge else ""}
        </h3>
        <ul className="tasks">
            {[
                <TaskRow
                    key={jid(t)}
                    task={t}
                    busy={busyId == jid(t)}
                    onToggle={onToggle}
                    onDelete={onDelete}
                /> for t in tasks
            ]}
        </ul>
    </section>
}

glob GROUPINGS: list[str] = ["date", "category"];

def:pub CategoryGroup(
    label: str,
    tasks: list[Task],
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None]
) -> JsxElement {
    <section className="day">
        <h3 className="day-heading">
            <span>{label if label else "No category"}</span>
            <span className="group-count">
                {str(len(tasks)) + (" task" if len(tasks) == 1 else " tasks")}
            </span>
        </h3>
        <ul className="tasks">
            {[
                <TaskRow
                    key={jid(t)}
                    task={t}
                    busy={busyId == jid(t)}
                    onToggle={onToggle}
                    onDelete={onDelete}
                    showDue={True}
                /> for t in tasks
            ]}
        </ul>
    </section>
}

"""The List tab: every task, grouped by due date or by category."""
def:pub ListView(
    tasks: list[Task],
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None]
) -> JsxElement {
    has grouping: str = "date";

    <section className="view-stack">
        <div className="segmented" role="group" aria-label="Group tasks by">
            {[
                <button
                    key={g}
                    type="button"
                    className={"seg" + (" active" if g == grouping else "")}
                    aria-pressed={g == grouping}
                    onClick={lambda { grouping = g; }}
                >
                    {"By " + g}
                </button> for g in GROUPINGS
            ]}
        </div>
        {(<p className="empty">No tasks yet.</p>) if len(tasks) == 0 else (
            (<div className="days">
                {[
                    <CategoryGroup
                        key={g["key"]}
                        label={g["label"]}
                        tasks={g["tasks"]}
                        busyId={busyId}
                        onToggle={onToggle}
                        onDelete={onDelete}
                    /> for g in group_by_category(tasks)
                ]}
            </div>) if grouping == "category" else (
                <div className="days">
                    {[
                        <DayGroup
                            key={g["due"]}
                            due={g["due"]}
                            tasks={g["tasks"]}
                            busyId={busyId}
                            onToggle={onToggle}
                            onDelete={onDelete}
                        /> for g in group_by_day(tasks)
                    ]}
                </div>
            )
        )}
    </section>
}
