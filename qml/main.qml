import QtQuick
import QtQuick.Layouts
import ClaudeUsage

// Root object: the two tray popups. main.cpp reads `detailsWindow` and
// `gaugeWindow`; `usage` is the UsageWatcher context property.
QtObject {
    id: root

    property PopupWindow detailsWindow: PopupWindow {
        panelWidth: 320

        DetailsPanel {
            Layout.fillWidth: true
            onShowGaugeRequested: {
                // Open the gauge where the details panel was, aligned to its right edge.
                const details = root.detailsWindow
                const gauge = root.gaugeWindow
                gauge.x = details.x + details.width - gauge.width
                gauge.y = details.y
                details.hide()
                gauge.show()
                gauge.raise()
                gauge.requestActivate()
            }
        }
    }

    property PopupWindow gaugeWindow: PopupWindow {
        panelWidth: 300

        GaugePanel { Layout.fillWidth: true }
    }
}
