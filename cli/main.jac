import argparse;
import asyncio;
import sys;
import from cli.tasks { EXIT_USAGE, run_add, run_done, run_list, warn }

glob PROG: str = "planner";

obj Invocation {
    has command: str = "",
        title: str = "",
        due: str = "",
        priority: str = "medium",
        duration: str = "",
        category: str = "",
        number: int = 0,
        undo: bool = False;
}

def build_parser -> argparse.ArgumentParser {
    parser = argparse.ArgumentParser(
        prog=PROG,
        description="Quick terminal access to your planner. Needs the server: `jac run`."
    );
    commands = parser.add_subparsers(
        dest="command", metavar="<command>", required=True
    );
    add = commands.add_parser("add", help="add a task");
    add.add_argument("title", help="what needs doing");
    add.add_argument(
        "--due", `default="", help="YYYY-MM-DD (default: today)"
    );
    add.add_argument(
        "--priority", `default="medium", choices=["low", "medium", "high"]
    );
    add.add_argument(
        "--time",
        dest="duration",
        `default="",
        choices=["<30min", "1hr", "2hr", "3+hr"],
        help="time it needs (default: 1hr); quote <30min in your shell"
    );
    add.add_argument("--category", `default="", help="e.g. \"EECS 449\"");
    commands.add_parser("list", help="show every task, numbered, by due date");
    done = commands.add_parser("done", help="mark a task complete");
    done.add_argument("number", type=int, help="the task's number from `list`");
    done.add_argument(
        "--undo", action="store_true", help="mark it not done instead"
    );
    return parser;
}

def parse_args(argv: list[str]) -> Invocation {
    ns = build_parser().parse_args(argv);
    return Invocation(
        command=str(getattr(ns, "command", "") or ""),
        title=str(getattr(ns, "title", "") or ""),
        due=str(getattr(ns, "due", "") or ""),
        priority=str(getattr(ns, "priority", "medium") or "medium"),
        duration=str(getattr(ns, "duration", "") or ""),
        category=str(getattr(ns, "category", "") or ""),
        number=int(getattr(ns, "number", 0) or 0),
        undo=bool(getattr(ns, "undo", False))
    );
}

async def dispatch(inv: Invocation) -> int {
    if inv.command == "add" {
        return await run_add(
            inv.title, inv.due, inv.priority, inv.duration, inv.category
        );
    }
    if inv.command == "list" {
        return await run_list();
    }
    if inv.command == "done" {
        return await run_done(inv.number, not inv.undo);
    }
    warn("planner: unknown command " + inv.command);
    return EXIT_USAGE;
}

async def main(argv: list[str]) -> int {
    return await dispatch(parse_args(argv));
}

with entry:__main__ {
    sys.`exit(asyncio.run(main(sys.argv[1:])));
}
