import QtQuick
import QtQuick.Layouts

// Pin (keep open when focus is lost) and collapse/expand buttons.
RowLayout {
    property bool pinned
    property bool compact
    signal pinClicked()
    signal compactClicked()

    spacing: 2

    IconButton {
        // Lucide "pin"
        path: "M12 17v5 M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z"
        checked: parent.pinned
        onClicked: parent.pinClicked()
    }
    IconButton {
        // Lucide "maximize-2" / "minimize-2"
        path: parent.compact ? "M15 3h6v6 M9 21H3v-6 M21 3l-7 7 M3 21l7-7"
                             : "M4 14h6v6 M20 10h-6V4 M14 10l7-7 M3 21l7-7"
        onClicked: parent.compactClicked()
    }
}
