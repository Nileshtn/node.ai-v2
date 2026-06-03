import QtQuick
import "../theme"

Item {
    id: root

    default property alias canvasContent: contentLayer.data

    property alias overlayHost: overlayLayer

    signal viewportChanged()

    signal canvasPressed(var mouse)
    signal canvasReleased(var mouse)
    signal canvasPanned(real deltaX, real deltaY, var mouse)

    property real zoom: 1.0
    property real minZoom: 0.2
    property real maxZoom: 3.0
    property real offsetX: width / 2
    property real offsetY: height / 2
    property real overlayAttachMargin: 12
    property bool panEnabled: true
    property bool gridEnabled: true
    readonly property AppColors colors: AppColors {}
    property color backgroundColor: colors.canvasBackground
    property color minorGridColor: colors.gridMinor
    property color majorGridColor: colors.gridMajor
    property color axisGridColor: colors.gridAxis

    clip: true

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function requestGridPaint() {
        gridCanvas.requestPaint()
    }

    function visibleCenterWorldPosition() {
        return {
            "x": (width / 2 - offsetX) / zoom,
            "y": (height / 2 - offsetY) / zoom
        }
    }

    function canvasToWorld(canvasX, canvasY) {
        return {
            "x": (canvasX - offsetX) / zoom,
            "y": (canvasY - offsetY) / zoom
        }
    }

    function worldToCanvas(worldX, worldY) {
        return {
            "x": offsetX + worldX * zoom,
            "y": offsetY + worldY * zoom
        }
    }

    function scenePointToCanvas(sceneX, sceneY) {
        return mapFromItem(null, sceneX, sceneY)
    }

    function viewportSnapshot() {
        return {
            "zoom": zoom,
            "offsetX": offsetX,
            "offsetY": offsetY
        }
    }

    function applyViewport(view) {
        if (!view) {
            viewOrigin()
            return
        }

        zoom = view.zoom === undefined ? 1.0 : view.zoom
        offsetX = view.offsetX === undefined ? width / 2 : view.offsetX
        offsetY = view.offsetY === undefined ? height / 2 : view.offsetY
        requestGridPaint()
        viewportChanged()
    }

    function viewOrigin() {
        zoom = 1.0
        offsetX = width / 2
        offsetY = height / 2
        requestGridPaint()
        viewportChanged()
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
        viewportChanged()
    }

    function clampOverlayY(overlay) {
        var margin = overlayAttachMarginFor(overlay)

        return clamp(overlay.y, margin, Math.max(margin, height - overlay.height - margin))
    }

    function overlayAttachMarginFor(overlay) {
        return overlay.attachMargin === undefined ? overlayAttachMargin : overlay.attachMargin
    }

    function attachOverlay(overlay) {
        if (!overlay) {
            return
        }

        var margin = overlayAttachMarginFor(overlay)
        var edge = overlay.attachEdge === undefined ? "right" : overlay.attachEdge

        if (edge === "right") {
            overlay.x = width - overlay.width - margin
        } else if (edge === "left") {
            overlay.x = margin
        } else if (edge === "top") {
            overlay.y = margin
        } else if (edge === "bottom") {
            overlay.y = height - overlay.height - margin
        }

        if (edge === "right" || edge === "left") {
            overlay.y = clampOverlayY(overlay)
        }

        overlay.isAttached = true
    }

    function snapOverlay(overlay) {
        if (!overlay) {
            return
        }

        var margin = overlayAttachMarginFor(overlay)
        var corner = overlay.snapCorner === undefined ? "rightBottom" : overlay.snapCorner

        if (corner === "rightBottom") {
            overlay.x = width - overlay.width - margin
            overlay.y = height - overlay.height - margin
        } else if (corner === "rightTop") {
            overlay.x = width - overlay.width - margin
            overlay.y = margin
        } else if (corner === "leftBottom") {
            overlay.x = margin
            overlay.y = height - overlay.height - margin
        } else if (corner === "leftTop") {
            overlay.x = margin
            overlay.y = margin
        }

        overlay.isAttached = true
    }

    function clampOverlayPosition(overlay) {
        if (!overlay) {
            return
        }

        var margin = overlayAttachMarginFor(overlay)

        overlay.x = clamp(overlay.x, margin, Math.max(margin, width - overlay.width - margin))
        overlay.y = clamp(overlay.y, margin, Math.max(margin, height - overlay.height - margin))
    }

    function repositionAttachedOverlays() {
        for (var i = 0; i < overlayLayer.children.length; i += 1) {
            var overlay = overlayLayer.children[i]

            if (overlay && overlay.isAttached) {
                attachOverlay(overlay)
            }
        }
    }

    onWidthChanged: if (overlayLayer.children.length > 0) repositionAttachedOverlays()
    onHeightChanged: if (overlayLayer.children.length > 0) repositionAttachedOverlays()

    Rectangle {
        id: solidBackground

        anchors.fill: parent
        z: 0
        visible: !root.gridEnabled
        color: root.backgroundColor
    }

    Canvas {
        id: gridCanvas

        anchors.fill: parent
        z: 0
        visible: root.gridEnabled

        Component.onCompleted: requestPaint()
        onWidthChanged: if (root.gridEnabled) requestPaint()
        onHeightChanged: if (root.gridEnabled) requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.backgroundColor
            ctx.fillRect(0, 0, width, height)

            if (!root.gridEnabled) {
                return
            }

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
        z: 0
        enabled: root.panEnabled
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true

        onPressed: function(mouse) {
            if (!root.panEnabled) {
                return
            }

            lastX = mouse.x
            lastY = mouse.y

            if (mouse.button !== Qt.RightButton) {
                cursorShape = Qt.ClosedHandCursor
            }

            root.canvasPressed(mouse)
        }

        onReleased: function(mouse) {
            cursorShape = Qt.ArrowCursor
            root.canvasReleased(mouse)
        }

        onCanceled: {
            cursorShape = Qt.ArrowCursor
        }

        onPositionChanged: function(mouse) {
            if (!pressed || !root.panEnabled) {
                return
            }

            var deltaX = mouse.x - lastX
            var deltaY = mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y

            if ((mouse.buttons & Qt.RightButton) !== 0) {
                root.canvasPanned(deltaX, deltaY, mouse)
                return
            }

            root.offsetX += deltaX
            root.offsetY += deltaY
            root.requestGridPaint()
            root.viewportChanged()
            root.canvasPanned(deltaX, deltaY, mouse)
        }

        onWheel: function(wheel) {
            if (!root.panEnabled) {
                return
            }

            var oldZoom = root.zoom
            var factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
            var nextZoom = root.clamp(oldZoom * factor, root.minZoom, root.maxZoom)
            var worldX = (wheel.x - root.offsetX) / oldZoom
            var worldY = (wheel.y - root.offsetY) / oldZoom

            root.zoom = nextZoom
            root.offsetX = wheel.x - worldX * root.zoom
            root.offsetY = wheel.y - worldY * root.zoom
            root.requestGridPaint()
            root.viewportChanged()
            wheel.accepted = true
        }
    }

    Item {
        id: contentLayer

        anchors.fill: parent
        z: 1
    }

    Item {
        id: overlayLayer

        anchors.fill: parent
        z: 3
    }
}
