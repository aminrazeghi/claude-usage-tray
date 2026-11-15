import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Segmented control with one tab per subscription; each tab shows that
// account's 5-hour usage so the other one can be watched at a glance.
Rectangle {
    id: tabs

    property var profiles: []
    property int currentIndex: 0

    implicitHeight: 32
    radius: 9
    color: Theme.card

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: tabs.profiles

            Rectangle {
                id: tab

                required property var modelData
                required property int index
                readonly property bool selected: index === tabs.currentIndex

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 7
                color: selected ? Theme.surface : tabArea.containsMouse ? Theme.card : "transparent"
                border.color: selected ? Theme.border : "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: tab.modelData.name
                        color: tab.selected ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 13
                        font.weight: tab.selected ? Font.DemiBold : Font.Normal
                    }
                    Text {
                        visible: tab.modelData.fiveHourKnown
                        text: Math.round(tab.modelData.fiveHourUsed) + "%"
                        color: Theme.usageColor(tab.modelData.fiveHourUsed)
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabs.currentIndex = tab.index
                }
            }
        }
    }
}
