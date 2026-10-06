import from core.task_rules {
    LEVELS,
    STATUSES,
    check_task_input,
    match_category,
    now_stamp
}
import from core.progress_rules {
    hours_for,
    shift,
    monday_of,
    days_between,
    week_days,
    streaks,
    plural,
    hrs
}

node Task {
    has title: str,
        due: str,
        priority: str = "medium",
        duration: str = "1hr",
        category: str = "",
        status: str = "todo",
        created_at: str = "",
        completed_at: str = "";
}

obj AddResult {
    has ok: bool = False,
        error: str = "",
        task: Task | None = None;
}

"""A task as plain data with its id, for apps that cannot hold graph nodes (the CLI)."""
obj TaskView {
    has id: str = "",
        title: str = "",
        due: str = "",
        priority: str = "medium",
        duration: str = "1hr",
        category: str = "",
        status: str = "todo",
        created_at: str = "",
        completed_at: str = "";
}

def:pub add_task(
    title: str,
    due: str = "",
    priority: str = "medium",
    duration: str = "",
    category: str = ""
) -> AddResult {
    check = check_task_input(title, due, priority, duration, category);
    if not check.ok {
        return AddResult(error=check.error);
    }
    task = Task(
        title=check.title,
        due=check.due,
        priority=check.priority,
        duration=check.duration,
        category=match_category(
            check.category, [t.category for t in [root-->][?:Task] if t.category]
        ),
        created_at=now_stamp()
    );
    root ++> task;
    return AddResult(ok=True, task=task);
}

"""All tasks by due date. On the same day, open tasks come before done ones,
then higher priority before lower, then oldest first."""
def:pub list_tasks -> list[Task] {
    tasks = [root-->][?:Task];
    tasks.sort(
        key=lambda (t: Task) {
            (
                t.due,
                t.status == "done",
                -(LEVELS.index(t.priority) if t.priority in LEVELS else 0),
                t.created_at
            );
        }
    );
    return tasks;
}

"""Same order as list_tasks, as TaskView data."""
def:pub list_task_views -> list[TaskView] {
    return [
        TaskView(
            id=jid(t),
            title=t.title,
            due=t.due,
            priority=t.priority,
            duration=t.duration,
            category=t.category,
            status=t.status,
            created_at=t.created_at,
            completed_at=t.completed_at
        ) for t in list_tasks()
    ];
}

"""Mark a task done (or back to todo with done=False), stamping when it was
finished. False if no such task."""
def:pub mark_complete(task_id: str, done: bool = True) -> bool {
    for t in [root-->][?:Task] {
        if jid(t) == task_id {
            t.status = "done" if done else "todo";
            t.completed_at = now_stamp() if done else "";
            return True;
        }
    }
    return False;
}

"""Replace every editable field of a task, with the same checks as add_task.
Moving into or out of "done" sets or clears the completion time."""
def:pub edit_task(
    task_id: str,
    title: str,
    due: str,
    priority: str,
    duration: str,
    category: str,
    status: str
) -> AddResult {
    check = check_task_input(title, due, priority, duration, category);
    if not check.ok {
        return AddResult(error=check.error);
    }
    status = status.strip().lower();
    if status not in STATUSES {
        return AddResult(error="status must be one of: " + ", ".join(STATUSES));
    }
    for t in [root-->][?:Task] {
        if jid(t) == task_id {
            others = [o.category for o in [root-->][?:Task] if o.category and jid(o) != task_id];
            if status == "done" and t.status != "done" {
                t.completed_at = now_stamp();
            } elif status != "done" {
                t.completed_at = "";
            }
            t.title = check.title;
            t.due = check.due;
            t.priority = check.priority;
            t.duration = check.duration;
            t.category = match_category(check.category, others);
            t.status = status;
            return AddResult(ok=True, task=t);
        }
    }
    return AddResult(error="that task no longer exists");
}

"""Permanently remove a task. False if no such task."""
def:pub delete_task(task_id: str) -> bool {
    for t in [root-->][?:Task] {
        if jid(t) == task_id {
            del t;
            return True;
        }
    }
    return False;
}

"""Work finished on one day of the week."""
obj DayTally {
    has day: str = "",
        count: int = 0,
        hours: float = 0.0;
}

"""Work finished in one category this week."""
obj CategoryTally {
    has name: str = "",
        count: int = 0,
        hours: float = 0.0;
}

"""Everything the Progress dashboard shows, for the week containing `today`.
Hours are rough totals of the tasks' time estimates."""
obj ProgressReport {
    has today: str = "",
        week_start: str = "",
        days: list[DayTally] = [],
        done_count: int = 0,
        hours: float = 0.0,
        last_week_count: int = 0,
        last_week_hours: float = 0.0,
        streak: int = 0,
        best_streak: int = 0,
        best_week_count: int = 0,
        is_record: bool = False,
        on_time_count: int = 0,
        high_done: int = 0,
        quick_done: int = 0,
        categories: list[CategoryTally] = [],
        completed: list[Task] = [],
        quick_start: list[Task] = [],
        frog: Task | None = None,
        frog_age: int = 0,
        recap: str = "";
}

"""The day a done task counts as finished (its due date if it has no timestamp)."""
def finished_on(t: Task) -> str {
    return t.completed_at[:10] if t.completed_at else t.due;
}

"""A few encouraging sentences built from the numbers."""
def write_recap(r: ProgressReport) -> str {
    if r.done_count == 0 {
        if r.streak > 0 {
            return "Nothing ticked off yet this week, but your " + plural(r.streak, "day")
                + " streak is still alive. One quick task keeps it going.";
        }
        return "A fresh week. Finish one task today and a new streak starts here.";
    }
    text = "You finished " + plural(r.done_count, "task") + " this week, about "
        + hrs(r.hours) + " of work";
    gap = r.done_count - r.last_week_count;
    if r.last_week_count > 0 and gap > 0 {
        text += ", " + str(gap) + " more than last week";
    } elif r.last_week_count > 0 and gap == 0 {
        text += ", matching last week";
    } elif gap < 0 {
        text += ". " + plural(-gap, "more task") + " and you'll match last week";
    }
    text += ". ";
    if r.on_time_count == r.done_count {
        text += ("On time, too. " if r.done_count == 1 else "Every one of them on time. ");
    } elif r.on_time_count > 0 {
        text += str(r.on_time_count) + " of " + str(r.done_count) + " on time. ";
    }
    if r.high_done > 0 {
        text += "You took on " + plural(r.high_done, "high-priority task") + ". ";
    }
    if r.streak >= 2 {
        text += "That's a " + str(r.streak) + "-day streak. ";
    }
    if r.is_record {
        text += "Best week yet.";
    }
    return text.strip();
}

"""The weekly progress report. `today` is the caller's local date (YYYY-MM-DD)."""
def:pub progress_report(today: str) -> ProgressReport {
    tasks = [root-->][?:Task];
    done = [t for t in tasks if t.status == "done"];
    monday = monday_of(today);
    last_monday = shift(monday, -7);
    r = ProgressReport(today=today, week_start=monday);

    # This week, day by day
    week = [t for t in done if monday_of(finished_on(t)) == monday];
    for d in week_days(monday) {
        on_day = [t for t in week if finished_on(t) == d];
        r.days.append(
            DayTally(day=d, count=len(on_day), hours=sum([hours_for(t.duration) for t in on_day]))
        );
    }
    r.done_count = len(week);
    r.hours = sum([hours_for(t.duration) for t in week]);
    r.on_time_count = len([t for t in week if finished_on(t) <= t.due]);
    r.high_done = len([t for t in week if t.priority == "high"]);
    r.quick_done = len([t for t in week if t.duration == "<30 min"]);
    r.completed = sorted(
        week, key=lambda (t: Task) { finished_on(t) + t.completed_at; }, reverse=True
    );

    # Last week, streaks and the best week before this one
    prev = [t for t in done if monday_of(finished_on(t)) == last_monday];
    r.last_week_count = len(prev);
    r.last_week_hours = sum([hours_for(t.duration) for t in prev]);
    (r.streak, r.best_streak) = streaks([finished_on(t) for t in done], today);
    per_week: dict[str, int] = {};
    for t in done {
        key = monday_of(finished_on(t));
        if key < monday {
            per_week[key] = per_week.get(key, 0) + 1;
        }
    }
    best_before = max(per_week.values()) if per_week else 0;
    r.best_week_count = max(best_before, r.done_count);
    r.is_record = best_before > 0 and r.done_count > best_before;

    # Where the time went
    by_cat: dict[str, CategoryTally] = {};
    for t in week {
        key = t.category.lower();
        if key not in by_cat {
            by_cat[key] = CategoryTally(name=t.category or "No category");
        }
        by_cat[key].count += 1;
        by_cat[key].hours += hours_for(t.duration);
    }
    r.categories = sorted(
        by_cat.values(), key=lambda (c: CategoryTally) { -c.hours; }
    );

    # Looking ahead: quick tasks due today, and the oldest high-priority task
    open_tasks = [t for t in tasks if t.status != "done"];
    r.quick_start = [t for t in open_tasks if t.due == today and t.duration == "<30 min"];
    frogs = sorted(
        [t for t in open_tasks if t.priority == "high"],
        key=lambda (t: Task) { (t.created_at or t.due, t.due); }
    );
    if frogs {
        r.frog = frogs[0];
        r.frog_age = max(0, days_between((r.frog.created_at or r.frog.due)[:10], today));
    }
    r.recap = write_recap(r);
    return r;
}
