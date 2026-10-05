"""Finished tasks, newest first, grouped by the week, month or year they were done."""

import from core.planner { Task }
import from .TaskList {
    TaskRow,
    done_day,
    local_iso,
    add_days,
    week_start,
    short_date,
    month_label
}

glob PERIODS: list[str] = ["week", "month", "year"];

"""Group key for `day`: the Monday of its week, YYYY-MM, or YYYY."""
def period_key(day: str, period: str) -> str {
    if period == "week" {
        return week_start(day);
    }
    return day[:7] if period == "month" else day[:4];
}

def period_label(key: str, period: str) -> str {
    if period == "week" {
        end = add_days(key, 6);
        text = short_date(key) + " – " + short_date(end);
        return text if end[:4] == local_iso(0)[:4] else text + ", " + end[:4];
    }
    return month_label(key + "-01") if period == "month" else key;
}

"""'This week' / 'Last week' / 'This month' / ... for recent groups, else ''."""
def period_badge(key: str, period: str) -> str {
    today = local_iso(0);
    if key == period_key(today, period) {
        return "This " + period;
    }
    if period == "week" and key == week_start(add_days(today, -7)) {
        return "Last week";
    }
    return "";
}

def:pub CompletedView(
    tasks: list[Task],
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None]
) -> JsxElement {
    has period: str = "week";

    finished = sorted(
        [t for t in tasks if t.status == "done"],
        key=lambda (t: Task) { done_day(t) + t.completed_at; },
        reverse=True
    );
    groups: list[dict[str, any]] = [];
    for t in finished {
        k = period_key(done_day(t), period);
        if len(groups) == 0 or groups[len(groups) - 1]["key"] != k {
            groups.append({"key": k, "tasks": []});
        }
        groups[len(groups) - 1]["tasks"].append(t);
    }
    today = local_iso(0);
    stats: list[dict[str, str]] = [
        {
            "period": p,
            "count": str(
                len([t for t in finished if period_key(done_day(t), p) == period_key(today, p)])
            )
        } for p in PERIODS
    ];

    <section className="completed">
        <div className="stats">
            {[
                <div key={s["period"]} className="stat">
                    <span className="stat-num">{s["count"]}</span>
                    <span className="stat-label">{"this " + s["period"]}</span>
                </div> for s in stats
            ]}
        </div>
        <div className="segmented" role="group" aria-label="Group completed tasks by">
            {[
                <button
                    key={p}
                    type="button"
                    className={"seg" + (" active" if p == period else "")}
                    aria-pressed={p == period}
                    onClick={lambda { period = p; }}
                >
                    {"By " + p}
                </button> for p in PERIODS
            ]}
        </div>
        {(<p className="empty">
            Nothing completed yet. Tick off a task and it will show up here.
        </p>) if len(finished) == 0 else (
            <div className="days">
                {[
                    <section key={g["key"]} className="day">
                        <h3 className="day-heading">
                            <span>{period_label(g["key"], period)}</span>
                            {(<span className="badge badge-today">
                                {period_badge(g["key"], period)}
                            </span>) if period_badge(g["key"], period) else ""}
                            <span className="group-count">
                                {str(len(g["tasks"])) + " done"}
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
                                /> for t in g["tasks"]
                            ]}
                        </ul>
                    </section> for g in groups
                ]}
            </div>
        )}
    </section>
}
