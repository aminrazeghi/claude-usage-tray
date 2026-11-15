import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Usage popup content: click the gauge to switch between used and available,
// click a row's reset time to see the time left instead.
ColumnLayout {
    id: root

    property QtObject usage  // UsageWatcher of the selected profile
    property bool showAvailable: false

    spacing: 12

    CircularGauge {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        Layout.preferredWidth: 172
        Layout.preferredHeight: 172
        innerValue: root.usage.fiveHourUsed / 100
        outerValue: root.usage.sevenDayUsed / 100
        hasData: root.usage.hasData
        showAvailable: root.showAvailable
        innerColor: Theme.green
        outerColor: Theme.purple
        trackColor: Theme.track
        textColor: Theme.textPrimary
        subTextColor: Theme.textSecondary
        onClicked: root.showAvailable = !root.showAvailable
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6

        UsageRow {
            Layout.fillWidth: true
            accent: Theme.green
            icon: "../resources/icons/alarm.svg"
            title: "5-Hour"
            known: root.usage.fiveHourKnown
            percent: root.usage.fiveHourUsed
            resetText: root.usage.fiveHourResetText
            leftText: root.usage.fiveHourLeftText
        }
        UsageRow {
            Layout.fillWidth: true
            accent: Theme.purple
            icon: "../resources/icons/calendar.svg"
            title: "Weekly"
            known: root.usage.sevenDayKnown
            percent: root.usage.sevenDayUsed
            resetText: root.usage.sevenDayResetText
            leftText: root.usage.sevenDayLeftText
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 1
        color: Theme.border
    }

    // Today's activity, from local Claude Code transcripts.
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 4

        Text {
            Layout.columnSpan: 2
            Layout.bottomMargin: 2
            text: "Today"
            color: Theme.textPrimary
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Text { text: "Messages"; color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: root.usage.todayMessages; color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
        Text { text: "Tokens (in + out)"; color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: root.usage.todayTokensText; color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.border
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: root.usage.updatedText + (root.usage.model ? " · " + root.usage.model : "")
            color: Theme.textSecondary
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        RefreshButton { usage: root.usage }
    }

    Text {
        visible: !root.usage.hasData
        Layout.fillWidth: true
        text: "Limits appear after Claude Code's next response. The status line writes them to " + root.usage.usageFile + "."
        wrapMode: Text.WordWrap
        color: Theme.textSecondary
        font.pixelSize: 11
    }
}
