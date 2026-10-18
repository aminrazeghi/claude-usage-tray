import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ClaudeUsage

// Frameless, translucent, rounded popup that closes when it loses focus.
// Children are laid out in a padded column.
Window {
    id: root

    default property alias content: body.data
    property int panelWidth: 300
    readonly property int shadowMargin: 14

    width: panelWidth + 2 * shadowMargin
    height: panel.implicitHeight + 2 * shadowMargin
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: "transparent"
    title: "Claude Usage"
    visible: false

    onActiveChanged: if (!active && visible) hide()
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
        implicitHeight: body.implicitHeight + 32
        height: implicitHeight
        radius: 16
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        focus: true
        Keys.onEscapePressed: root.hide()

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
        }
    }
}
