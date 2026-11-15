import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// App icon, title, plan badge and the pin / collapse buttons.
RowLayout {
    id: header

    property QtObject usage  // UsageWatcher of the selected profile
    property alias pinned: controls.pinned
    signal pinClicked()
    signal collapseClicked()

    spacing: 8

    Image {
        source: "../resources/claude-icon.svg"
        sourceSize: Qt.size(48, 48)
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
    }
    Text {
        Layout.fillWidth: true
        text: "Claude Usage"
        color: Theme.textPrimary
        font.pixelSize: 16
        font.weight: Font.Bold
    }
    Rectangle {
        visible: header.usage.plan !== ""
        implicitWidth: planLabel.implicitWidth + 16
        implicitHeight: 22
        radius: 6
        color: Qt.rgba(0.85, 0.47, 0.34, Theme.dark ? 0.22 : 0.14)

        Text {
            id: planLabel
            anchors.centerIn: parent
            text: header.usage.plan
            color: Theme.claudeOrange
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    WindowControls {
        id: controls
        compact: false
        onPinClicked: header.pinClicked()
        onCompactClicked: header.collapseClicked()
    }
}
