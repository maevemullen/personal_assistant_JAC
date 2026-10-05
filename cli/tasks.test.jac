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
