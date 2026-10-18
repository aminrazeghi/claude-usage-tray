import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// A rounded card for one limit window: icon in an accent-colored ring, name and
// percentage, and the reset time. Click the reset time to see the time left.
Rectangle {
    id: row

    property color accent: Theme.green
    property url icon
    property string title
    property bool known: true
    property real percent: 0
    property string resetText   // "Today 9:00 PM"
    property string leftText    // "1h 6m left"
    property bool showLeft: false

    implicitHeight: 38
    radius: 10
    color: Theme.card

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 12
            color: "transparent"
            border.color: row.accent
            border.width: 2

            Image {
                anchors.centerIn: parent
                source: row.icon
                sourceSize: Qt.size(28, 28)
                width: 14
                height: 14
            }
        }

        Text {
            text: row.title
            color: Theme.textSecondary
            font.pixelSize: 13
        }

        Text {
            visible: row.known
            text: Math.round(row.percent) + "%"
            color: row.accent
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        Text {
            text: row.showLeft ? row.leftText : row.resetText
            color: valueArea.containsMouse ? row.accent : Theme.textPrimary
            font.pixelSize: 13
            font.weight: Font.DemiBold

            MouseArea {
                id: valueArea
                anchors.fill: parent
                anchors.margins: -6   // easier to hit
                enabled: row.known
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.showLeft = !row.showLeft
            }
        }
    }
}
