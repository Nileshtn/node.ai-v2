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
    signal connectionDragStarted(string socketId, string socketSide, real sceneX, real sceneY)
    signal connectionDragged(real sceneX, real sceneY)
    signal connectionDragFinished(real sceneX, real sceneY)
    signal displayNameEdited(string newDisplayName)
    signal outputLabelsEdited(var labels)

    default property alias bodyContent: bodyColumn.data
    property string defaultTitle: "Node"
    property string displayName: ""
    property var outputLabels: ({})
    property bool editingDisplayName: false
    property bool editingSocketLabel: false
    readonly property bool renaming: editingDisplayName || editingSocketLabel
    property string category: ""
    property var inputSockets: []
    property var outputSockets: []
    property bool isSelected: false
    readonly property AppColors colors: AppColors {}

    function isNodeTextInput(item) {
        return item && item.cursorPosition !== undefined && item.selectByMouse !== undefined
    }

    function outputLabelForSocket(socketId) {
        if (outputLabels && outputLabels[socketId] !== undefined && outputLabels[socketId].length > 0) {
            return outputLabels[socketId]
        }

        return socketId
    }

    function setOutputLabel(socketId, labelText) {
        var nextLabels = {}

        for (var key in outputLabels) {
            nextLabels[key] = outputLabels[key]
        }

        if (labelText.length > 0) {
            nextLabels[socketId] = labelText
        } else {
            delete nextLabels[socketId]
        }

        outputLabels = nextLabels
        outputLabelsEdited(nextLabels)
    }

    function beginDisplayNameEdit() {
        if (root.editingDisplayName) {
            return
        }

        root.editingDisplayName = true
        displayNameInput.text = root.displayName
        Qt.callLater(function() {
            displayNameInput.forceActiveFocus()
            displayNameInput.selectAll()
        })
    }

    function finishDisplayNameEdit() {
        if (!root.editingDisplayName) {
            return
        }

        root.displayName = displayNameInput.text.trim()
        root.editingDisplayName = false
        displayNameInput.focus = false
        displayNameEdited(root.displayName)
    }

    function clearTextFocus(item) {
        if (root.editingDisplayName) {
            root.finishDisplayNameEdit()
        }

        if (item === undefined) {
            item = root
        }

        for (var i = 0; i < item.children.length; i += 1) {
            var child = item.children[i]

            if (child && child.editingLabel) {
                child.finishLabelEdit()
            }

            if (isNodeTextInput(child) && child.activeFocus) {
                child.focus = false
            }

            clearTextFocus(child)
        }
    }

    function socketScenePosition(socketSide, socketId) {
        var socketColumn = socketSide === "left" ? inputSocketColumn : outputSocketColumn

        for (var i = 0; i < socketColumn.children.length; i += 1) {
            var socketItem = socketColumn.children[i]

            if (socketItem.socketId === socketId) {
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
                text: root.defaultTitle
                color: colors.textMain
                font.pixelSize: 28
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.editingDisplayName ? displayNameInput.implicitHeight : displayNameLabel.implicitHeight

                Label {
                    id: displayNameLabel

                    visible: !root.editingDisplayName
                    text: root.displayName.length > 0 ? root.displayName : "name"
                    color: root.displayName.length > 0 ? colors.textMain : colors.textMuted
                    font.pixelSize: 13
                }

                TextInput {
                    id: displayNameInput

                    visible: root.editingDisplayName
                    text: root.displayName
                    color: colors.textMain
                    font.pixelSize: 13
                    selectByMouse: true
                    maximumLength: 64

                    onEditingFinished: root.finishDisplayNameEdit()

                    Keys.onEscapePressed: {
                        displayNameInput.text = root.displayName
                        root.editingDisplayName = false
                        focus = false
                    }
                }

                TapHandler {
                    enabled: !root.editingDisplayName

                    onDoubleTapped: root.beginDisplayNameEdit()
                }
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
                        socketId: modelData
                        side: "left"
                        nodeRoot: root

                        onConnectionDragStarted: function(socketId, socketSide, sceneX, sceneY) {
                            root.connectionDragStarted(socketId, socketSide, sceneX, sceneY)
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                clip: true

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
                        socketId: modelData
                        displayLabel: root.outputLabelForSocket(modelData)
                        side: "right"
                        labelEditable: true
                        nodeRoot: root

                        onEditingLabelChanged: root.editingSocketLabel = editingLabel

                        onDisplayLabelEdited: function(socketId, newDisplayLabel) {
                            root.setOutputLabel(socketId, newDisplayLabel)
                        }

                        onConnectionDragStarted: function(socketId, socketSide, sceneX, sceneY) {
                            root.connectionDragStarted(socketId, socketSide, sceneX, sceneY)
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

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        z: -1

        onPressed: function(mouse) {
            root.clearTextFocus()
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
