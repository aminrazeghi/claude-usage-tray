import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ClaudeUsage

// Frameless, translucent, rounded popup that closes when it loses focus unless
// pinned. Children are laid out in a padded column; drag empty space to move it.
Window {
    id: root

    default property alias content: body.data
    property int panelWidth: 300
    property int padding: 16
    property bool pinned: false
    readonly property int shadowMargin: 14

    // Grow and shrink towards the left so the popup stays against the tray corner.
    property int previousWidth: width
    onWidthChanged: {
        if (visible)
            x += previousWidth - width
        previousWidth = width
    }

    width: panelWidth + 2 * shadowMargin
    height: panel.implicitHeight + 2 * shadowMargin
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: "transparent"
    title: "Claude Usage"
    visible: false

    onActiveChanged: if (!active && visible && !pinned) hide()
    onVisibleChanged: if (visible) usage.refresh()

    MultiEffect {
        source: panel
        anchors.fill: panel
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: Theme.dark ? 0.55 : 0.22
        shadowBlur: 0.8
        shadowVerticalOffset: 3
    }

    Rectangle {
        id: panel

        x: root.shadowMargin
        y: root.shadowMargin
        width: root.panelWidth
        implicitHeight: body.implicitHeight + 2 * root.padding
        height: implicitHeight
        radius: 16
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        focus: true
        Keys.onEscapePressed: root.hide()

        DragHandler {
            target: null
            onActiveChanged: if (active) root.startSystemMove()
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 12
        }
    }
}
