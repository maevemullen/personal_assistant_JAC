import os;
import sys;
import from core.planner { TaskView, add_task, list_task_views, mark_complete }
import from jaclang.server.bridge {
    BridgeError,
    BridgeRejected,
    BridgeTimeout,
    BridgeUnavailable
}

glob EXIT_OK: int = 0,
     EXIT_FAILURE: int = 1,
     EXIT_USAGE: int = 2,
     EXIT_UNAVAILABLE: int = 3,
     EXIT_TIMEOUT: int = 4,
     EXIT_REJECTED: int = 5;

glob DEFAULT_SERVER: str = "http://localhost:8001",
     DEFAULT_ROUTE: str = "/api/planner",
     START_HINT: str = "hint: start the server first with `jac run` (in another terminal)";

obj TaskLine {
    has title: str = "",
        due: str = "",
        priority: str = "medium",
        duration: str = "1hr",
        category: str = "",
        status: str = "todo";
}

def warn(text: str) {
    print(text, file=sys.stderr);
}

def use_default_server {
    if not os.environ.get("JAC_APP_PLANNER_URL") {
        os.environ["JAC_APP_PLANNER_URL"] = DEFAULT_SERVER;
    }
    if not os.environ.get("JAC_APP_PLANNER_ROUTE") {
        os.environ["JAC_APP_PLANNER_ROUTE"] = DEFAULT_ROUTE;
    }
}

def render_line(line: TaskLine) -> str {
    mark = "[x]" if line.status == "done" else "[ ]";
    meta = line.due + " · " + line.priority + " priority · " + line.duration;
    if line.category {
        meta = meta + " · " + line.category;
    }
    return mark + " " + line.title + "\n      " + meta;
}

def to_line(t: TaskView) -> TaskLine {
    return TaskLine(
        title=t.title,
        due=t.due,
        priority=t.priority,
        duration=t.duration,
        category=t.category,
        status=t.status
    );
}

"""Prefix a rendered task with its 1-based number from `list`."""
def numbered(n: int, text: str) -> str {
    return (str(n) + ".").ljust(4) + text.replace("\n", "\n    ");
}

def explain_bridge_error(e: BridgeError) -> int {
    detail = " (" + e.detail + ")" if e.detail else "";
    if isinstance(e, BridgeUnavailable) {
        warn("planner: the server is not reachable" + detail);
        warn(START_HINT);
        return EXIT_UNAVAILABLE;
    }
    if isinstance(e, BridgeTimeout) {
        warn("planner: the server timed out" + detail);
        return EXIT_TIMEOUT;
    }
    if isinstance(e, BridgeRejected) {
        warn("planner: the server rejected the call" + detail);
        return EXIT_REJECTED;
    }
    warn("planner: the call failed" + detail);
    return EXIT_FAILURE;
}

async def run_add(
    title: str, due: str, priority: str, duration: str, category: str
) -> int {
    use_default_server();
    try {
        res = await add_task(title, due, priority, duration, category);
        task = res.task;
        if not res.ok or task is None {
            warn("planner add: " + (res.error or "the task was not saved"));
            return EXIT_USAGE;
        }
        print("added:");
        print(
            render_line(
                TaskLine(
                    title=task.title,
                    due=task.due,
                    priority=task.priority,
                    duration=task.duration,
                    category=task.category,
                    status=task.status
                )
            )
        );
        return EXIT_OK;
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
}

async def run_list -> int {
    use_default_server();
    try {
        tasks = await list_task_views();
        if not tasks {
            print("no tasks yet; add one: jac run cli -- add \"Read chapter 4\"");
            return EXIT_OK;
        }
        for (i, t) in enumerate(tasks) {
            print(numbered(i + 1, render_line(to_line(t))));
        }
        return EXIT_OK;
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
}

"""Mark the task numbered `number` in `list` output as done (or todo with done=False)."""
async def run_done(number: int, done: bool) -> int {
    use_default_server();
    try {
        tasks = await list_task_views();
        if number < 1 or number > len(tasks) {
            warn(
                "planner done: no task number " + str(number)
                + "; run `list` to see the numbers"
            );
            return EXIT_USAGE;
        }
        task = tasks[number - 1];
        if not await mark_complete(task.id, done) {
            warn("planner done: that task no longer exists");
            return EXIT_FAILURE;
        }
        task.status = "done" if done else "todo";
        print("completed:" if done else "reopened:");
        print(render_line(to_line(task)));
        return EXIT_OK;
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
}
