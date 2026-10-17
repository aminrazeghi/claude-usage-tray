import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Frameless popup shown from the tray icon. `usage` is the UsageWatcher
// context property set up in main.cpp.
Window {
    id: root

    readonly property int shadowMargin: 14
    property bool showAvailable: false

    readonly property bool dark: Qt.styleHints.colorScheme !== Qt.ColorScheme.Light
    readonly property color surface: dark ? Qt.rgba(0.13, 0.13, 0.14, 0.92) : Qt.rgba(0.98, 0.98, 0.97, 0.94)
    readonly property color border: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color card: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color textPrimary: dark ? "#F2F2F0" : "#1C1C1E"
    readonly property color textSecondary: dark ? "#9A9A9E" : "#6E6E73"
    readonly property color green: "#34C759"
    readonly property color purple: "#BF5AF2"
    readonly property color claudeOrange: "#D97757"

    width: 300 + 2 * shadowMargin
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
        shadowOpacity: root.dark ? 0.55 : 0.22
        shadowBlur: 0.8
        shadowVerticalOffset: 3
    }

    Rectangle {
        id: panel

        x: root.shadowMargin
        y: root.shadowMargin
        width: root.width - 2 * root.shadowMargin
        implicitHeight: content.implicitHeight + 32
        height: implicitHeight
        radius: 16
        color: root.surface
        border.color: root.border
        border.width: 1

        focus: true
        Keys.onEscapePressed: root.hide()
        Keys.onSpacePressed: root.showAvailable = !root.showAvailable

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
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
                    color: root.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                Rectangle {
                    visible: usage.plan !== ""
                    implicitWidth: planLabel.implicitWidth + 16
                    implicitHeight: 22
                    radius: 6
                    color: Qt.rgba(0.85, 0.47, 0.34, root.dark ? 0.22 : 0.14)

                    Text {
                        id: planLabel
                        anchors.centerIn: parent
                        text: usage.plan
                        color: root.claudeOrange
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }

            CircularGauge {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                Layout.preferredWidth: 172
                Layout.preferredHeight: 172
                innerValue: usage.fiveHourUsed / 100
                outerValue: usage.sevenDayUsed / 100
                hasData: usage.hasData
                showAvailable: root.showAvailable
                innerColor: root.green
                outerColor: root.purple
                trackColor: root.track
                textColor: root.textPrimary
                subTextColor: root.textSecondary
                onClicked: root.showAvailable = !root.showAvailable
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6

                UsageRow {
                    Layout.fillWidth: true
                    color: root.card
                    accent: root.green
                    known: usage.fiveHourKnown
                    badgeValue: Math.round(usage.fiveHourUsed)
                    title: "5-Hour Limit"
                    value: root.showAvailable ? usage.fiveHourLeftText : usage.fiveHourResetText
                    textColor: root.textPrimary
                    subTextColor: root.textSecondary
                }
                UsageRow {
                    Layout.fillWidth: true
                    color: root.card
                    accent: root.purple
                    known: usage.sevenDayKnown
                    badgeValue: Math.round(usage.sevenDayUsed)
                    title: "7-Day Limit"
                    value: root.showAvailable ? usage.sevenDayLeftText : usage.sevenDayResetText
                    textColor: root.textPrimary
                    subTextColor: root.textSecondary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 1
                color: root.border
            }

            // Today's activity, from local Claude Code transcripts.
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 4

                Text {
                    Layout.columnSpan: 2
                    Layout.bottomMargin: 2
                    text: "Today"
                    color: root.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text { text: "Messages"; color: root.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
                Text { text: usage.todayMessages; color: root.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Tokens (in + out)"; color: root.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
                Text { text: usage.todayTokensText; color: root.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.border
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: usage.updatedText + (usage.model ? " · " + usage.model : "")
                    color: root.textSecondary
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: refreshArea.containsMouse ? root.card : "transparent"

                    Text {
                        id: refreshGlyph
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.textPrimary
                        font.pixelSize: 16

                        RotationAnimation on rotation {
                            running: usage.scanning
                            from: 0; to: 360
                            duration: 800
                            loops: Animation.Infinite
                            onStopped: refreshGlyph.rotation = 0
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: usage.refresh()
                    }
                }
            }

            Text {
                visible: !usage.hasData
                Layout.fillWidth: true
                text: "Limits appear after Claude Code's next response. The status line writes them to " + usage.usageFile + "."
                wrapMode: Text.WordWrap
                color: root.textSecondary
                font.pixelSize: 11
            }
        }
    }
}
