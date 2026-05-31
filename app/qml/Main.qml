import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "canvas"
import "ui"

ApplicationWindow {
    id: root

    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: "Node.ai"

    Shortcut {
        sequence: "Delete"
        onActivated: canvas.deleteSelectedNodes()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: canvas.cancelGraphOperation()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        AppMenuBar {
            Layout.fillWidth: true

            onActionTriggered: function(action) {
                if (action === "View Origin" || action === "View All" || action === "Reset Zoom") {
                    canvas.viewOrigin()
                } else if (action === "Zoom In") {
                    canvas.zoomBy(1.1)
                } else if (action === "Zoom Out") {
                    canvas.zoomBy(0.9)
                } else if (action === "Run" || action === "Debug" || action === "Compute Selected" || action === "Compute Before" || action === "Compute After") {
                    canvas.computeGraph()
                    return
                } else if (action === "Delete") {
                    canvas.deleteSelectedNodes()
                    return
                } else if (action === "Add" || action === "Sub" || action === "Mul" || action === "Button") {
                    canvas.createMathNode(action)
                } else if (action === "Int" || action === "Float" || action === "Vector 2D" || action === "Vector 3D" || action === "Vector 4D" || action === "Bool" || action === "Str") {
                    canvas.createVarNode(action)
                } else if (action === "Lookup") {
                    canvas.createUtilityNode("Lookup")
                }

                infoBar.message = action + " selected"
                infoBar.level = "INFO"
            }
        }

        InfiniteGraphCanvas {
            id: canvas

            Layout.fillWidth: true
            Layout.fillHeight: true

            onGraphComputed: function(message, level) {
                infoBar.message = message
                infoBar.level = level
            }
        }

        InfoBar {
            id: infoBar

            Layout.fillWidth: true
            message: "Canvas ready"
            detail: "Zoom " + Math.round(canvas.zoom * 100) + "%  |  Pan " + Math.round(canvas.offsetX) + ", " + Math.round(canvas.offsetY)
        }
    }
}
