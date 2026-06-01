import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    signal selected(bool additiveSelection)
    signal deleteRequested()
    signal nodeHoverChanged(bool hovered)
    signal moved(real screenDeltaX, real screenDeltaY)
    signal connectionDragStarted(string socketLabel, string socketSide, real sceneX, real sceneY)
    signal connectionDragged(real sceneX, real sceneY)
    signal connectionDragFinished(real sceneX, real sceneY)

    default property alias bodyContent: bodyColumn.data
    property string title: "Node"
    property string category: ""
    property var inputSockets: []
    property var outputSockets: []
    property bool isSelected: false
    readonly property AppColors colors: AppColors {}

    function socketScenePosition(socketSide, socketLabel) {
        var socketColumn = socketSide === "left" ? inputSocketColumn : outputSocketColumn

        for (var i = 0; i < socketColumn.children.length; i += 1) {
            var socketItem = socketColumn.children[i]

            if (socketItem.label === socketLabel) {
                return socketItem.connectorScenePosition()
            }
        }

        return mapToItem(null, width / 2, height / 2)
    }

    width: 330
    height: 170
    radius: 6
    color: colors.nodeBackground
    border.color: isSelected ? colors.accent : colors.panelBorder
    border.width: isSelected ? 2 : 1
    clip: false

    HoverHandler {
        id: nodeHover

        onHoveredChanged: root.nodeHoverChanged(hovered)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        ColumnLayout {
            id: headerArea

            Layout.fillWidth: true
            spacing: 1

            Label {
                text: root.category
                color: colors.textMuted
                font.pixelSize: 11
                visible: root.category.length > 0
            }

            Label {
                text: root.title
                color: colors.textMain
                font.pixelSize: 28
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                id: inputSocketColumn

                visible: root.inputSockets.length > 0
                Layout.preferredWidth: visible ? 96 : 0
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: root.inputSockets

                    NodeSocket {
                        label: modelData
                        side: "left"

                        onConnectionDragStarted: function(socketLabel, socketSide, sceneX, sceneY) {
                            root.connectionDragStarted(socketLabel, socketSide, sceneX, sceneY)
                        }

                        onConnectionDragged: function(sceneX, sceneY) {
                            root.connectionDragged(sceneX, sceneY)
                        }

                        onConnectionDragFinished: function(sceneX, sceneY) {
                            root.connectionDragFinished(sceneX, sceneY)
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: bodyColumn

                    width: parent.width
                    spacing: 4
                }
            }

            ColumnLayout {
                id: outputSocketColumn

                visible: root.outputSockets.length > 0
                Layout.preferredWidth: visible ? 96 : 0
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: root.outputSockets

                    NodeSocket {
                        label: modelData
                        side: "right"

                        onConnectionDragStarted: function(socketLabel, socketSide, sceneX, sceneY) {
                            root.connectionDragStarted(socketLabel, socketSide, sceneX, sceneY)
                        }

                        onConnectionDragged: function(sceneX, sceneY) {
                            root.connectionDragged(sceneX, sceneY)
                        }

                        onConnectionDragFinished: function(sceneX, sceneY) {
                            root.connectionDragFinished(sceneX, sceneY)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: dragArea

        property real lastSceneX: 0
        property real lastSceneY: 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 20
        height: headerArea.implicitHeight
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        z: 10

        onPressed: function(mouse) {
            var point = mapToItem(null, mouse.x, mouse.y)
            lastSceneX = point.x
            lastSceneY = point.y
            root.selected((mouse.modifiers & Qt.ControlModifier) !== 0)
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                return
            }

            var point = mapToItem(null, mouse.x, mouse.y)
            root.moved(point.x - lastSceneX, point.y - lastSceneY)
            lastSceneX = point.x
            lastSceneY = point.y
        }
    }
}
