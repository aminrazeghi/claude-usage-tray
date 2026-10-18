import QtCore
import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// The tray popup, in full or compact form. `usage` is the UsageWatcher context
// property from main.cpp.
PopupWindow {
    id: window

    property bool compact: false

    panelWidth: compact ? compactPanel.implicitWidth + 2 * padding : 320
    padding: compact ? 10 : 16

    Settings {
        category: "popup"
        property alias compact: window.compact
    }

    Header {
        Layout.fillWidth: true
        visible: !window.compact
        pinned: window.pinned
        onPinClicked: window.pinned = !window.pinned
        onCollapseClicked: window.compact = true
    }

    GaugePanel {
        Layout.fillWidth: true
        visible: !window.compact
    }

    CompactPanel {
        id: compactPanel
        visible: window.compact
        pinned: window.pinned
        onPinClicked: window.pinned = !window.pinned
        onExpandClicked: window.compact = false
    }
}
