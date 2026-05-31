import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    signal connectionDragStarted(string socketLabel, string socketSide, real sceneX, real sceneY)
    signal connectionDragged(real sceneX, real sceneY)
    signal connectionDragFinished(real sceneX, real sceneY)

    property string label: ""
    property string side: "left"
    readonly property AppColors colors: AppColors {}

    width: 96
    height: 26

    function connectorScenePosition() {
        return socketDot.mapToItem(null, socketDot.width / 2, socketDot.height / 2)
    }

    Rectangle {
        id: socketDot

        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: root.side === "left" ? -6 : root.width - 6
        color: colors.nodeSocket
        border.color: colors.nodeBackground
        border.width: 1
    }

    MouseArea {
        id: socketMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true

        onPressed: function(mouse) {
            var point = root.connectorScenePosition()
            root.connectionDragStarted(root.label, root.side, point.x, point.y)
            mouse.accepted = true
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                return
            }

            var point = root.mapToItem(null, mouse.x, mouse.y)
            root.connectionDragged(point.x, point.y)
        }

        onReleased: function(mouse) {
            var point = root.mapToItem(null, mouse.x, mouse.y)
            root.connectionDragFinished(point.x, point.y)
        }
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.side === "left" ? socketDot.right : parent.left
        anchors.right: root.side === "right" ? socketDot.left : parent.right
        anchors.leftMargin: root.side === "left" ? 8 : 0
        anchors.rightMargin: root.side === "right" ? 8 : 0
        text: root.label
        color: colors.textMain
        font.pixelSize: 14
        horizontalAlignment: root.side === "left" ? Text.AlignLeft : Text.AlignRight
    }
}
