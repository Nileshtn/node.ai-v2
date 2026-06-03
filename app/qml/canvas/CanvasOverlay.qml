import QtQuick

Item {
    id: root

    property Item canvas: null
    property string attachEdge: "right"
    property string snapCorner: "rightBottom"
    property real attachMargin: 12
    property bool isAttached: false
    property bool draggable: true

    signal overlayPressed()
    signal overlayReleased()
    signal overlayMoved(real deltaX, real deltaY)

    width: 120
    height: 80

    function resolveCanvas() {
        var item = parent

        while (item) {
            if (typeof item.attachOverlay === "function") {
                canvas = item
                return
            }

            item = item.parent
        }
    }

    function bringToFront() {
        z = parent ? parent.children.length : 0
    }

    Component.onCompleted: {
        resolveCanvas()

        if (canvas) {
            canvas.attachOverlay(root)
        }
    }

    onParentChanged: resolveCanvas()

    MouseArea {
        id: dragArea

        anchors.fill: parent
        enabled: root.draggable
        acceptedButtons: Qt.LeftButton
        hoverEnabled: root.draggable
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real lastX: 0
        property real lastY: 0
        property bool dragged: false

        onPressed: function(mouse) {
            dragged = false
            lastX = mouse.x
            lastY = mouse.y
            root.bringToFront()

            if (root.canvas) {
                root.canvas.attachOverlay(root)
            }

            root.overlayPressed()
            mouse.accepted = true
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                return
            }

            var deltaX = mouse.x - lastX
            var deltaY = mouse.y - lastY

            if (Math.abs(deltaX) > 0 || Math.abs(deltaY) > 0) {
                dragged = true
            }

            root.x += deltaX
            root.y += deltaY
            lastX = mouse.x
            lastY = mouse.y

            if (root.canvas) {
                root.canvas.clampOverlayPosition(root)
            }

            root.overlayMoved(deltaX, deltaY)
            mouse.accepted = true
        }

        onReleased: function(mouse) {
            if (root.canvas) {
                if (dragged) {
                    root.canvas.snapOverlay(root)
                } else {
                    root.canvas.attachOverlay(root)
                }
            }

            root.overlayReleased()
            mouse.accepted = true
        }
    }
}
