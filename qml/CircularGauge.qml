import QtQuick
import QtQuick.Shapes

// Two concentric arcs: a thin outer ring (7-day limit) and a thick inner ring
// (5-hour limit). Clicking toggles between showing used and available capacity;
// in "available" mode each arc sweeps over to cover the unused part of its ring.
Item {
    id: gauge

    property real innerValue: 0      // 0..1, 5-hour usage
    property real outerValue: 0      // 0..1, 7-day usage
    property bool showAvailable: false
    property bool hasData: true

    property color innerColor: "#34C759"
    property color outerColor: "#BF5AF2"
    property color trackColor: "#E5E5E5"
    property color textColor: "#1C1C1E"
    property color subTextColor: "#8E8E93"

    property real outerWidth: 5
    property real innerWidth: 15
    property real ringGap: 6

    signal clicked()

    implicitWidth: 172
    implicitHeight: 172

    readonly property real size: Math.min(width, height)
    readonly property real outerRadius: size / 2 - outerWidth / 2 - 1
    readonly property real innerRadius: outerRadius - outerWidth / 2 - ringGap - innerWidth / 2

    // Each arc is a [start, end] span in turns, measured clockwise from 12 o'clock.
    // Animating both ends makes the arc slide around to the complementary segment.
    property real innerStart: showAvailable ? innerValue : 0
    property real innerEnd: showAvailable ? 1 : innerValue
    property real outerStart: showAvailable ? outerValue : 0
    property real outerEnd: showAvailable ? 1 : outerValue

    Behavior on innerStart { NumberAnimation { duration: 650; easing.type: Easing.InOutCubic } }
    Behavior on innerEnd { NumberAnimation { duration: 650; easing.type: Easing.InOutCubic } }
    Behavior on outerStart { NumberAnimation { duration: 750; easing.type: Easing.InOutCubic } }
    Behavior on outerEnd { NumberAnimation { duration: 750; easing.type: Easing.InOutCubic } }

    property real shownPercent: Math.round((showAvailable ? 1 - innerValue : innerValue) * 100)
    Behavior on shownPercent { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

    component Ring: Shape {
        id: ring
        property real radius
        property real lineWidth
        property color color
        property real from: 0
        property real to: 1

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // A zero-length arc with round caps would still draw a dot.
        visible: to - from > 0.001

        ShapePath {
            strokeColor: ring.color
            strokeWidth: ring.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: gauge.width / 2
                centerY: gauge.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90 + ring.from * 360
                sweepAngle: (ring.to - ring.from) * 360
            }
        }
    }

    Item {
        id: dial
        anchors.fill: parent
        scale: tap.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }

        Ring { radius: gauge.outerRadius; lineWidth: gauge.outerWidth; color: gauge.trackColor; to: 0.9999 }
        Ring { radius: gauge.innerRadius; lineWidth: gauge.innerWidth; color: gauge.trackColor; to: 0.9999 }

        Ring {
            radius: gauge.outerRadius; lineWidth: gauge.outerWidth; color: gauge.outerColor
            from: gauge.outerStart; to: gauge.outerEnd
        }
        Ring {
            radius: gauge.innerRadius; lineWidth: gauge.innerWidth; color: gauge.innerColor
            from: gauge.innerStart; to: gauge.innerEnd
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.hasData ? Math.round(gauge.shownPercent) + "%" : "—"
                color: gauge.textColor
                font.pixelSize: 38
                font.weight: Font.Bold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.hasData ? (gauge.showAvailable ? "Available" : "Used") : "No data"
                color: gauge.subTextColor
                font.pixelSize: 12
            }
        }
    }

    MouseArea {
        id: tap
        // Only the disc reacts, not the square's corners.
        anchors.centerIn: parent
        width: gauge.size
        height: gauge.size
        cursorShape: Qt.PointingHandCursor
        onClicked: gauge.clicked()
    }
}
