"""Paper-and-ink theme for the mobile app, matching web/styles.css: warm paper,
black ink, one vermilion accent, serif text with small uppercase sans labels."""

import from "@jac/mobui" { StyleSheet, Platform }

obj Colors {
    has paper: str = "#f4efe4",
        paperDeep: str = "#ece5d6",
        ink: str = "#1d1b17",
        inkSoft: str = "#5e574b",
        rule: str = "rgba(29, 27, 23, 0.22)",
        accent: str = "#a8321d",
        accentWash: str = "rgba(168, 50, 29, 0.08)",
        done: str = "#3d6a3a",
        hlToday: str = "rgba(240, 196, 48, 0.34)",
        hlTomorrow: str = "rgba(240, 196, 48, 0.14)";
}

glob:pub C: Colors = Colors();

"""Built-in fonts only: Iowan Old Style / Avenir Next ship with iOS, Android has
generic serif / sans-serif, and the web preview gets the same stacks as the web app."""
glob:pub SERIF: str = Platform.select(
        {
            "ios": "Iowan Old Style",
            "android": "serif",
            "default": "'Iowan Old Style', 'Palatino Linotype', Palatino, Georgia, serif"
        }
    ),
    SANS: str = Platform.select(
        {
            "ios": "Avenir Next",
            "android": "sans-serif",
            "default": "'Avenir Next', 'Helvetica Neue', system-ui, sans-serif"
        }
    );

"""Small uppercase label type, shared by tags, badges and kickers."""
glob label: dict[str, any] = {
    "fontFamily": SANS,
    "fontSize": 10,
    "fontWeight": "600",
    "letterSpacing": 0.8,
    "textTransform": "uppercase"
};

glob:pub styles: any = StyleSheet.create(
    {
        "screen": {"flex": 1, "backgroundColor": C.paper},
        "body": {
            "width": "100%",
            "maxWidth": 640,
            "alignSelf": "center",
            "paddingHorizontal": 16,
            "paddingTop": 52,
            "paddingBottom": 48,
            "gap": 18
        },

        # Masthead
        "masthead": {"alignItems": "stretch"},
        "dateline": {
            **label,
            "color": C.inkSoft,
            "textAlign": "center",
            "paddingBottom": 8,
            "borderBottomWidth": 1,
            "borderBottomColor": C.ink
        },
        "title": {
            "fontFamily": SERIF,
            "fontSize": 42,
            "fontWeight": "700",
            "letterSpacing": -0.8,
            "color": C.ink,
            "textAlign": "center",
            "marginTop": 12
        },
        "tagline": {**label, "color": C.inkSoft, "textAlign": "center", "marginTop": 2},
        "doubleRule": {
            "marginTop": 12,
            "height": 4,
            "borderTopWidth": 1,
            "borderBottomWidth": 1,
            "borderColor": C.ink
        },

        # Add form
        "fieldLabel": {**label, "color": C.inkSoft, "marginBottom": 4},
        "addRow": {"flexDirection": "row", "alignItems": "flex-end", "gap": 12},
        "input": {
            "flex": 1,
            "fontFamily": SERIF,
            "fontSize": 19,
            "fontStyle": "italic",
            "color": C.ink,
            "paddingVertical": 6,
            "borderBottomWidth": 1,
            "borderBottomColor": C.ink
        },
        "inputFocused": {"borderBottomColor": C.accent, "borderBottomWidth": 2},
        "button": {
            "backgroundColor": C.ink,
            "paddingHorizontal": 14,
            "paddingVertical": 10,
            "justifyContent": "center"
        },
        "buttonPressed": {"backgroundColor": C.accent},
        "buttonText": {**label, "fontSize": 11, "color": C.paper},
        "error": {"fontFamily": SERIF, "fontStyle": "italic", "color": C.accent, "fontSize": 15},

        # Day groups
        "days": {"gap": 24},
        "dayHeading": {
            "flexDirection": "row",
            "alignItems": "center",
            "gap": 8,
            "paddingBottom": 6,
            "borderBottomWidth": 1,
            "borderBottomColor": C.ink
        },
        "dayHeadingLate": {"borderBottomColor": C.accent},
        "dayTitle": {
            "fontFamily": SERIF,
            "fontSize": 19,
            "fontWeight": "600",
            "fontStyle": "italic",
            "color": C.ink
        },
        "dayTitleLate": {"color": C.accent},
        "badge": {"borderWidth": 1, "borderColor": C.ink, "paddingHorizontal": 5, "paddingVertical": 1},
        "badgeToday": {"backgroundColor": C.ink},
        "badgeLate": {"backgroundColor": C.accent, "borderColor": C.accent},
        "badgeText": {**label, "fontSize": 9, "fontWeight": "700", "color": C.ink},
        "badgeTextOn": {"color": C.paper},

        # Task rows
        "row": {
            "flexDirection": "row",
            "alignItems": "center",
            "gap": 14,
            "paddingVertical": 12,
            "paddingHorizontal": 10,
            "borderBottomWidth": 1,
            "borderBottomColor": C.rule
        },
        "rowToday": {"backgroundColor": C.hlToday},
        "rowTomorrow": {"backgroundColor": C.hlTomorrow},
        "rowPressed": {"backgroundColor": "rgba(29, 27, 23, 0.06)"},
        "lateBar": {
            "position": "absolute",
            "left": 0,
            "top": 10,
            "bottom": 10,
            "width": 3,
            "backgroundColor": C.accent
        },
        "check": {
            "width": 22,
            "height": 22,
            "borderWidth": 1.5,
            "borderColor": C.ink,
            "alignItems": "center",
            "justifyContent": "center"
        },
        "checkLate": {"borderColor": C.accent},
        "checkDone": {"backgroundColor": C.ink},
        "checkMark": {"color": C.paper, "fontSize": 13, "fontWeight": "700"},
        "rowBody": {"flex": 1, "gap": 4},
        "taskTitle": {"fontFamily": SERIF, "fontSize": 17, "color": C.ink},
        "taskTitleDone": {
            "color": C.inkSoft,
            "textDecorationLine": "line-through",
            "textDecorationColor": C.accent
        },
        "note": {"fontFamily": SERIF, "fontStyle": "italic", "fontSize": 14, "color": C.done},
        "tags": {"flexDirection": "row", "flexWrap": "wrap", "alignItems": "center"},
        "tag": {**label, "color": C.inkSoft},
        "tagDot": {**label, "color": C.rule, "marginHorizontal": 6},
        "tagStrong": {"color": C.ink},
        "tagAccent": {"color": C.accent, "fontWeight": "700"},
        "tagDone": {"color": C.done},

        # Empty state
        "empty": {
            "alignItems": "center",
            "gap": 4,
            "paddingVertical": 28,
            "paddingHorizontal": 16,
            "borderTopWidth": 1,
            "borderTopColor": C.ink,
            "borderBottomWidth": 1,
            "borderBottomColor": C.rule
        },
        "emptyMark": {"fontSize": 26, "color": C.accent, "marginBottom": 4},
        "emptyTitle": {
            "fontFamily": SERIF,
            "fontSize": 21,
            "fontStyle": "italic",
            "fontWeight": "600",
            "color": C.ink
        },
        "emptyNote": {
            "fontFamily": SERIF,
            "fontSize": 15,
            "lineHeight": 22,
            "color": C.inkSoft,
            "textAlign": "center"
        }
    }
);
