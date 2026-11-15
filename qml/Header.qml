import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// App icon, title, plan badge and the settings / pin / collapse buttons.
RowLayout {
    id: header

    property QtObject usage  // UsageWatcher of the selected profile
    property alias pinned: controls.pinned
    property bool settingsOpen: false
    signal settingsClicked()
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

    IconButton {
        Layout.leftMargin: -6  // tighten towards the pin / collapse pair
        // Lucide "settings"
        path: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"
        checked: header.settingsOpen
        onClicked: header.settingsClicked()
    }

    WindowControls {
        id: controls
        compact: false
        onPinClicked: header.pinClicked()
        onCompactClicked: header.collapseClicked()
    }
}
