import QtQuick
import ClaudeUsage

// Round "↻" button that spins while the transcript scan runs.
Rectangle {
    implicitWidth: 26
    implicitHeight: 26
    radius: 13
    color: area.containsMouse ? Theme.card : "transparent"

    Text {
        id: glyph
        anchors.centerIn: parent
        text: "↻"
        color: Theme.textPrimary
        font.pixelSize: 16

        RotationAnimation on rotation {
            running: usage.scanning
            from: 0; to: 360
            duration: 800
            loops: Animation.Infinite
            onStopped: glyph.rotation = 0
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: usage.refresh()
    }
}
