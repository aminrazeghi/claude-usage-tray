import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// List-style details view: one section per limit window with a progress bar,
// then today's activity and a footer.
ColumnLayout {
    id: root

    signal showGaugeRequested()

    spacing: 10

    component Divider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.border
    }

    component SectionTitle: RowLayout {
        property alias icon: iconImage.source
        property alias title: titleText.text
        property alias value: valueText.text

        Layout.fillWidth: true
        spacing: 10

        Image {
            id: iconImage
            sourceSize: Qt.size(40, 40)
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }
        Text {
            id: titleText
            Layout.fillWidth: true
            color: Theme.textPrimary
            font.pixelSize: 15
        }
        Text {
            id: valueText
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Bold
        }
    }

    component LimitSection: ColumnLayout {
        id: section
        property alias icon: title.icon
        property alias title: title.title
        property bool known: false
        property real percent: 0
        property string caption

        Layout.fillWidth: true
        spacing: 8

        SectionTitle {
            id: title
            value: section.known ? Math.round(section.percent) + "%" : "—"
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Qt.rgba(0.91, 0.50, 0.35, Theme.dark ? 0.22 : 0.18)

            Rectangle {
                readonly property real fraction: Math.max(0, Math.min(1, section.percent / 100))
                visible: section.known
                // Keep a visible dot at 0-1% like a pill-shaped meter.
                width: Math.max(track.height, track.width * fraction)
                height: track.height
                radius: track.radius
                color: Theme.usageColor(section.percent)
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: section.caption
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }

    component MetricRow: RowLayout {
        property alias label: labelText.text
        property alias value: valueText.text

        Layout.fillWidth: true

        Text {
            id: labelText
            Layout.fillWidth: true
            color: Theme.textSecondary
            font.pixelSize: 13
        }
        Text {
            id: valueText
            color: Theme.textPrimary
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }

    component LinkText: Text {
        signal clicked()
        color: linkArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
        font.pixelSize: 13

        MouseArea {
            id: linkArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    Header { Layout.fillWidth: true }

    Divider {}

    LimitSection {
        icon: "../resources/icons/alarm.svg"
        title: "5-Hour Window"
        known: usage.fiveHourKnown
        percent: usage.fiveHourUsed
        caption: !usage.fiveHourKnown ? "No data yet"
               : usage.fiveHourRemainingText ? "Resets in " + usage.fiveHourRemainingText
               : "Window has reset"
    }

    LimitSection {
        Layout.topMargin: 4
        icon: "../resources/icons/calendar.svg"
        title: "Weekly"
        known: usage.sevenDayKnown
        percent: usage.sevenDayUsed
        caption: !usage.sevenDayKnown ? "No data yet"
               : usage.sevenDayRemainingText ? "Resets " + usage.sevenDayResetText
               : "Window has reset"
    }

    Divider { Layout.topMargin: 4 }

    SectionTitle {
        icon: "../resources/icons/today.svg"
        title: "Today"
    }

    MetricRow { label: "Messages:"; value: usage.todayMessages }
    MetricRow { label: "Tokens:"; value: usage.todayTokensText }

    Divider { Layout.topMargin: 4 }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: usage.updatedText
            color: Theme.textSecondary
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        RefreshButton {}
    }

    RowLayout {
        Layout.fillWidth: true

        LinkText {
            Layout.fillWidth: true
            text: "Gauge view"
            onClicked: root.showGaugeRequested()
        }
        LinkText {
            text: "Quit"
            onClicked: Qt.quit()
        }
    }
}
