import QtCore
import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// The tray popup, in full or compact form, with a settings view.
// `profileManager` (ProfileManager) is set up in main.cpp.
PopupWindow {
    id: window

    property bool compact: false
    property bool showSettings: false
    // Selected tab; TrayController reads it to pick the tray icon's profile.
    property int currentIndex: 0
    readonly property var allProfiles: profileManager.profiles
    readonly property QtObject usage: allProfiles[Math.max(0, Math.min(currentIndex, allProfiles.length - 1))]

    panelWidth: compact ? compactPanel.implicitWidth + 2 * padding : 320
    padding: compact ? 10 : 16

    onVisibleChanged: {
        if (visible)
            profileManager.refreshAll()
        else
            showSettings = false
    }
    // The second account can be removed in settings.
    onAllProfilesChanged: if (currentIndex >= allProfiles.length) currentIndex = 0


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
        settingsOpen: window.showSettings
        onSettingsClicked: window.showSettings = !window.showSettings
        onPinClicked: window.pinned = !window.pinned
        onCollapseClicked: window.compact = true
    }

    ProfileTabs {
        Layout.fillWidth: true
        visible: !window.compact && !window.showSettings && window.allProfiles.length > 1
        profiles: window.allProfiles
        currentIndex: window.currentIndex
        onCurrentIndexChanged: window.currentIndex = currentIndex
    }

    GaugePanel {
        Layout.fillWidth: true
        visible: !window.compact && !window.showSettings
        usage: window.usage
    }

    SettingsPanel {
        Layout.fillWidth: true
        visible: !window.compact && window.showSettings
        manager: profileManager
        onCloseClicked: window.showSettings = false
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
