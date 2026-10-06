import from core.planner {
    Task,
    AddResult,
    ProgressReport,
    add_task,
    list_tasks,
    mark_complete,
    delete_task,
    progress_report
}
import from "@jac/runtime" { BridgeError }
import from .TaskList {
    ListView,
    EmptyState,
    category_names,
    filter_tasks,
    local_iso,
    parse_day
}
import from .CalendarView { CalendarView }
import from .CompletedView { CompletedView }
import from .ProgressView { ProgressView }
import from .EditTaskDialog { EditTaskDialog }
import from .Fields { CategoryField, OptionSelect, LEVEL_OPTIONS, DURATION_OPTIONS }

glob VIEWS: list[str] = ["list", "calendar", "completed", "progress"];

"""The view named in the URL hash (#calendar), defaulting to the list."""
def view_from_hash -> str {
    name = window.location.hash.replace("#", "");
    return name if name in VIEWS else "list";
}

def:pub PlannerPage -> JsxElement {
    has tasks: list[Task] = [],
        title: str = "",
        due: str = "",
        priority: str = "medium",
        duration: str = "1hr",
        category: str = "",
        newCategory: bool = False,
        error: str = "",
        saving: bool = False,
        busyId: str = "",
        query: str = "",
        view: str = view_from_hash(),
        editing: Task | None = None,
        weekly: ProgressReport | None = None;

    shown = filter_tasks(tasks, query);
    searching = len(query.strip()) > 0;

    def show(name: str) {
        view = name;
        window.history.replaceState(None, "", "#" + name);
    }

    async def refresh {
        try {
            tasks = await list_tasks();
            weekly = await progress_report(local_iso(0));
        } except BridgeError {
            error = "Could not reach the planner server.";
        }
    }

    async can with entry {
        await refresh();
    }

    async def handle_toggle(task: Task) {
        if busyId {
            return;
        }
        busyId = jid(task);
        error = "";
        try {
            await mark_complete(jid(task), task.status != "done");
            await refresh();
        } except BridgeError {
            error = "Could not reach the planner server.";
        }
        busyId = "";
    }

    async def handle_delete(task: Task) {
        if busyId {
            return;
        }
        busyId = jid(task);
        error = "";
        try {
            if not await delete_task(jid(task)) {
                error = "That task was already deleted.";
            }
            await refresh();
        } except BridgeError {
            error = "Could not reach the planner server.";
        }
        busyId = "";
    }

    async def handle_submit(e: FormEvent) {
        e.preventDefault();
        if saving {
            return;
        }
        saving = True;
        error = "";
        try {
            res: AddResult = await add_task(title, due, priority, duration, category);
            if res.ok {
                title = "";
                # Keep the category for the next task; the server may have matched
                # it to an existing spelling, so adopt that one.
                if res.task {
                    category = res.task.category;
                }
                newCategory = False;
                await refresh();
            } else {
                error = res.error;
            }
        } except BridgeError {
            error = "Could not reach the planner server.";
        }
        saving = False;
    }

    <main className="page">
        <header className="masthead">
            <p className="dateline">
                {parse_day(local_iso(0)).toLocaleDateString(
                    "en-US",
                    {"weekday": "long", "month": "long", "day": "numeric", "year": "numeric"}
                )}
            </p>
            <h1>The Planner</h1>
            <p className="tagline">{"Coursework, deadlines & the day’s work"}</p>
        </header>
        <form className="add-form" onSubmit={handle_submit}>
            <label className="field wide">
                <span>Task</span>
                <input
                    value={title}
                    placeholder="e.g. Read chapter 4"
                    onChange={lambda (e: ChangeEvent) { title = e.target.value; }}
                />
            </label>
            <label className="field">
                <span>Due (blank = today)</span>
                <input
                    type="date"
                    value={due}
                    onChange={lambda (e: ChangeEvent) { due = e.target.value; }}
                />
            </label>
            <OptionSelect
                label="Priority"
                value={priority}
                options={LEVEL_OPTIONS}
                onPick={lambda (v: str) { priority = v; }}
            />
            <OptionSelect
                label="Time"
                value={duration}
                options={DURATION_OPTIONS}
                onPick={lambda (v: str) { duration = v; }}
            />
            <CategoryField
                value={category}
                adding={newCategory}
                names={category_names(tasks)}
                onChange={lambda (v: str, adding: bool) {
                    category = v;
                    newCategory = adding;
                }}
            />
            <button type="submit" disabled={saving}>
                {"Adding…" if saving else "Add task"}
            </button>
        </form>
        {error and <p className="error" role="alert">{error}</p>}
        <div className="list-heading">
            <nav className="tabs" aria-label="Views">
                {[
                    <button
                        key={v}
                        type="button"
                        className={"tab" + (" active" if v == view else "")}
                        aria-current={"page" if v == view else None}
                        onClick={lambda { show(v); }}
                    >
                        {v.capitalize()}
                    </button> for v in VIEWS
                ]}
            </nav>
            <span className="counts" aria-live="polite">
                {(str(len(shown)) + " of " + str(len(tasks)) + " match") if searching else (
                    str(len([t for t in tasks if t.status != "done"])) + " open · "
                        + str(len([t for t in tasks if t.status == "done"])) + " done"
                )}
            </span>
        </div>
        <div className="search" hidden={view == "progress"}>
            <input
                type="search"
                className="search-input"
                value={query}
                placeholder="Search tasks by title, category, priority, time or date…"
                aria-label="Search tasks"
                onChange={lambda (e: ChangeEvent) { query = e.target.value; }}
                onKeyDown={lambda (e: KeyboardEvent) {
                    if e.key == "Escape" {
                        query = "";
                    }
                }}
            />
            {(<button
                type="button"
                className="ghost search-clear"
                onClick={lambda { query = ""; }}
            >
                Clear
            </button>) if searching else ""}
        </div>
        {((<ProgressView
            weekly={weekly}
            busyId={busyId}
            onToggle={handle_toggle}
            onDelete={handle_delete}
            onEdit={lambda (t: Task) { editing = t; }}
        />) if weekly else (<p className="loading">Gathering your week…</p>))
            if view == "progress" else (<EmptyState
            title="No matches."
            note={"Nothing matches “" + query.strip() + "”. Try fewer words, or press Esc to clear."}
        />)
            if searching and len(shown) == 0 else (
        (<CalendarView
                tasks={shown}
                busyId={busyId}
                onToggle={handle_toggle}
                onDelete={handle_delete}
                onEdit={lambda (t: Task) { editing = t; }}
            />)
            if view == "calendar" else (
            (<CompletedView
                    tasks={shown}
                    busyId={busyId}
                    onToggle={handle_toggle}
                    onDelete={handle_delete}
                    onEdit={lambda (t: Task) { editing = t; }}
                />)
                if view == "completed" else (
                <ListView
                    tasks={shown}
                    busyId={busyId}
                    onToggle={handle_toggle}
                    onDelete={handle_delete}
                    onEdit={lambda (t: Task) { editing = t; }}
                />
            )
        ))}
        {(<EditTaskDialog
            key={jid(editing)}
            task={editing}
            categories={category_names(tasks)}
            onSaved={lambda {
                editing = None;
                refresh();
            }}
            onClose={lambda { editing = None; }}
        />) if editing else ""}
    </main>
}
