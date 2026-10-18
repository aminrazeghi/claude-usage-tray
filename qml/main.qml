import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// The tray popup. `usage` is the UsageWatcher context property from main.cpp.
PopupWindow {
    panelWidth: 320

    GaugePanel { Layout.fillWidth: true }
}
