import QtQuick
import QtQuick.Layouts

// A rounded card: colored percentage badge, limit name, and a right-aligned value.
Rectangle {
    id: row

    property color accent: "#34C759"
    property int badgeValue: 0
    property bool known: true
    property string title
    property string value
    property color textColor: "#1C1C1E"
    property color subTextColor: "#8E8E93"

    implicitHeight: 36
    radius: 10

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 11
            color: "transparent"
            border.color: row.accent
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: row.known ? row.badgeValue : "–"
                color: row.accent
                font.pixelSize: row.badgeValue >= 100 ? 8 : 10
                font.weight: Font.DemiBold
            }
        }

        Text {
            Layout.fillWidth: true
            text: row.title
            color: row.subTextColor
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Text {
            text: row.value
            color: row.textColor
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
}
