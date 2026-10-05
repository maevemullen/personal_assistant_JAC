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
