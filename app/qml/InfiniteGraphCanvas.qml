import QtQuick
import QtQuick.Controls

Item {
    id: root

    property real zoom: 1.0
    property real minZoom: 0.2
    property real maxZoom: 3.0
    property real offsetX: width / 2
    property real offsetY: height / 2
    readonly property AppColors colors: AppColors {}
    property color backgroundColor: colors.canvasBackground
    property color minorGridColor: colors.gridMinor
    property color majorGridColor: colors.gridMajor
    property color axisGridColor: colors.gridAxis
    property color textColor: colors.textMuted

    clip: true

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function requestGridPaint() {
        gridCanvas.requestPaint()
    }

    function viewOrigin() {
        zoom = 1.0
        offsetX = width / 2
        offsetY = height / 2
        requestGridPaint()
    }

    function zoomBy(factor) {
        var nextZoom = clamp(zoom * factor, minZoom, maxZoom)
        var centerX = width / 2
        var centerY = height / 2
        var worldX = (centerX - offsetX) / zoom
        var worldY = (centerY - offsetY) / zoom

        zoom = nextZoom
        offsetX = centerX - worldX * zoom
        offsetY = centerY - worldY * zoom
        requestGridPaint()
    }

    Canvas {
        id: gridCanvas

        anchors.fill: parent

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.backgroundColor
            ctx.fillRect(0, 0, width, height)

            var minorStep = Math.max(8, 32 * root.zoom)
            var majorStep = minorStep * 5
            var startX = ((root.offsetX % minorStep) + minorStep) % minorStep
            var startY = ((root.offsetY % minorStep) + minorStep) % minorStep
            var majorStartX = ((root.offsetX % majorStep) + majorStep) % majorStep
            var majorStartY = ((root.offsetY % majorStep) + majorStep) % majorStep

            ctx.translate(0.5, 0.5)
            ctx.lineWidth = 1
            ctx.strokeStyle = root.minorGridColor

            for (var x = startX; x < width; x += minorStep) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }

            for (var y = startY; y < height; y += minorStep) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }

            ctx.strokeStyle = root.majorGridColor

            for (var majorX = majorStartX; majorX < width; majorX += majorStep) {
                ctx.beginPath()
                ctx.moveTo(majorX, 0)
                ctx.lineTo(majorX, height)
                ctx.stroke()
            }

            for (var majorY = majorStartY; majorY < height; majorY += majorStep) {
                ctx.beginPath()
                ctx.moveTo(0, majorY)
                ctx.lineTo(width, majorY)
                ctx.stroke()
            }

            ctx.strokeStyle = root.axisGridColor
            ctx.lineWidth = 2

            if (root.offsetX >= 0 && root.offsetX <= width) {
                ctx.beginPath()
                ctx.moveTo(root.offsetX, 0)
                ctx.lineTo(root.offsetX, height)
                ctx.stroke()
            }

            if (root.offsetY >= 0 && root.offsetY <= height) {
                ctx.beginPath()
                ctx.moveTo(0, root.offsetY)
                ctx.lineTo(width, root.offsetY)
                ctx.stroke()
            }
        }
    }

    MouseArea {
        id: panArea

        property real lastX: 0
        property real lastY: 0

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true

        onPressed: function(mouse) {
            lastX = mouse.x
            lastY = mouse.y
            cursorShape = Qt.ClosedHandCursor
        }

        onReleased: {
            cursorShape = Qt.ArrowCursor
        }

        onCanceled: {
            cursorShape = Qt.ArrowCursor
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                return
            }

            root.offsetX += mouse.x - lastX
            root.offsetY += mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y
            root.requestGridPaint()
        }

        onWheel: function(wheel) {
            var oldZoom = root.zoom
            var factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
            var nextZoom = root.clamp(oldZoom * factor, root.minZoom, root.maxZoom)
            var worldX = (wheel.x - root.offsetX) / oldZoom
            var worldY = (wheel.y - root.offsetY) / oldZoom

            root.zoom = nextZoom
            root.offsetX = wheel.x - worldX * root.zoom
            root.offsetY = wheel.y - worldY * root.zoom
            root.requestGridPaint()
            wheel.accepted = true
        }
    }

    Label {
        anchors.centerIn: parent
        text: ""
        color: root.textColor
        font.pixelSize: 28
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        width: 220
        height: 30
        radius: 4
        color: root.colors.overlayBackground
        border.color: root.colors.panelBorder

        Label {
            anchors.centerIn: parent
            color: root.textColor
            text: "Pan: drag  |  Zoom: mouse wheel"
        }
    }
}
