import QtQuick
import QtQuick.Shapes
import ClaudeUsage

// Round icon button drawn from a 24×24 SVG path, so it follows the theme colors.
Rectangle {
    id: button

    property string path
    property bool checked: false
    signal clicked()

    implicitWidth: 26
    implicitHeight: 26
    radius: 13
    color: area.containsMouse || checked ? Theme.card : "transparent"

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: 16 / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: button.checked ? Theme.claudeOrange
                       : area.containsMouse ? Theme.textPrimary : Theme.textSecondary
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: button.path }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
