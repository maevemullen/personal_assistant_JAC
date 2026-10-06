"""Month calendar: tasks on their due dates; pick a day to see and check off its tasks."""

import from core.planner { Task }
import from .TaskList {
    DayGroup,
    EmptyState,
    iso_of,
    parse_day,
    local_iso,
    add_days,
    week_start,
    month_label,
    pretty_date
}

glob WEEKDAYS: list[str] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
glob MAX_CHIPS: int = 3;

"""First day of the month `n` months away from the month containing `iso`."""
def shift_month(iso: str, n: int) -> str {
    d = parse_day(iso);
    return iso_of(new(Date, d.getFullYear(), d.getMonth() + n, 1));
}

"""Every day shown on the grid: whole Monday-to-Sunday weeks covering the month."""
def grid_days(month: str) -> list[str] {
    last = add_days(shift_month(month, 1), -1);
    days: list[str] = [];
    day = week_start(month);
    while day <= last or len(days) % 7 != 0 {
        days.append(day);
        day = add_days(day, 1);
    }
    return days;
}

def tasks_by_day(tasks: list[Task]) -> dict[str, list[Task]] {
    out: dict[str, list[Task]] = {};
    for t in tasks {
        if t.due not in out {
            out[t.due] = [];
        }
        out[t.due].append(t);
    }
    return out;
}

def:pub DayCell(
    day: str,
    tasks: list[Task],
    inMonth: bool,
    selected: bool,
    onPick: Callable[[str], None]
) -> JsxElement {
    open_count = len([t for t in tasks if t.status != "done"]);
    late = open_count > 0 and day < local_iso(0);
    classes = "cal-cell" + ("" if inMonth else " outside") + (" overdue" if late else "") + (
        " today" if day == local_iso(0) else ""
    ) + (" selected" if selected else "");
    label = pretty_date(day) + (
        (", " + str(len(tasks)) + (" task" if len(tasks) == 1 else " tasks")) if len(tasks) > 0 else ""
    ) + (", overdue" if late else "");
    <button
        type="button"
        className={classes}
        aria-label={label}
        aria-pressed={selected}
        onClick={lambda { onPick(day); }}
    >
        <span className="cal-date">{str(int(parse_day(day).getDate()))}</span>
        {(<span className={"cal-dot" + (" all-done" if open_count == 0 else "")}>
            {str(len(tasks))}
        </span>) if len(tasks) > 0 else ""}
        <span className="cal-chips">
            {[
                <span
                    key={jid(t)}
                    className={"cal-chip prio-" + t.priority + (
                        " done" if t.status == "done" else ""
                    )}
                >
                    {t.title}
                </span> for t in tasks[:MAX_CHIPS]
            ]}
            {(<span className="cal-more">{"+" + str(len(tasks) - MAX_CHIPS) + " more"}</span>)
                if len(tasks) > MAX_CHIPS else ""}
        </span>
    </button>
}

def:pub CalendarView(
    tasks: list[Task],
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None],
    onEdit: Callable[[Task], None]
) -> JsxElement {
    has month: str = shift_month(local_iso(0), 0),
        selected: str = local_iso(0);

    by_day = tasks_by_day(tasks);
    month_prefix = month[:7];
    picked = by_day[selected] if selected in by_day else [];

    def go_today {
        month = shift_month(local_iso(0), 0);
        selected = local_iso(0);
    }

    <section className="calendar">
        <div className="cal-toolbar">
            <button
                type="button"
                className="ghost"
                aria-label="Previous month"
                onClick={lambda { month = shift_month(month, -1); }}
            >
                {"‹"}
            </button>
            <h3 className="cal-title">{month_label(month)}</h3>
            <button
                type="button"
                className="ghost"
                aria-label="Next month"
                onClick={lambda { month = shift_month(month, 1); }}
            >
                {"›"}
            </button>
            <button type="button" className="ghost today-btn" onClick={go_today}>
                Today
            </button>
        </div>
        <div className="cal-grid">
            {[<div key={w} className="cal-weekday">{w}</div> for w in WEEKDAYS]}
            {[
                <DayCell
                    key={d}
                    day={d}
                    tasks={by_day[d] if d in by_day else []}
                    inMonth={d[:7] == month_prefix}
                    selected={d == selected}
                    onPick={lambda (v: str) { selected = v; }}
                /> for d in grid_days(month)
            ]}
        </div>
        <div className="cal-detail">
            {(<DayGroup
                due={selected}
                tasks={picked}
                busyId={busyId}
                onToggle={onToggle}
                onDelete={onDelete}
                onEdit={onEdit}
            />) if len(picked) > 0 else (
                <EmptyState
                    title="Nothing due."
                    note={pretty_date(selected) + " is clear. Pick another day, or add a task above."}
                />
            )}
        </div>
    </section>
}
