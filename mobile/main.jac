import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView }
import from "@jac/runtime" { BridgeError }
import from core.planner { Task, AddResult, add_task, list_tasks, mark_complete }
import from .theme { C, styles }
import from .dates { local_iso, pretty_date, short_date, long_date, days_late }

"""Keep in sync with QUICK_NOTES in web/TaskList.jac."""
glob QUICK_NOTES: list[str] = [
    "Quick win: knock it out now.",
    "Under half an hour. Start it now.",
    "Small one. Clear it before the big ones.",
    "Twenty minutes and it's off your list.",
    "Do this one first. Momentum helps."
];

"""Split date-sorted tasks into one group per due date, keeping order."""
def group_by_day(tasks: list[Task]) -> list[dict[str, any]] {
    groups: list[dict[str, any]] = [];
    for t in tasks {
        if len(groups) == 0 or groups[len(groups) - 1]["due"] != t.due {
            groups.append({"due": t.due, "tasks": []});
        }
        groups[len(groups) - 1]["tasks"].append(t);
    }
    return groups;
}

def Tag(text: str, tone: any) -> JsxElement {
    return <Text style={[styles.tag, tone] if tone else styles.tag}>{text}</Text>;
}

def Dot -> JsxElement {
    return <Text style={styles.tagDot}>·</Text>;
}

def:pub TaskRow(task: Task, busy: bool, onToggle: Callable[[Task], None]) -> JsxElement {
    done = task.status == "done";
    late = 0 if done else days_late(task.due);
    highlight = None if done else (
        styles.rowToday if task.due == local_iso(0) else (
            styles.rowTomorrow if task.due == local_iso(1) else None
        )
    );
    quick = task.duration == "<30 min" and not done;
    lead = (
        Tag("done " + short_date(task.completed_at[:10] or task.due), styles.tagDone)
    ) if done else (
        Tag(str(late) + (" day late" if late == 1 else " days late"), styles.tagAccent)
    ) if late > 0 else None;
    return
        <Pressable
            style={lambda (state: any) {
                return [styles.row, highlight, styles.rowPressed if state.pressed else None];
            }}
            disabled={busy}
            onPress={lambda { onToggle(task); }}
            accessibilityRole="checkbox"
            accessibilityState={{"checked": done, "disabled": busy}}
            accessibilityLabel={task.title + (
                (", " + str(late) + (" day late" if late == 1 else " days late")) if late > 0 else ""
            )}
        >
            {(<View style={styles.lateBar}/>) if late > 0 else None}
            <View
                style={[styles.check, styles.checkDone] if done else (
                    [styles.check, styles.checkLate] if late > 0 else styles.check
                )}
            >
                <Text style={styles.checkMark}>{"✓" if done else ""}</Text>
            </View>
            <View style={styles.rowBody}>
                <Text style={[styles.taskTitle, styles.taskTitleDone] if done else styles.taskTitle}>
                    {task.title}
                </Text>
                {(<Text style={styles.note}>
                    {"→ " + QUICK_NOTES[len(task.title) % len(QUICK_NOTES)]}
                </Text>) if quick else None}
                <View style={styles.tags}>
                    {lead}
                    {(<Dot/>) if lead else None}
                    {Tag(
                        task.priority + " priority",
                        styles.tagAccent if task.priority == "high" else (
                            styles.tagStrong if task.priority == "medium" else None
                        )
                    )}
                    <Dot/>
                    {Tag(task.duration, None)}
                    {(<Dot/>) if task.category else None}
                    {Tag(task.category, styles.tagStrong) if task.category else None}
                </View>
            </View>
        </Pressable>;
}

def DayGroup(
    due: str, tasks: list[Task], busyId: str, onToggle: Callable[[Task], None]
) -> JsxElement {
    today = local_iso(0);
    has_open = len([t for t in tasks if t.status != "done"]) > 0;
    badge = "Today" if due == today else (
        "Tomorrow" if due == local_iso(1) else (
            "Overdue" if due < today and has_open else ""
        )
    );
    late = badge == "Overdue";
    return
        <View>
            <View style={[styles.dayHeading, styles.dayHeadingLate] if late else styles.dayHeading}>
                <Text style={[styles.dayTitle, styles.dayTitleLate] if late else styles.dayTitle}>
                    {pretty_date(due)}
                </Text>
                {(<View
                    style={[styles.badge, styles.badgeToday] if badge == "Today" else (
                        [styles.badge, styles.badgeLate] if late else styles.badge
                    )}
                >
                    <Text
                        style={[styles.badgeText, styles.badgeTextOn] if badge != "Tomorrow" else styles.badgeText}
                    >
                        {badge}
                    </Text>
                </View>) if badge else None}
            </View>
            {[
                <TaskRow key={jid(t)} task={t} busy={busyId == jid(t)} onToggle={onToggle}/>
                for t in tasks
            ]}
        </View>;
}

def EmptyState(title: str, note: str) -> JsxElement {
    return
        <View style={styles.empty} accessibilityRole="text">
            <Text style={styles.emptyMark}>❦</Text>
            <Text style={styles.emptyTitle}>{title}</Text>
            <Text style={styles.emptyNote}>{note}</Text>
        </View>;
}

def:pub app -> JsxElement {
    has tasks: list[Task] = [],
        title: str = "",
        error: str = "",
        saving: bool = False,
        focused: bool = False,
        busyId: str = "";

    async def refresh {
        try {
            tasks = await list_tasks();
            error = "";
        } except BridgeError {
            error = "Can't reach the planner server.";
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
        try {
            await mark_complete(jid(task), task.status != "done");
            await refresh();
        } except BridgeError {
            error = "Can't reach the planner server.";
        }
        busyId = "";
    }

    async def handle_add {
        if saving {
            return;
        }
        saving = True;
        try {
            res: AddResult = await add_task(title);
            if res.ok {
                title = "";
                await refresh();
            } else {
                error = res.error;
            }
        } except BridgeError {
            error = "Can't reach the planner server.";
        }
        saving = False;
    }

    return
        <ScrollView style={styles.screen} contentContainerStyle={styles.body}>
            <View style={styles.masthead}>
                <Text style={styles.dateline}>{long_date(local_iso(0))}</Text>
                <Text style={styles.title} accessibilityRole="header">The Planner</Text>
                <Text style={styles.tagline}>{"Coursework, deadlines & the day’s work"}</Text>
                <View style={styles.doubleRule}/>
            </View>
            <View>
                <Text style={styles.fieldLabel}>Task due today</Text>
                <View style={styles.addRow}>
                    <TextInput
                        style={[styles.input, styles.inputFocused] if focused else styles.input}
                        value={title}
                        placeholder="e.g. Read chapter 4"
                        placeholderTextColor={C.inkSoft}
                        accessibilityLabel="New task title"
                        onChangeText={lambda (t: str) { title = t; }}
                        onFocus={lambda { focused = True; }}
                        onBlur={lambda { focused = False; }}
                        onSubmitEditing={handle_add}
                        returnKeyType="done"
                    />
                    <Pressable
                        style={lambda (state: any) {
                            return [styles.button, styles.buttonPressed if state.pressed else None];
                        }}
                        disabled={saving}
                        onPress={handle_add}
                        accessibilityRole="button"
                    >
                        <Text style={styles.buttonText}>{"Adding…" if saving else "Add task"}</Text>
                    </Pressable>
                </View>
            </View>
            {(<Text style={styles.error} accessibilityRole="alert">{error}</Text>) if error else None}
            {(<EmptyState
                title="A clean slate."
                note="Nothing on the docket. Add a task above and it will be filed here."
            />) if len(tasks) == 0 else (
                <View style={styles.days}>
                    {[
                        <DayGroup
                            key={g["due"]}
                            due={g["due"]}
                            tasks={g["tasks"]}
                            busyId={busyId}
                            onToggle={handle_toggle}
                        /> for g in group_by_day(tasks)
                    ]}
                </View>
            )}
        </ScrollView>;
}
