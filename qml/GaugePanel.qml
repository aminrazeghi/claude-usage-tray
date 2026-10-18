import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Ring gauge view: click the gauge to switch between used and available.
ColumnLayout {
    id: root

    property bool showAvailable: false

    spacing: 12

    Header { Layout.fillWidth: true }

    CircularGauge {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        Layout.preferredWidth: 172
        Layout.preferredHeight: 172
        innerValue: usage.fiveHourUsed / 100
        outerValue: usage.sevenDayUsed / 100
        hasData: usage.hasData
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
            color: Theme.card
            accent: Theme.green
            known: usage.fiveHourKnown
            badgeValue: Math.round(usage.fiveHourUsed)
            title: "5-Hour Limit"
            value: root.showAvailable ? usage.fiveHourLeftText : usage.fiveHourResetText
            textColor: Theme.textPrimary
            subTextColor: Theme.textSecondary
        }
        UsageRow {
            Layout.fillWidth: true
            color: Theme.card
            accent: Theme.purple
            known: usage.sevenDayKnown
            badgeValue: Math.round(usage.sevenDayUsed)
            title: "7-Day Limit"
            value: root.showAvailable ? usage.sevenDayLeftText : usage.sevenDayResetText
            textColor: Theme.textPrimary
            subTextColor: Theme.textSecondary
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
        Text { text: usage.todayMessages; color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
        Text { text: "Tokens (in + out)"; color: Theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: usage.todayTokensText; color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
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
            text: usage.updatedText + (usage.model ? " · " + usage.model : "")
            color: Theme.textSecondary
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        RefreshButton {}
    }

    Text {
        visible: !usage.hasData
        Layout.fillWidth: true
        text: "Limits appear after Claude Code's next response. The status line writes them to " + usage.usageFile + "."
        wrapMode: Text.WordWrap
        color: Theme.textSecondary
        font.pixelSize: 11
    }
}
