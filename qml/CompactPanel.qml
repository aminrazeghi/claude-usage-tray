import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Collapsed view: the icon and percent used for each limit window, one line
// per subscription (named when there is more than one).
RowLayout {
    id: root

    property var profiles: []
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
            // Wide enough for "100%" so the columns line up across rows.
            Layout.preferredWidth: 42
            text: parent.known ? Math.round(parent.percent) + "%" : "—"
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Bold
        }
    }

    ColumnLayout {
        spacing: 6

        Repeater {
            model: root.profiles

            RowLayout {
                id: line

                required property var modelData

                spacing: 10

                Text {
                    visible: root.profiles.length > 1
                    Layout.preferredWidth: nameMetrics.width
                    text: line.modelData.name
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }
                Chip {
                    accent: Theme.green
                    icon: "../resources/icons/alarm.svg"
                    known: line.modelData.fiveHourKnown
                    percent: line.modelData.fiveHourUsed
                }
                Chip {
                    accent: Theme.purple
                    icon: "../resources/icons/calendar.svg"
                    known: line.modelData.sevenDayKnown
                    percent: line.modelData.sevenDayUsed
                }
            }
        }
    }

    // Widest profile name, so the chips line up across rows.
    TextMetrics {
        id: nameMetrics
        font.pixelSize: 12
        text: root.profiles.reduce((longest, p) => p.name.length > longest.length ? p.name : longest, "")
    }

    WindowControls {
        id: controls
        compact: true
        onPinClicked: root.pinClicked()
        onCompactClicked: root.expandClicked()
    }
}
