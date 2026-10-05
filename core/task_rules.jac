import datetime;

glob MAX_TITLE: int = 120,
     MAX_CATEGORY: int = 40,
     LEVELS: list[str] = ["low", "medium", "high"],
     STATUSES: list[str] = ["todo", "doing", "done"],
     DURATIONS: list[str] = ["<30 min", "1hr", "2hr", "3+hr"],
     DEFAULT_DURATION: str = "1hr",
     DURATION_ALIASES: dict[str, str] = {
         "<30min": "<30 min",
         "30min": "<30 min",
         "30": "<30 min",
         "1hr": "1hr",
         "1h": "1hr",
         "1": "1hr",
         "2hr": "2hr",
         "2h": "2hr",
         "2": "2hr",
         "3+hr": "3+hr",
         "3+h": "3+hr",
         "3+": "3+hr",
         "3hr": "3+hr",
         "3": "3+hr"
     };

obj TaskCheck {
    has ok: bool = True,
        error: str = "",
        title: str = "",
        due: str = "",
        priority: str = "medium",
        duration: str = "1hr",
        category: str = "";
}

def today_iso -> str {
    return datetime.date.today().isoformat();
}

def now_stamp -> str {
    return datetime.datetime.now().isoformat(timespec="seconds");
}

def _valid_date(text: str) -> bool {
    try {
        datetime.date.fromisoformat(text);
        return len(text) == 10;
    } except ValueError {
        return False;
    }
}

def _level(value: str, name: str, check: TaskCheck) -> str {
    level = value.strip().lower() or "medium";
    if level not in LEVELS {
        check.ok = False;
        check.error = name + " must be one of: " + ", ".join(LEVELS);
    }
    return level;
}

"""Normalise a time estimate ("<30min", "1 hr", "3+") to one of DURATIONS; blank
means the default. Returns "" when it isn't recognised."""
def _duration(value: str) -> str {
    key = value.strip().lower().replace(" ", "");
    if not key {
        return DEFAULT_DURATION;
    }
    return DURATION_ALIASES.get(key, "");
}

"""Case-insensitive match against categories already in use, so "eecs 449" joins
"EECS 449" instead of becoming a second group."""
def match_category(category: str, existing: list[str]) -> str {
    for e in existing {
        if e.lower() == category.lower() {
            return e;
        }
    }
    return category;
}

def check_task_input(
    title: str, due: str, priority: str, duration: str, category: str
) -> TaskCheck {
    check = TaskCheck();
    check.title = " ".join(title.split());
    if not check.title {
        return TaskCheck(ok=False, error="title is required");
    }
    if len(check.title) > MAX_TITLE {
        return TaskCheck(
            ok=False, error="title is longer than " + str(MAX_TITLE) + " characters"
        );
    }
    check.due = due.strip() or today_iso();
    if not _valid_date(check.due) {
        return TaskCheck(ok=False, error="due date must look like YYYY-MM-DD");
    }
    check.priority = _level(priority, "priority", check);
    check.duration = _duration(duration);
    if not check.duration {
        return TaskCheck(
            ok=False, error="time must be one of: " + ", ".join(DURATIONS)
        );
    }
    check.category = " ".join(category.split())[:MAX_CATEGORY];
    return check;
}
