import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Settings view: the second Claude subscription's config folder and tab name.
ColumnLayout {
    id: root

    property QtObject manager  // ProfileManager
    signal closeClicked()

    spacing: 10

    // Fields start from the saved values each time the view opens.
    function reset() {
        dirField.text = manager.secondDir
        nameField.text = manager.secondName
    }
    onVisibleChanged: if (visible) reset()
    Component.onCompleted: reset()

    function apply() {
        manager.setSecondProfile(dirField.text, nameField.text)
    }

    component Field: Rectangle {
        property alias text: input.text
        property alias placeholder: placeholderText.text
        signal accepted()

        Layout.fillWidth: true
        implicitHeight: 32
        radius: 8
        color: Theme.card
        border.color: input.activeFocus ? Theme.claudeOrange : Theme.border

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.textPrimary
            selectionColor: Theme.claudeOrange
            font.pixelSize: 13
            clip: true
            selectByMouse: true
            onAccepted: parent.accepted()
        }
        Text {
            id: placeholderText
            anchors.fill: input
            verticalAlignment: Text.AlignVCenter
            visible: !input.text && !input.activeFocus
            color: Theme.textSecondary
            font.pixelSize: 13
        }
    }

    component Label: Text {
        color: Theme.textSecondary
        font.pixelSize: 12
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "Second account"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        IconButton {
            // Lucide "arrow-left"
            path: "m12 19-7-7 7-7 M19 12H5"
            onClicked: root.closeClicked()
        }
    }

    Label { text: "Claude config folder (empty for none)" }
    Field {
        id: dirField
        placeholder: "~/.claude-work"
        onAccepted: root.apply()
    }

    Label { text: "Tab name (optional)" }
    Field {
        id: nameField
        placeholder: "Derived from the folder"
        onAccepted: root.apply()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            color: root.manager.secondProblem ? Theme.red : Theme.textSecondary
            text: root.manager.secondProblem
                  ? root.manager.secondProblem + ": " + root.manager.secondDir
                  : root.manager.secondDir
                    ? "Showing " + root.manager.profiles.length + " accounts"
                    : "Showing the main account only"
        }

        Rectangle {
            implicitWidth: applyText.implicitWidth + 24
            implicitHeight: 30
            radius: 8
            color: applyArea.containsMouse ? Qt.darker(Theme.claudeOrange, 1.1) : Theme.claudeOrange

            Text {
                id: applyText
                anchors.centerIn: parent
                text: "Apply"
                color: "#FFFFFF"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: applyArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.apply()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 1
        color: Theme.border
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Run Claude Code for that account with CLAUDE_CONFIG_DIR=<folder> claude. "
              + "Its status line is set up when you apply."
    }
}
