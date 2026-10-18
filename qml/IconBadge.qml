import QtQuick

// A limit's icon inside a ring of its gauge color.
Rectangle {
    property color accent
    property url icon

    implicitWidth: 24
    implicitHeight: 24
    radius: width / 2
    color: "transparent"
    border.color: accent
    border.width: 2

    Image {
        anchors.centerIn: parent
        source: parent.icon
        sourceSize: Qt.size(28, 28)
        width: parent.width * 0.58
        height: width
    }
}
