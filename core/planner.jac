import from core.task_rules { check_task_input, match_category, now_stamp }

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

"""All tasks by due date; on the same day, open tasks come before done ones."""
def:pub list_tasks -> list[Task] {
    tasks = [root-->][?:Task];
    tasks.sort(
        key=lambda (t: Task) { (t.due, t.status == "done", t.created_at); }
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
