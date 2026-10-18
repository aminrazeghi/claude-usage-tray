import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Collapsed view: just the icon and percent used for each limit window.
RowLayout {
    id: root

    property alias pinned: controls.pinned
    signal pinClicked()
    signal expandClicked()

    spacing: 12

    component Chip: RowLayout {
        property alias accent: badge.accent
        property alias icon: badge.icon
        property bool known
        property real percent

        spacing: 6

        IconBadge { id: badge }
        Text {
            text: parent.known ? Math.round(parent.percent) + "%" : "—"
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Bold
        }
    }

    Chip {
        accent: Theme.green
        icon: "../resources/icons/alarm.svg"
        known: usage.fiveHourKnown
        percent: usage.fiveHourUsed
    }
    Chip {
        accent: Theme.purple
        icon: "../resources/icons/calendar.svg"
        known: usage.sevenDayKnown
        percent: usage.sevenDayUsed
    }

    WindowControls {
        id: controls
        Layout.leftMargin: 4
        compact: true
        onPinClicked: root.pinClicked()
        onCompactClicked: root.expandClicked()
    }
}
