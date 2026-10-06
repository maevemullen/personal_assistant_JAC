"""Date helpers for the mobile app, in the device's local time. Dates travel as
YYYY-MM-DD strings. These mirror the ones in web/TaskList.jac, which can't be
imported here because that module renders HTML."""

def pad2(n: float) -> str {
    text = str(int(n));
    return ("0" + text) if len(text) < 2 else text;
}

def iso_of(d: any) -> str {
    return str(int(d.getFullYear())) + "-" + pad2(d.getMonth() + 1) + "-" + pad2(
        d.getDate()
    );
}

"""Local midnight on an ISO day (a bare `new Date("2026-10-04")` would be UTC)."""
def:pub parse_day(iso: str) -> any {
    return new(Date, iso + "T00:00:00");
}

"""ISO date for today plus `offset` days."""
def:pub local_iso(offset: int) -> str {
    d = new(Date);
    d.setDate(d.getDate() + offset);
    return iso_of(d);
}

def:pub pretty_date(iso: str) -> str {
    return parse_day(iso).toLocaleDateString(
        "en-US", {"weekday": "long", "month": "short", "day": "numeric"}
    );
}

def:pub short_date(iso: str) -> str {
    return parse_day(iso).toLocaleDateString("en-US", {"month": "short", "day": "numeric"});
}

def:pub long_date(iso: str) -> str {
    return parse_day(iso).toLocaleDateString(
        "en-US", {"weekday": "long", "month": "long", "day": "numeric", "year": "numeric"}
    );
}

"""Whole days `iso` is in the past; 0 for today and later."""
def:pub days_late(iso: str) -> int {
    today = local_iso(0);
    if iso >= today {
        return 0;
    }
    gap = parse_day(today).getTime() - parse_day(iso).getTime();
    return int(gap / 86400000 + 0.5);
}
