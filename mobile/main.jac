import from "@jac/mobui" {
    View,
    Text,
    Pressable,
    TextInput,
    ScrollView,
    StyleSheet
}
import from "@jac/runtime" { BridgeError }
import from core.planner { Task, AddResult, add_task, list_tasks, mark_complete }

glob styles: any = StyleSheet.create(
    {
        "screen": {"flex": 1, "backgroundColor": "#f7f7f5"},
        "body": {"padding": 20, "paddingTop": 56, "gap": 12},
        "heading": {"fontSize": 28, "fontWeight": "bold", "color": "#1d1d1f"},
        "row": {"flexDirection": "row", "gap": 8},
        "input": {
            "flex": 1,
            "borderWidth": 1,
            "borderColor": "#e2e2de",
            "borderRadius": 8,
            "paddingHorizontal": 12,
            "paddingVertical": 10,
            "backgroundColor": "#ffffff",
            "fontSize": 16
        },
        "button": {
            "backgroundColor": "#2f6fde",
            "borderRadius": 8,
            "paddingHorizontal": 16,
            "justifyContent": "center"
        },
        "buttonText": {"color": "#ffffff", "fontSize": 16, "fontWeight": "bold"},
        "error": {"color": "#c0392b", "fontSize": 14},
        "empty": {"color": "#6b6b70", "fontSize": 15},
        "card": {
            "flexDirection": "row",
            "alignItems": "center",
            "backgroundColor": "#ffffff",
            "borderWidth": 1,
            "borderColor": "#e2e2de",
            "borderRadius": 8,
            "padding": 12,
            "gap": 12
        },
        "cardDone": {"opacity": 0.55},
        "cardBody": {"flex": 1, "gap": 2},
        "check": {
            "width": 28,
            "height": 28,
            "borderRadius": 14,
            "borderWidth": 2,
            "borderColor": "#8a8a90",
            "alignItems": "center",
            "justifyContent": "center"
        },
        "checkDone": {"backgroundColor": "#2f6fde", "borderColor": "#2f6fde"},
        "checkMark": {"color": "#ffffff", "fontSize": 16, "fontWeight": "bold"},
        "title": {"fontSize": 16, "fontWeight": "bold", "color": "#1d1d1f"},
        "titleDone": {"textDecorationLine": "line-through", "color": "#6b6b70"},
        "meta": {"fontSize": 13, "color": "#6b6b70"}
    }
);

def:pub TaskCard(task: Task, onToggle: Callable[[Task], None]) -> JsxElement {
    done = task.status == "done";
    return
        <Pressable
            style={[styles.card, styles.cardDone] if done else styles.card}
            onPress={lambda { onToggle(task); }}
            accessibilityRole="checkbox"
            accessibilityState={{"checked": done}}
        >
            <View style={[styles.check, styles.checkDone] if done else styles.check}>
                <Text style={styles.checkMark}>{"✓" if done else ""}</Text>
            </View>
            <View style={styles.cardBody}>
                <Text style={[styles.title, styles.titleDone] if done else styles.title}>
                    {task.title}
                </Text>
                <Text style={styles.meta}>
                    {"due " + task.due + " · " + task.priority + " priority"}
                </Text>
            </View>
        </Pressable>;
}

def:pub app -> JsxElement {
    has tasks: list[Task] = [],
        title: str = "",
        error: str = "",
        saving: bool = False,
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
            <Text style={styles.heading}>Planner</Text>
            <View style={styles.row}>
                <TextInput
                    style={styles.input}
                    value={title}
                    placeholder="Add a task for today"
                    placeholderTextColor="#8a8a90"
                    onChangeText={lambda (t: str) { title = t; }}
                    onSubmitEditing={handle_add}
                />
                <Pressable style={styles.button} onPress={handle_add}>
                    <Text style={styles.buttonText}>{"…" if saving else "Add"}</Text>
                </Pressable>
            </View>
            {(<Text style={styles.error}>{error}</Text>) if error else <View/>}
            {(<Text style={styles.empty}>No tasks yet.</Text>) if len(tasks) == 0 else (
                <View style={{"gap": 8}}>
                    {[<TaskCard key={jid(t)} task={t} onToggle={handle_toggle}/> for t in tasks]}
                </View>
            )}
        </ScrollView>;
}
