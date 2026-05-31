import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root

    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: "Node.ai"

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
                }

                infoBar.message = action + " selected"
            }
        }

        InfiniteGraphCanvas {
            id: canvas

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        InfoBar {
            id: infoBar

            Layout.fillWidth: true
            message: "Canvas ready"
            detail: "Zoom " + Math.round(canvas.zoom * 100) + "%  |  Pan " + Math.round(canvas.offsetX) + ", " + Math.round(canvas.offsetY)
        }
    }
}
