test "add_task stores a task on the graph" {
    before = len(list_tasks());
    res = add_task("Problem set 3", due="2026-10-07", priority="high");
    assert res.ok;
    task = res.task;
    assert task is not None;
    assert task.title == "Problem set 3";
    assert task.status == "todo";
    assert len(list_tasks()) == before + 1;
    assert not add_task("").ok;
    assert len(list_tasks()) == before + 1;
}

test "mark_complete toggles a task and sorts done tasks last for the day" {
    a = add_task("Early", due="2030-01-01").task;
    b = add_task("Late", due="2030-01-01").task;
    assert a is not None and b is not None;
    assert mark_complete(jid(a));
    assert a.status == "done";
    assert len(a.completed_at) >= 10;
    same_day = [t.title for t in list_tasks() if t.due == "2030-01-01"];
    assert same_day == ["Late", "Early"];
    assert mark_complete(jid(a), done=False);
    assert a.status == "todo";
    assert a.completed_at == "";
    assert not mark_complete("no-such-id");
    views = list_task_views();
    assert [v.id for v in views] == [jid(t) for t in list_tasks()];
}

test "list_tasks puts higher priority first within a day, done tasks last" {
    low = add_task("Low", due="2030-04-01", priority="low").task;
    add_task("High", due="2030-04-01", priority="high");
    add_task("Medium", due="2030-04-01", priority="medium");
    finished = add_task("Done high", due="2030-04-01", priority="high").task;
    add_task("Tomorrow high", due="2030-04-02", priority="high");
    assert low is not None and finished is not None;
    assert mark_complete(jid(finished));
    titles = [t.title for t in list_tasks() if t.due in ["2030-04-01", "2030-04-02"]];
    assert titles == ["High", "Medium", "Low", "Done high", "Tomorrow high"];
}

test "delete_task removes exactly that task" {
    keep = add_task("Keep me", due="2030-02-01").task;
    gone = add_task("Delete me", due="2030-02-01").task;
    assert keep is not None and gone is not None;
    gone_id = jid(gone);
    before = len(list_tasks());
    assert delete_task(gone_id);
    assert len(list_tasks()) == before - 1;
    assert gone_id not in [jid(t) for t in list_tasks()];
    assert jid(keep) in [jid(t) for t in list_tasks()];
    assert not delete_task(gone_id);
}

test "a new task reuses the spelling of an existing category" {
    add_task("First", due="2030-03-01", category="Quantum Mechanics");
    second = add_task("Second", due="2030-03-01", category="quantum  mechanics", duration="2hr").task;
    assert second is not None;
    assert second.category == "Quantum Mechanics";
    assert second.duration == "2hr";
    assert not add_task("Bad", duration="forever").ok;
}

test "edit_task updates fields and keeps the completion time consistent" {
    task = add_task("Draft essay", due="2030-04-01", category="Writing").task;
    assert task is not None;
    tid = jid(task);
    res = edit_task(tid, "Final essay", "2030-04-03", "high", "2hr", "writing", "doing");
    assert res.ok;
    assert task.title == "Final essay";
    assert task.due == "2030-04-03";
    assert task.priority == "high";
    assert task.duration == "2hr";
    assert task.category == "writing";
    assert task.status == "doing";
    assert task.completed_at == "";
    assert edit_task(tid, "Final essay", "2030-04-03", "high", "2hr", "", "done").ok;
    assert len(task.completed_at) >= 10;
    assert edit_task(tid, "Final essay", "2030-04-03", "high", "2hr", "", "todo").ok;
    assert task.completed_at == "";
    assert not edit_task(tid, "", "2030-04-03", "high", "2hr", "", "todo").ok;
    assert not edit_task(tid, "Final essay", "2030-04-03", "high", "2hr", "", "someday").ok;
    assert task.title == "Final essay";
    assert not edit_task("no-such-id", "X", "2030-04-03", "low", "1hr", "", "todo").ok;
}

"""Add a task already finished on `day` (completion times are normally "now")."""
def finished(title: str, day: str, priority: str = "medium", duration: str = "1hr", category: str = "") -> Task {
    t = add_task(title, due=day, priority=priority, duration=duration, category=category).task;
    assert t is not None;
    mark_complete(jid(t));
    t.completed_at = day + "T12:00:00";
    return t;
}

test "progress_report totals the week, compares weeks and finds the frog" {
    # Week of Mon 2031-03-03; "today" is Wed 2031-03-05.
    finished("Last week A", "2031-02-25");
    finished("This Mon", "2031-03-03", priority="high", duration="2hr", category="EECS 449");
    finished("This Tue", "2031-03-04", duration="<30 min", category="eecs 449");
    late = finished("This Wed", "2031-03-05", category="Reading");
    late.due = "2031-03-04";
    frog = add_task("Old high", due="2031-03-09", priority="high").task;
    assert frog is not None;
    frog.created_at = "2031-02-20T09:00:00";
    add_task("Quick today", due="2031-03-05", duration="<30 min");

    r = progress_report("2031-03-05");
    assert r.week_start == "2031-03-03";
    assert r.done_count == 3;
    assert r.hours == 3.5;
    assert [d.count for d in r.days] == [1, 1, 1, 0, 0, 0, 0];
    assert r.last_week_count == 1;
    assert r.streak == 3;
    assert r.on_time_count == 2;
    assert r.high_done == 1;
    assert r.quick_done == 1;
    assert r.is_record;
    assert [c.name for c in r.categories] == ["EECS 449", "Reading"];
    assert r.categories[0].hours == 2.5;
    assert [t.title for t in r.completed] == ["This Wed", "This Tue", "This Mon"];
    assert [t.title for t in r.quick_start] == ["Quick today"];
    assert r.frog is not None and r.frog.title == "Old high";
    assert r.frog_age == 13;
    assert "3 tasks" in r.recap and "2 more than last week" in r.recap;
}

test "an empty week gets an encouraging recap" {
    r = progress_report("2040-06-06");
    assert r.done_count == 0;
    assert r.recap.startswith("A fresh week");
}
