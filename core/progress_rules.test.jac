test "weeks start on Monday and dates shift across months" {
    assert monday_of("2026-10-07") == "2026-10-05";
    assert monday_of("2026-10-05") == "2026-10-05";
    assert monday_of("2026-10-04") == "2026-09-28";
    assert shift("2026-10-31", 1) == "2026-11-01";
    assert days_between("2026-10-01", "2026-10-05") == 4;
    assert week_days("2026-10-05")[6] == "2026-10-11";
}

test "streaks count runs of days and survive until the day ends" {
    days = ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-05", "2026-10-05"];
    assert streaks(days, "2026-10-05") == (1, 3);
    assert streaks(days, "2026-10-06") == (1, 3);
    assert streaks(days, "2026-10-07") == (0, 3);
    assert streaks(["2026-10-03", "2026-10-04"], "2026-10-05") == (2, 2);
    assert streaks([], "2026-10-05") == (0, 0);
}

test "hours and labels" {
    assert hours_for("<30 min") == 0.5;
    assert hours_for("3+hr") == 3.0;
    assert fmt_hours(3.0) == "3";
    assert fmt_hours(2.5) == "2.5";
    assert hrs(1.0) == "1 hr";
    assert hrs(0.5) == "0.5 hrs";
    assert plural(1, "task") == "1 task";
    assert plural(2, "task") == "2 tasks";
}
