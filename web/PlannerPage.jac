import from core.planner { Task, AddResult, add_task, list_tasks, mark_complete, delete_task }
import from "@jac/runtime" { BridgeError }
import from .TaskList { ListView, category_names, filter_tasks }
import from .CalendarView { CalendarView }
import from .CompletedView { CompletedView }

glob LEVEL_OPTIONS: list[str] = ["low", "medium", "high"],
     DURATION_OPTIONS: list[str] = ["<30 min", "1hr", "2hr", "3+hr"],
     NEW_CATEGORY: str = "__new__";

def:pub OptionSelect(
    label: str, value: str, options: list[str], onPick: Callable[[str], None]
) -> JsxElement {
    <label className="field">
        <span>{label}</span>
        <select
            value={value}
            onChange={lambda (e: ChangeEvent) { onPick(e.target.value); }}
        >
            {[<option key={o} value={o}>{o}</option> for o in options]}
        </select>
    </label>
}

glob VIEWS: list[str] = ["list", "calendar", "completed"];

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
        view: str = view_from_hash();

    shown = filter_tasks(tasks, query);
    searching = len(query.strip()) > 0;

    def pick_category(value: str) {
        if value == NEW_CATEGORY {
            newCategory = True;
            category = "";
        } else {
            newCategory = False;
            category = value;
        }
    }

    def show(name: str) {
        view = name;
        window.history.replaceState(None, "", "#" + name);
    }

    async def refresh {
        try {
            tasks = await list_tasks();
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
        <h1>Planner</h1>
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
            <label className="field">
                <span>Category</span>
                <select
                    value={NEW_CATEGORY if newCategory else category}
                    onChange={lambda (e: ChangeEvent) { pick_category(e.target.value); }}
                >
                    <option value="">None</option>
                    {[<option key={c} value={c}>{c}</option> for c in category_names(tasks)]}
                    <option value={NEW_CATEGORY}>+ New category…</option>
                </select>
            </label>
            {(<label className="field">
                <span>New category</span>
                <input
                    value={category}
                    placeholder="e.g. EECS 449"
                    autoFocus={True}
                    onChange={lambda (e: ChangeEvent) { category = e.target.value; }}
                />
            </label>) if newCategory else ""}
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
        <div className="search">
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
        {(<p className="empty">{"No tasks match “" + query.strip() + "”."}</p>)
            if searching and len(shown) == 0 else (
        (<CalendarView
                tasks={shown}
                busyId={busyId}
                onToggle={handle_toggle}
                onDelete={handle_delete}
            />)
            if view == "calendar" else (
            (<CompletedView
                    tasks={shown}
                    busyId={busyId}
                    onToggle={handle_toggle}
                    onDelete={handle_delete}
                />)
                if view == "completed" else (
                <ListView
                    tasks={shown}
                    busyId={busyId}
                    onToggle={handle_toggle}
                    onDelete={handle_delete}
                />
            )
        ))}
    </main>
}
