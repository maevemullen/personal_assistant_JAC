import io;
import from contextlib { redirect_stderr }

test "a task renders as a checkbox line plus details" {
    text = render_line(
        TaskLine(
            title="Lab 2", due="2026-10-06", priority="high", duration="<30 min", category="EECS 449"
        )
    );
    assert text == "[ ] Lab 2\n      2026-10-06 · high priority · <30 min · EECS 449";
    assert render_line(TaskLine(title="Done", due="2026-10-01", status="done")).startswith(
        "[x] Done"
    );
}

test "an unreachable server explains how to start it" {
    buf = io.StringIO();
    with redirect_stderr(buf) {
        code = explain_bridge_error(
            BridgeUnavailable(app="planner", name="add_task", detail="connection refused")
        );
    }
    assert code == EXIT_UNAVAILABLE;
    assert START_HINT in buf.getvalue();
}

test "list lines are numbered so `done N` can refer to them" {
    assert numbered(3, "[ ] Lab 2\n      x") == "3.  [ ] Lab 2\n          x";
}

test "a refused connection reported as a plain failure still says start the server" {
    buf = io.StringIO();
    with redirect_stderr(buf) {
        code = explain_bridge_error(
            BridgeError(
                app="planner",
                name="list_task_views",
                detail="sv-to-sv RPC 'planner.list_task_views' failed after 3 attempts: "
                    + "localhost:8999: [Errno 61] Connect call failed ('127.0.0.1', 8999)"
            )
        );
    }
    assert code == EXIT_UNAVAILABLE;
    assert START_HINT in buf.getvalue();
}

test "numbering ignores done, so completing a task never renumbers the list" {
    a = TaskView(id="a", title="A", due="2026-10-06", priority="low", created_at="1");
    b = TaskView(id="b", title="B", due="2026-10-06", priority="high", status="done", created_at="2");
    c = TaskView(id="c", title="C", due="2026-10-06", priority="medium", created_at="3");
    d = TaskView(id="d", title="D", due="2026-10-05", priority="low", created_at="4");
    assert [t.id for t in cli_order([a, b, c, d])] == ["d", "b", "c", "a"];
    b.status = "todo";
    assert [t.id for t in cli_order([c, a, d, b])] == ["d", "b", "c", "a"];
}
