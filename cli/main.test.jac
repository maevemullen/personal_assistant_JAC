test "add takes a title and optional fields" {
    inv = parse_args(["add", "Lab 2", "--due", "2026-10-06", "--priority", "high"]);
    assert inv.command == "add";
    assert inv.title == "Lab 2";
    assert inv.due == "2026-10-06";
    assert inv.priority == "high";
    assert inv.duration == "";
    assert inv.category == "";
}

test "list needs no arguments" {
    assert parse_args(["list"]).command == "list";
}

test "done takes a task number and an optional --undo" {
    inv = parse_args(["done", "2"]);
    assert inv.command == "done";
    assert inv.number == 2;
    assert not inv.undo;
    assert parse_args(["done", "1", "--undo"]).undo;
}

test "--time takes one of the four sizes" {
    assert parse_args(["add", "Lab", "--time", "<30min"]).duration == "<30min";
    assert parse_args(["add", "Lab", "--time", "3+hr"]).duration == "3+hr";
}
