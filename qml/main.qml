import QtCore
import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// The tray popup, in full or compact form. `profiles` is the list of
// UsageWatchers (one per Claude config directory) set up in main.cpp.
PopupWindow {
    id: window

    property bool compact: false
    // Selected tab; TrayController reads it to pick the tray icon's profile.
    property int currentIndex: 0
    // Children can't read the `profiles` context property by that name: their
    // own `profiles` property would shadow it.
    readonly property var allProfiles: profiles
    readonly property QtObject usage: allProfiles[Math.max(0, Math.min(currentIndex, allProfiles.length - 1))]

    panelWidth: compact ? compactPanel.implicitWidth + 2 * padding : 320
    padding: compact ? 10 : 16

    onVisibleChanged: {
        if (visible)
            allProfiles.forEach(p => p.refresh())
    }

    Settings {
        category: "popup"
        property alias compact: window.compact
        property alias currentIndex: window.currentIndex
    }

    Header {
        Layout.fillWidth: true
        visible: !window.compact
        usage: window.usage
        pinned: window.pinned
        onPinClicked: window.pinned = !window.pinned
        onCollapseClicked: window.compact = true
    }

    ProfileTabs {
        Layout.fillWidth: true
        visible: !window.compact && window.allProfiles.length > 1
        profiles: window.allProfiles
        currentIndex: window.currentIndex
        onCurrentIndexChanged: window.currentIndex = currentIndex
    }

    GaugePanel {
        Layout.fillWidth: true
        visible: !window.compact
        usage: window.usage
    }

    CompactPanel {
        id: compactPanel
        visible: window.compact
        profiles: window.allProfiles
        pinned: window.pinned
        onPinClicked: window.pinned = !window.pinned
        onExpandClicked: window.compact = false
    }
}
