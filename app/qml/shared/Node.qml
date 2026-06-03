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
    signal connectionDragStarted(string socketId, string socketSide, real canvasX, real canvasY)
    signal connectionDragged(real canvasX, real canvasY)
    signal connectionDragFinished(real canvasX, real canvasY)
    signal displayNameEdited(string newDisplayName)
    signal outputLabelsEdited(var labels)

    default property alias bodyContent: bodyColumn.data
    property string defaultTitle: "Node"
    property string displayName: ""
    property var outputLabels: ({})
    readonly property bool showDisplayNameRow: displayName.length > 0
    property string category: ""
    property var inputSockets: []
    property var outputSockets: []
    property bool isSelected: false
    property Item graphCanvas: null
    readonly property int outerMargin: 16
    readonly property AppColors colors: AppColors {}

    function isNodeTextInput(item) {
        return item && item.cursorPosition !== undefined && item.selectByMouse !== undefined
    }

    function outputLabelForSocket(socketId) {
        if (outputLabels && outputLabels[socketId] !== undefined && outputLabels[socketId].length > 0) {
            return outputLabels[socketId]
        }

        return ""
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

        outputLabelsEdited(nextLabels)
        outputLabels = nextLabels
    }

    function deepestChildAt(item, localX, localY) {
        var child = item.childAt(localX, localY)

        if (!child) {
            return item
        }

        var mapped = item.mapToItem(child, localX, localY)
        return deepestChildAt(child, mapped.x, mapped.y)
    }

    function isSocketItem(item) {
        return item && item.socketId !== undefined && typeof item.connectorCanvasPosition === "function"
    }

    function isOverSocketColumns(localX, localY) {
        if (inputSocketColumn.visible) {
            var inputPoint = root.mapToItem(inputSocketColumn, localX, localY)

            if (inputSocketColumn.contains(inputPoint)) {
                return true
            }
        }

        if (outputSocketColumn.visible) {
            var outputPoint = root.mapToItem(outputSocketColumn, localX, localY)

            if (outputSocketColumn.contains(outputPoint)) {
                return true
            }
        }

        return false
    }

    function pickPressTarget(localX, localY) {
        var hit = deepestChildAt(root, localX, localY)

        if (hit !== dragArea) {
            return hit
        }

        for (var i = 0; i < root.children.length; i += 1) {
            var child = root.children[i]

            if (child === dragArea || !child.visible) {
                continue
            }

            var mapped = root.mapToItem(child, localX, localY)

            if (!child.contains(mapped)) {
                continue
            }

            return deepestChildAt(child, mapped.x, mapped.y)
        }

        return hit
    }

    function shouldPassPressToChild(hit) {
        var item = hit

        while (item && item !== root) {
            if (isNodeTextInput(item)) {
                return true
            }

            if (isSocketItem(item)) {
                return true
            }

            if (item.objectName === "socketConnectorDrag") {
                return true
            }

            if (item !== dragArea && typeof item.propagateComposedEvents === "boolean") {
                return true
            }

            item = item.parent
        }

        return false
    }

    function markPassiveBodyLabels(item) {
        for (var i = 0; i < item.children.length; i += 1) {
            var child = item.children[i]

            if (!child) {
                continue
            }

            if (isNodeTextInput(child)) {
                continue
            }

            if (typeof child.propagateComposedEvents === "boolean") {
                markPassiveBodyLabels(child)
                continue
            }

            if (child.font !== undefined && child.selectByMouse === undefined) {
                child.enabled = false
            }

            markPassiveBodyLabels(child)
        }
    }

    function clearTextFocus(item) {
        if (item === undefined) {
            item = root
        }

        for (var i = 0; i < item.children.length; i += 1) {
            var child = item.children[i]

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

    function socketCanvasPosition(socketSide, socketId) {
        var socketColumn = socketSide === "left" ? inputSocketColumn : outputSocketColumn

        if (!graphCanvas) {
            return socketScenePosition(socketSide, socketId)
        }

        for (var i = 0; i < socketColumn.children.length; i += 1) {
            var socketItem = socketColumn.children[i]

            if (socketItem.socketId === socketId && socketItem.connectorCanvasPosition) {
                return socketItem.connectorCanvasPosition()
            }
        }

        return graphCanvas.mapFromItem(root, width / 2, height / 2)
    }

    width: 330
    height: 170
    radius: 6
    color: colors.nodeBackground
    border.color: isSelected ? colors.accent : colors.panelBorder
    border.width: isSelected ? 2 : 1
    clip: false

    Component.onCompleted: markPassiveBodyLabels(bodyColumn)

    HoverHandler {
        id: nodeHover

        onHoveredChanged: root.nodeHoverChanged(hovered)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: outerMargin
        spacing: 8

        ColumnLayout {
            id: headerArea

            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.preferredHeight: root.category.length > 0 ? 14 : 0
                Layout.maximumHeight: root.category.length > 0 ? 14 : 0
                text: root.category
                color: colors.textMuted
                font.pixelSize: 11
                visible: root.category.length > 0
                enabled: false
            }

            Item {
                id: titleRow

                Layout.fillWidth: true
                Layout.preferredHeight: 32

                Label {
                    id: typeTitleLabel

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.defaultTitle
                    color: colors.textMain
                    font.pixelSize: 28
                    enabled: false
                }

            }

            Item {
                id: displayNameRow

                Layout.fillWidth: true
                Layout.preferredHeight: root.showDisplayNameRow ? 14 : 0
                Layout.maximumHeight: root.showDisplayNameRow ? 14 : 0
                visible: root.showDisplayNameRow

                Label {
                    id: displayNameLabel

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    text: root.displayName
                    color: colors.textMuted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    enabled: false
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
                Layout.leftMargin: -outerMargin
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: root.inputSockets

                    NodeSocket {
                        socketId: modelData
                        side: "left"
                        nodeRoot: root

                        onConnectionDragStarted: function(socketId, socketSide, canvasX, canvasY) {
                            root.connectionDragStarted(socketId, socketSide, canvasX, canvasY)
                        }

                        onConnectionDragged: function(canvasX, canvasY) {
                            root.connectionDragged(canvasX, canvasY)
                        }

                        onConnectionDragFinished: function(canvasX, canvasY) {
                            root.connectionDragFinished(canvasX, canvasY)
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

                    onChildrenChanged: root.markPassiveBodyLabels(bodyColumn)
                }
            }

            ColumnLayout {
                id: outputSocketColumn

                visible: root.outputSockets.length > 0
                Layout.preferredWidth: visible ? 96 : 0
                Layout.rightMargin: -outerMargin
                Layout.fillHeight: true
                spacing: 4

                Repeater {
                    model: root.outputSockets

                    NodeSocket {
                        socketId: modelData
                        displayLabel: root.outputLabelForSocket(modelData)
                        side: "right"
                        nodeRoot: root

                        onConnectionDragStarted: function(socketId, socketSide, canvasX, canvasY) {
                            root.connectionDragStarted(socketId, socketSide, canvasX, canvasY)
                        }

                        onConnectionDragged: function(canvasX, canvasY) {
                            root.connectionDragged(canvasX, canvasY)
                        }

                        onConnectionDragFinished: function(canvasX, canvasY) {
                            root.connectionDragFinished(canvasX, canvasY)
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
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        z: 10

        onPressed: function(mouse) {
            var hit = root.pickPressTarget(mouse.x, mouse.y)

            if (root.shouldPassPressToChild(hit) || root.isOverSocketColumns(mouse.x, mouse.y)) {
                mouse.accepted = false
                return
            }

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
