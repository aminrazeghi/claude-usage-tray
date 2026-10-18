pragma Singleton
import QtQuick

// Colors shared by both popups; follows the system light/dark preference.
QtObject {
    readonly property bool dark: Qt.styleHints.colorScheme !== Qt.ColorScheme.Light

    readonly property color surface: dark ? Qt.rgba(0.13, 0.13, 0.14, 0.92) : Qt.rgba(0.98, 0.98, 0.97, 0.94)
    readonly property color border: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color card: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color textPrimary: dark ? "#F2F2F0" : "#1C1C1E"
    readonly property color textSecondary: dark ? "#9A9A9E" : "#6E6E73"

    readonly property color green: "#34C759"
    readonly property color orange: "#FF9F0A"
    readonly property color red: "#FF453A"
    readonly property color purple: "#BF5AF2"
    readonly property color claudeOrange: "#D97757"

    // Same thresholds as the tray icon ring.
    function usageColor(percent) {
        return percent >= 90 ? red : percent >= 75 ? orange : green
    }
}
