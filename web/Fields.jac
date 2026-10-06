"""Form fields shared by the add form and the edit dialog."""

glob:pub LEVEL_OPTIONS: list[str] = ["low", "medium", "high"],
     DURATION_OPTIONS: list[str] = ["<30 min", "1hr", "2hr", "3+hr"],
     STATUS_OPTIONS: list[str] = ["todo", "doing", "done"],
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

"""Pick an existing category, none, or "+ New category…" which reveals a text box.
`adding` is true while the text box is shown; onChange reports (value, adding)."""
def:pub CategoryField(
    value: str,
    adding: bool,
    names: list[str],
    onChange: Callable[[str, bool], None]
) -> JsxElement {
    <>
        <label className="field">
            <span>Category</span>
            <select
                value={NEW_CATEGORY if adding else value}
                onChange={lambda (e: ChangeEvent) {
                    picked = e.target.value;
                    if picked == NEW_CATEGORY {
                        onChange("", True);
                    } else {
                        onChange(picked, False);
                    }
                }}
            >
                <option value="">None</option>
                {[<option key={c} value={c}>{c}</option> for c in names]}
                <option value={NEW_CATEGORY}>+ New category…</option>
            </select>
        </label>
        {(<label className="field">
            <span>New category</span>
            <input
                value={value}
                placeholder="e.g. EECS 449"
                autoFocus={True}
                onChange={lambda (e: ChangeEvent) { onChange(e.target.value, True); }}
            />
        </label>) if adding else ""}
    </>
}
