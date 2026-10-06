"""The Progress tab: a weekly report built from the server's progress_report."""

import from core.planner { Task, ProgressReport, DayTally, CategoryTally }
import from .TaskList { TaskRow, EmptyState, parse_day, short_date, add_days }

"""Hours to one decimal, without a trailing .0."""
def fmt_hours(h: float) -> str {
    return str(Math.round(h * 10) / 10);
}

"""The largest of `values`, but at least `floor` (so empty weeks don't divide by 0)."""
def peak_of(values: list[float], floor: float) -> float {
    top = floor;
    for v in values {
        if v > top {
            top = v;
        }
    }
    return top;
}

def weekday(day: str) -> str {
    return parse_day(day).toLocaleDateString("en-US", {"weekday": "short"});
}

"""'1 hr' / '2.5 hrs'."""
def hrs(h: float) -> str {
    return fmt_hours(h) + (" hr" if Math.round(h * 10) == 10 else " hrs");
}

"""'▲ 2 on last week' / '▼ 1 on last week' / 'same as last week'."""
def delta_note(now: float, before: float, hours: bool) -> str {
    gap = Math.round((now - before) * 10) / 10;
    if gap == 0 {
        return "same as last week";
    }
    size = hrs(Math.abs(gap)) if hours else str(Math.abs(gap));
    return ("▲ " if gap > 0 else "▼ ") + size + " on last week";
}

def StatCard(value: str, label: str, note: str) -> JsxElement {
    <div className="stat">
        <span className="stat-num">{value}</span>
        <span className="stat-label">{label}</span>
        {(<span className="stat-note">{note}</span>) if note else ""}
    </div>
}

"""Mon-Sun bars sized by hours of work, with the task count on top."""
def WeekChart(days: list[DayTally], today: str) -> JsxElement {
    peak = peak_of([d.hours for d in days], 1.0);
    summary = "Tasks done each day:";
    for d in days {
        summary += " " + weekday(d.day) + " " + str(d.count) + ";";
    }
    <div className="week-chart" role="img" aria-label={summary}>
        {[
            <div key={d.day} className={"week-col" + (" is-today" if d.day == today else "") + (
                " is-future" if d.day > today else ""
            )}>
                <span className="week-count">{str(d.count) if d.count else ""}</span>
                <span className="week-track">
                    <span
                        className="week-bar"
                        style={{"height": str(peak_of([d.hours / peak * 100], 4.0 if d.count else 0.0)) + "%"}}
                    />
                </span>
                <span className="week-day">{weekday(d.day)}</span>
            </div> for d in days
        ]}
    </div>
}

def CategoryBars(cats: list[CategoryTally]) -> JsxElement {
    peak = peak_of([c.hours for c in cats], 0.5);
    <ul className="cat-bars">
        {[
            <li key={c.name} className="cat-row">
                <span className="cat-name">{c.name}</span>
                <span className="cat-track">
                    <span className="cat-bar" style={{"width": str(c.hours / peak * 100) + "%"}} />
                </span>
                <span className="cat-hours">{hrs(c.hours)}</span>
            </li> for c in cats
        ]}
    </ul>
}

def:pub ProgressView(
    weekly: ProgressReport,
    busyId: str,
    onToggle: Callable[[Task], None],
    onDelete: Callable[[Task], None],
    onEdit: Callable[[Task], None]
) -> JsxElement {
    r = weekly;
    on_time = (
        str(Math.round(r.on_time_count / r.done_count * 100)) + "%"
    ) if r.done_count else "—";

    def rows(tasks: list[Task], showDue: bool) -> list[JsxElement] {
        return [
            <TaskRow
                key={jid(t)}
                task={t}
                busy={busyId == jid(t)}
                onToggle={onToggle}
                onDelete={onDelete}
                onEdit={onEdit}
                showDue={showDue}
            /> for t in tasks
        ];
    }

    <section className="progress">
        <header className="progress-head">
            <p className="kicker">
                {"Week of " + short_date(r.week_start) + " – " + short_date(add_days(r.week_start, 6))}
            </p>
            <h2 className="progress-title">The Week in Review</h2>
        </header>

        <p className="lede">{r.recap}</p>

        {(<div className="record" role="status">
            <span className="empty-mark" aria-hidden="true">❦</span>
            <span>
                <strong>Best week yet.</strong>
                {" " + str(r.done_count) + " tasks done, a new personal record."}
            </span>
        </div>) if r.is_record else ""}

        <div className="stats stats-4">
            <StatCard
                value={str(r.done_count)}
                label="tasks done"
                note={delta_note(r.done_count, r.last_week_count, False)}
            />
            <StatCard
                value={fmt_hours(r.hours)}
                label={"hour of work" if Math.round(r.hours * 10) == 10 else "hours of work"}
                note={delta_note(r.hours, r.last_week_hours, True)}
            />
            <StatCard
                value={str(r.streak)}
                label="day streak"
                note={"best: " + str(r.best_streak) + (" day" if r.best_streak == 1 else " days")}
            />
            <StatCard
                value={on_time}
                label="on time"
                note={(str(r.on_time_count) + " of " + str(r.done_count)) if r.done_count else "nothing due yet"}
            />
        </div>

        <div className="box-score">
            <div><span className="box-num">{str(r.high_done)}</span> high-priority done</div>
            <div>
                <span className="box-num">{str(r.quick_done)}</span>
                {" quick win" + ("" if r.quick_done == 1 else "s") + " cleared"}
            </div>
            <div>
                {"best week: "}
                <span className="box-num">{str(r.best_week_count)}</span>
                {" (this one!)" if r.is_record else ""}
            </div>
        </div>

        <section className="day">
            <h3 className="day-heading">Day by day</h3>
            <WeekChart days={r.days} today={r.today} />
        </section>

        <section className="day">
            <h3 className="day-heading">Where your time went</h3>
            {(<CategoryBars cats={r.categories} />) if len(r.categories) else (
                <p className="aside">Finish a task this week to see where the hours go.</p>
            )}
        </section>

        <section className="day">
            <h3 className="day-heading">
                <span>Today’s quick start</span>
                <span className="group-count">under 30 min each</span>
            </h3>
            {(<ul className="tasks">{rows(r.quick_start, False)}</ul>) if len(r.quick_start) else (
                <p className="aside">{"No quick tasks due today. Add one marked “<30 min” to warm up."}</p>
            )}
        </section>

        {(<section className="day frog">
            <h3 className="day-heading">
                <span>Eat the frog</span>
                <span className="group-count">
                    {"added today" if r.frog_age == 0 else (
                        "open " + str(r.frog_age) + (" day" if r.frog_age == 1 else " days")
                    )}
                </span>
            </h3>
            <p className="aside">
                Your oldest high-priority task. Give it fifteen minutes first thing and the rest of the day gets easier.
            </p>
            <ul className="tasks">{rows([r.frog], True)}</ul>
        </section>) if r.frog else ""}

        <section className="day">
            <h3 className="day-heading">
                <span>Done this week</span>
                <span className="group-count">
                    {str(r.done_count) + (" task" if r.done_count == 1 else " tasks")}
                </span>
            </h3>
            {(<ul className="tasks">{rows(r.completed, True)}</ul>) if len(r.completed) else (
                <EmptyState
                    title="Nothing finished yet."
                    note="Tick off a task and it will be counted here."
                />
            )}
        </section>
    </section>
}
