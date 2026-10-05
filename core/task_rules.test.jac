test "a bare title gets today's date, medium priority and a 1hr estimate" {
    check = check_task_input("  Read   ch. 4 ", "", "", "", "");
    assert check.ok;
    assert check.title == "Read ch. 4";
    assert check.due == today_iso();
    assert check.priority == "medium";
    assert check.duration == "1hr";
    assert check.category == "";
}

test "explicit fields are normalised" {
    check = check_task_input("Lab 2", "2026-10-06", "HIGH", " < 30 Min ", " EECS  449 ");
    assert check.ok;
    assert check.due == "2026-10-06";
    assert check.priority == "high";
    assert check.duration == "<30 min";
    assert check.category == "EECS 449";
}

test "bad input is rejected with a message" {
    assert check_task_input("   ", "", "", "", "").error == "title is required";
    assert not check_task_input("x" * 121, "", "", "", "").ok;
    assert "YYYY-MM-DD" in check_task_input("Lab", "10/06/2026", "", "", "").error;
    assert "YYYY-MM-DD" in check_task_input("Lab", "2026-13-01", "", "", "").error;
    assert "priority" in check_task_input("Lab", "", "urgent", "", "").error;
    assert "time" in check_task_input("Lab", "", "", "huge", "").error;
}

test "time estimates accept the four sizes and common spellings" {
    for (given, want) in [
        ("<30 min", "<30 min"), ("<30min", "<30 min"), ("1hr", "1hr"), ("1 hr", "1hr"),
        ("2HR", "2hr"), ("3+hr", "3+hr"), ("3+", "3+hr"), ("", "1hr")
    ] {
        assert check_task_input("Lab", "", "", given, "").duration == want;
    }
}

test "a category matches an existing one ignoring case" {
    assert match_category("eecs 449", ["Math", "EECS 449"]) == "EECS 449";
    assert match_category("Art", ["Math"]) == "Art";
    assert match_category("", []) == "";
}
