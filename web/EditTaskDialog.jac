"""Edit every field of one task in a modal. Mount it with key={jid(task)} so the
form starts from that task's values."""

import from core.planner { Task, AddResult, edit_task }
import from "@jac/runtime" { BridgeError }
import from .Fields {
    CategoryField,
    OptionSelect,
    LEVEL_OPTIONS,
    DURATION_OPTIONS,
    STATUS_OPTIONS
}

def:pub EditTaskDialog(
    task: Task,
    categories: list[str],
    onSaved: Callable[[], None],
    onClose: Callable[[], None]
) -> JsxElement {
    has title: str = task.title,
        due: str = task.due,
        priority: str = task.priority,
        duration: str = task.duration,
        category: str = task.category,
        status: str = task.status,
        newCategory: bool = False,
        error: str = "",
        saving: bool = False;

    async def handle_save(e: FormEvent) {
        e.preventDefault();
        if saving {
            return;
        }
        saving = True;
        error = "";
        try {
            res: AddResult = await edit_task(
                jid(task), title, due, priority, duration, category, status
            );
            if res.ok {
                onSaved();
            } else {
                error = res.error;
            }
        } except BridgeError {
            error = "Could not reach the planner server.";
        }
        saving = False;
    }

    <div
        className="modal-backdrop"
        onClick={lambda (e: MouseEvent) {
            if e.target == e.currentTarget {
                onClose();
            }
        }}
    >
        <form
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="edit-heading"
            onSubmit={handle_save}
            onKeyDown={lambda (e: KeyboardEvent) {
                if e.key == "Escape" {
                    onClose();
                }
            }}
        >
            <h2 id="edit-heading">Edit task</h2>
            <label className="field wide">
                <span>Task</span>
                <input
                    value={title}
                    autoFocus={True}
                    onChange={lambda (e: ChangeEvent) { title = e.target.value; }}
                />
            </label>
            <div className="modal-fields">
                <label className="field">
                    <span>Due</span>
                    <input
                        type="date"
                        value={due}
                        onChange={lambda (e: ChangeEvent) { due = e.target.value; }}
                    />
                </label>
                <OptionSelect
                    label="Status"
                    value={status}
                    options={STATUS_OPTIONS}
                    onPick={lambda (v: str) { status = v; }}
                />
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
                    names={categories}
                    onChange={lambda (v: str, adding: bool) {
                        category = v;
                        newCategory = adding;
                    }}
                />
            </div>
            {error and <p className="error" role="alert">{error}</p>}
            <div className="modal-actions">
                <button type="button" className="ghost" onClick={lambda { onClose(); }}>
                    Cancel
                </button>
                <button type="submit" disabled={saving}>
                    {"Saving…" if saving else "Save"}
                </button>
            </div>
        </form>
    </div>
}
