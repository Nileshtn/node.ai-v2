import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    signal connectionDragStarted(string socketId, string socketSide, real sceneX, real sceneY)
    signal connectionDragged(real sceneX, real sceneY)
    signal connectionDragFinished(real sceneX, real sceneY)
    signal displayLabelEdited(string socketId, string newDisplayLabel)

    property string socketId: ""
    property string displayLabel: ""
    property string side: "left"
    property bool labelEditable: false
    property bool editingLabel: false
    property Item nodeRoot: null
    property real nodeEdgeInset: 20
    readonly property string shownLabel: displayLabel.length > 0 ? displayLabel : socketId
    readonly property AppColors colors: AppColors {}

    width: 96
    height: 26

    function connectorScenePosition() {
        return socketDot.mapToItem(null, socketDot.width / 2, socketDot.height / 2)
    }

    function beginLabelEdit() {
        if (!labelEditable || editingLabel) {
            return
        }

        editingLabel = true
        labelInput.text = displayLabel.length > 0 ? displayLabel : socketId
        Qt.callLater(function() {
            labelInput.forceActiveFocus()
            labelInput.selectAll()
        })
    }

    function finishLabelEdit() {
        if (!editingLabel) {
            return
        }

        var nextLabel = labelInput.text.trim()
        var resolved = nextLabel.length > 0 && nextLabel !== socketId ? nextLabel : ""

        editingLabel = false
        labelInput.focus = false
        displayLabelEdited(socketId, resolved)
    }

    Rectangle {
        id: socketDot

        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: root.side === "left" ? -root.nodeEdgeInset - width / 2 : root.width + root.nodeEdgeInset - width / 2
        color: colors.nodeSocket
        border.color: colors.nodeBackground
        border.width: 1
    }

    MouseArea {
        id: socketMouseArea

        x: Math.min(0, socketDot.x)
        y: 0
        width: Math.max(root.width, socketDot.x + socketDot.width) - x
        height: root.height
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        z: editingLabel ? -1 : 0

        onPressed: function(mouse) {
            var point = root.connectorScenePosition()
            root.connectionDragStarted(root.socketId, root.side, point.x, point.y)
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
        id: socketLabel

        visible: !root.editingLabel
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.side === "left" ? socketDot.right : parent.left
        anchors.right: root.side === "right" ? socketDot.left : parent.right
        anchors.leftMargin: root.side === "left" ? 8 : 0
        anchors.rightMargin: root.side === "right" ? 8 : 0
        text: root.shownLabel
        color: colors.textMain
        font.pixelSize: 14
        horizontalAlignment: root.side === "left" ? Text.AlignLeft : Text.AlignRight
    }

    TextInput {
        id: labelInput

        visible: root.editingLabel
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: socketLabel.left
        anchors.right: socketLabel.right
        color: colors.textMain
        font.pixelSize: 14
        horizontalAlignment: socketLabel.horizontalAlignment
        selectByMouse: true
        maximumLength: 32

        onEditingFinished: root.finishLabelEdit()

        Keys.onEscapePressed: {
            root.editingLabel = false
            focus = false
        }
    }

    TapHandler {
        enabled: root.labelEditable && !root.editingLabel

        onDoubleTapped: root.beginLabelEdit()
    }
}
