"""Date and number helpers for the progress report. Days are YYYY-MM-DD strings;
weeks run Monday to Sunday."""

import datetime;

"""Rough hours for each time estimate, used to total up a week's work."""
glob HOURS: dict[str, float] = {"<30 min": 0.5, "1hr": 1.0, "2hr": 2.0, "3+hr": 3.0};

def hours_for(duration: str) -> float {
    return HOURS.get(duration, 1.0);
}

def _day(text: str) -> datetime.date {
    return datetime.date.fromisoformat(text);
}

def shift(day: str, days: int) -> str {
    return (_day(day) + datetime.timedelta(days=days)).isoformat();
}

def monday_of(day: str) -> str {
    return shift(day, -_day(day).weekday());
}

def days_between(start: str, end: str) -> int {
    return (_day(end) - _day(start)).days;
}

"""The seven days of the week that starts on `monday`."""
def week_days(monday: str) -> list[str] {
    return [shift(monday, i) for i in range(7)];
}

"""(current, best) runs of consecutive days in `days`. The current run ends today,
or yesterday if nothing is done yet today, so the streak survives until midnight."""
def streaks(days: list[str], today: str) -> tuple[int, int] {
    seen = set(days);
    best = 0;
    for d in seen {
        if shift(d, -1) not in seen {
            run = 1;
            while shift(d, run) in seen {
                run += 1;
            }
            best = max(best, run);
        }
    }
    end = today if today in seen else shift(today, -1);
    current = 0;
    while shift(end, -current) in seen {
        current += 1;
    }
    return (current, best);
}

"""'1 task' / '3 tasks'."""
def plural(n: int, word: str) -> str {
    return str(n) + " " + word + ("" if n == 1 else "s");
}

"""Hours without a trailing .0: 2.5 -> '2.5', 3.0 -> '3'."""
def fmt_hours(h: float) -> str {
    text = str(round(h, 1));
    return text[:-2] if text.endswith(".0") else text;
}

"""'1 hr' / '2.5 hrs'."""
def hrs(h: float) -> str {
    return fmt_hours(h) + (" hr" if round(h, 1) == 1 else " hrs");
}
