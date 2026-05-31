import QtQuick
import QtQuick.Controls
import "../nodes/math"
import "../nodes/utility"
import "../nodes/values"
import "../theme"

Item {
    id: root

    signal graphComputed(string message, string level)

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
    property int selectedNodeIndex: -1
    property var selectedNodeIndices: []
    property bool isConnecting: false
    property int connectionSourceNodeIndex: -1
    property string connectionSourceSocket: ""
    property string connectionSourceSide: "right"
    property real connectionStartX: 0
    property real connectionStartY: 0
    property real connectionEndX: 0
    property real connectionEndY: 0
    property bool isCuttingConnections: false
    property var connectionCutPoints: []

    clip: true

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function requestGridPaint() {
        gridCanvas.requestPaint()
    }

    function requestConnectionPaint() {
        connectionCanvas.requestPaint()
    }

    function visibleCenterWorldPosition() {
        return {
            "x": (width / 2 - offsetX) / zoom,
            "y": (height / 2 - offsetY) / zoom
        }
    }

    function isNodeSelected(nodeIndex) {
        return selectedNodeIndices.indexOf(nodeIndex) >= 0
    }

    function selectNode(nodeIndex, additiveSelection) {
        if (!additiveSelection) {
            selectedNodeIndices = [nodeIndex]
            selectedNodeIndex = nodeIndex
            return
        }

        var nextSelection = selectedNodeIndices.slice()
        var existingIndex = nextSelection.indexOf(nodeIndex)

        if (existingIndex >= 0) {
            nextSelection.splice(existingIndex, 1)
        } else {
            nextSelection.push(nodeIndex)
        }

        selectedNodeIndices = nextSelection
        selectedNodeIndex = nextSelection.length > 0 ? nextSelection[nextSelection.length - 1] : -1
    }

    function clearSelection() {
        selectedNodeIndices = []
        selectedNodeIndex = -1
    }

    function createMathNode(nodeType) {
        var center = visibleCenterWorldPosition()

        graphNodes.append({
            "type": nodeType,
            "worldX": center.x,
            "worldY": center.y,
            "value": 0,
            "displayValue": ""
        })
        selectNode(graphNodes.count - 1, false)
        requestConnectionPaint()
    }

    function createVarNode(nodeType) {
        var center = visibleCenterWorldPosition()

        graphNodes.append({
            "type": nodeType,
            "worldX": center.x,
            "worldY": center.y,
            "value": 0,
            "displayValue": ""
        })
        selectNode(graphNodes.count - 1, false)
        requestConnectionPaint()
    }

    function createUtilityNode(nodeType) {
        var center = visibleCenterWorldPosition()

        graphNodes.append({
            "type": nodeType,
            "worldX": center.x,
            "worldY": center.y,
            "value": 0,
            "displayValue": "No value connected"
        })
        selectNode(graphNodes.count - 1, false)
        requestConnectionPaint()
    }

    function deleteSelectedNodes() {
        if (selectedNodeIndices.length === 0) {
            graphComputed("No selected nodes to delete", "INFO")
            return
        }

        var selectedLookup = {}

        for (var selectionIndex = 0; selectionIndex < selectedNodeIndices.length; selectionIndex += 1) {
            selectedLookup[selectedNodeIndices[selectionIndex]] = true
        }

        var indexMap = {}
        var nextNodeIndex = 0

        for (var nodeIndex = 0; nodeIndex < graphNodes.count; nodeIndex += 1) {
            if (!selectedLookup[nodeIndex]) {
                indexMap[nodeIndex] = nextNodeIndex
                nextNodeIndex += 1
            }
        }

        var nextConnections = []

        for (var connectionIndex = 0; connectionIndex < graphConnections.count; connectionIndex += 1) {
            var connection = graphConnections.get(connectionIndex)

            if (selectedLookup[connection.sourceNodeIndex] || selectedLookup[connection.targetNodeIndex]) {
                continue
            }

            nextConnections.push({
                "sourceNodeIndex": indexMap[connection.sourceNodeIndex],
                "sourceSocket": connection.sourceSocket,
                "targetNodeIndex": indexMap[connection.targetNodeIndex],
                "targetSocket": connection.targetSocket
            })
        }

        for (var removeIndex = graphNodes.count - 1; removeIndex >= 0; removeIndex -= 1) {
            if (selectedLookup[removeIndex]) {
                graphNodes.remove(removeIndex)
            }
        }

        graphConnections.clear()

        for (var nextConnectionIndex = 0; nextConnectionIndex < nextConnections.length; nextConnectionIndex += 1) {
            graphConnections.append(nextConnections[nextConnectionIndex])
        }

        var deletedCount = selectedNodeIndices.length
        clearSelection()
        computeGraph()
        requestConnectionPaint()
        graphComputed("Deleted " + deletedCount + (deletedCount === 1 ? " node" : " nodes"), "INFO")
    }

    function scenePointToCanvas(sceneX, sceneY) {
        return mapFromItem(null, sceneX, sceneY)
    }

    function socketCanvasPosition(nodeIndex, socketSide, socketLabel) {
        var nodeDelegate = nodeRepeater.itemAt(nodeIndex)

        if (!nodeDelegate || !nodeDelegate.nodeItem) {
            return null
        }

        var scenePoint = nodeDelegate.nodeItem.socketScenePosition(socketSide, socketLabel)
        return scenePointToCanvas(scenePoint.x, scenePoint.y)
    }

    function resetLookupValue(nodeIndex) {
        var node = graphNodes.get(nodeIndex)

        if (node && node.type === "Lookup") {
            graphNodes.setProperty(nodeIndex, "displayValue", "No value connected")
        }
    }

    function removeConnectionAt(connectionIndex) {
        var connection = graphConnections.get(connectionIndex)

        resetLookupValue(connection.targetNodeIndex)
        graphConnections.remove(connectionIndex)
        computeGraph()
    }

    function removeConnectionsForInput(nodeIndex, socketLabel) {
        for (var connectionIndex = graphConnections.count - 1; connectionIndex >= 0; connectionIndex -= 1) {
            var connection = graphConnections.get(connectionIndex)

            if (connection.targetNodeIndex === nodeIndex && connection.targetSocket === socketLabel) {
                resetLookupValue(connection.targetNodeIndex)
                graphConnections.remove(connectionIndex)
            }
        }
    }

    function detachFromOutput(nodeIndex, socketLabel) {
        for (var connectionIndex = graphConnections.count - 1; connectionIndex >= 0; connectionIndex -= 1) {
            var connection = graphConnections.get(connectionIndex)

            if (connection.sourceNodeIndex === nodeIndex && connection.sourceSocket === socketLabel) {
                removeConnectionAt(connectionIndex)
            }
        }
    }

    function detachFromInput(nodeIndex, socketLabel) {
        for (var connectionIndex = graphConnections.count - 1; connectionIndex >= 0; connectionIndex -= 1) {
            var connection = graphConnections.get(connectionIndex)

            if (connection.targetNodeIndex === nodeIndex && connection.targetSocket === socketLabel) {
                var sourcePoint = socketCanvasPosition(connection.sourceNodeIndex, "right", connection.sourceSocket)

                connectionSourceNodeIndex = connection.sourceNodeIndex
                connectionSourceSocket = connection.sourceSocket
                removeConnectionAt(connectionIndex)
                return sourcePoint
            }
        }

        return null
    }

    function startConnection(nodeIndex, socketLabel, socketSide, sceneX, sceneY) {
        var canvasPoint = scenePointToCanvas(sceneX, sceneY)

        if (socketSide === "left") {
            var sourcePoint = detachFromInput(nodeIndex, socketLabel)

            if (!sourcePoint) {
                return
            }

            canvasPoint = sourcePoint
        } else {
            connectionSourceNodeIndex = nodeIndex
            connectionSourceSocket = socketLabel
        }

        isConnecting = true
        connectionSourceSide = "right"
        connectionStartX = canvasPoint.x
        connectionStartY = canvasPoint.y
        connectionEndX = canvasPoint.x
        connectionEndY = canvasPoint.y
        requestConnectionPaint()
    }

    function dragConnection(sceneX, sceneY) {
        if (!isConnecting) {
            return
        }

        var canvasPoint = scenePointToCanvas(sceneX, sceneY)
        connectionEndX = canvasPoint.x
        connectionEndY = canvasPoint.y
        requestConnectionPaint()
    }

    function finishConnection(sceneX, sceneY) {
        if (!isConnecting) {
            return
        }

        var releasePoint = scenePointToCanvas(sceneX, sceneY)
        var closestNodeIndex = -1
        var closestSocket = ""
        var closestDistance = 32

        for (var nodeIndex = 0; nodeIndex < graphNodes.count; nodeIndex += 1) {
            var nodeDelegate = nodeRepeater.itemAt(nodeIndex)

            if (!nodeDelegate || !nodeDelegate.nodeItem) {
                continue
            }

            var inputSockets = nodeDelegate.nodeItem.inputSockets

            for (var socketIndex = 0; socketIndex < inputSockets.length; socketIndex += 1) {
                var socketLabel = inputSockets[socketIndex]
                var socketPoint = socketCanvasPosition(nodeIndex, "left", socketLabel)

                if (!socketPoint) {
                    continue
                }

                var dx = releasePoint.x - socketPoint.x
                var dy = releasePoint.y - socketPoint.y
                var distance = Math.sqrt(dx * dx + dy * dy)

                if (distance < closestDistance) {
                    closestDistance = distance
                    closestNodeIndex = nodeIndex
                    closestSocket = socketLabel
                }
            }
        }

        if (closestNodeIndex >= 0) {
            removeConnectionsForInput(closestNodeIndex, closestSocket)
            graphConnections.append({
                "sourceNodeIndex": connectionSourceNodeIndex,
                "sourceSocket": connectionSourceSocket,
                "targetNodeIndex": closestNodeIndex,
                "targetSocket": closestSocket
            })
            computeGraph()
        }

        isConnecting = false
        connectionSourceNodeIndex = -1
        connectionSourceSocket = ""
        connectionSourceSide = "right"
        requestConnectionPaint()
    }

    function cancelGraphOperation() {
        if (!isConnecting && !isCuttingConnections) {
            return
        }

        isConnecting = false
        connectionSourceNodeIndex = -1
        connectionSourceSocket = ""
        connectionSourceSide = "right"
        isCuttingConnections = false
        connectionCutPoints = []
        requestConnectionPaint()
        graphComputed("Operation cancelled", "INFO")
    }

    function startConnectionCut(canvasX, canvasY) {
        isCuttingConnections = true
        connectionCutPoints = [{ "x": canvasX, "y": canvasY }]
        requestConnectionPaint()
    }

    function dragConnectionCut(canvasX, canvasY) {
        if (!isCuttingConnections) {
            return
        }

        var nextPoints = connectionCutPoints.slice()
        nextPoints.push({ "x": canvasX, "y": canvasY })
        connectionCutPoints = nextPoints
        requestConnectionPaint()
    }

    function finishConnectionCut() {
        if (!isCuttingConnections) {
            return
        }

        var removedCount = cutConnectionsOnPath(connectionCutPoints)
        isCuttingConnections = false
        connectionCutPoints = []
        requestConnectionPaint()

        if (removedCount > 0) {
            computeGraph()
        }

        graphComputed(removedCount > 0 ? "Cut " + removedCount + (removedCount === 1 ? " connection" : " connections") : "No connections cut", "INFO")
    }

    function cutConnectionsOnPath(cutPoints) {
        if (cutPoints.length < 2) {
            return 0
        }

        var removedCount = 0

        for (var connectionIndex = graphConnections.count - 1; connectionIndex >= 0; connectionIndex -= 1) {
            var connection = graphConnections.get(connectionIndex)
            var startPoint = socketCanvasPosition(connection.sourceNodeIndex, "right", connection.sourceSocket)
            var endPoint = socketCanvasPosition(connection.targetNodeIndex, "left", connection.targetSocket)

            if (startPoint && endPoint && connectionIntersectsCut(startPoint, endPoint, cutPoints)) {
                resetLookupValue(connection.targetNodeIndex)
                graphConnections.remove(connectionIndex)
                removedCount += 1
            }
        }

        return removedCount
    }

    function connectionIntersectsCut(startPoint, endPoint, cutPoints) {
        var previousConnectionPoint = bezierPoint(startPoint.x, startPoint.y, endPoint.x, endPoint.y, 0)

        for (var sampleIndex = 1; sampleIndex <= 24; sampleIndex += 1) {
            var connectionPoint = bezierPoint(startPoint.x, startPoint.y, endPoint.x, endPoint.y, sampleIndex / 24)

            for (var cutIndex = 1; cutIndex < cutPoints.length; cutIndex += 1) {
                if (segmentsIntersect(previousConnectionPoint, connectionPoint, cutPoints[cutIndex - 1], cutPoints[cutIndex])) {
                    return true
                }
            }

            previousConnectionPoint = connectionPoint
        }

        return false
    }

    function bezierPoint(startX, startY, endX, endY, t) {
        var controlOffset = Math.max(60, Math.abs(endX - startX) * 0.45)
        var x1 = startX + controlOffset
        var y1 = startY
        var x2 = endX - controlOffset
        var y2 = endY
        var inverseT = 1 - t

        return {
            "x": inverseT * inverseT * inverseT * startX + 3 * inverseT * inverseT * t * x1 + 3 * inverseT * t * t * x2 + t * t * t * endX,
            "y": inverseT * inverseT * inverseT * startY + 3 * inverseT * inverseT * t * y1 + 3 * inverseT * t * t * y2 + t * t * t * endY
        }
    }

    function segmentsIntersect(a, b, c, d) {
        var denominator = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)

        if (Math.abs(denominator) < 0.0001) {
            return false
        }

        var u = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denominator
        var v = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denominator

        return u >= 0 && u <= 1 && v >= 0 && v <= 1
    }

    function sourceValueText(sourceNodeIndex, sourceSocket) {
        var sourceDelegate = nodeRepeater.itemAt(sourceNodeIndex)

        if (!sourceDelegate || !sourceDelegate.nodeItem) {
            return "Connected: " + sourceSocket
        }

        if (sourceDelegate.nodeItem.value !== undefined) {
            return sourceDelegate.nodeItem.value.toString()
        }

        return sourceDelegate.nodeItem.title + "." + sourceSocket
    }

    function updateLookupValue(targetNodeIndex, sourceNodeIndex, sourceSocket) {
        var targetNode = graphNodes.get(targetNodeIndex)

        if (!targetNode || targetNode.type !== "Lookup") {
            return
        }

        graphNodes.setProperty(targetNodeIndex, "displayValue", sourceValueText(sourceNodeIndex, sourceSocket))
    }

    function updateConnectedLookupValues(sourceNodeIndex) {
        computeGraph()
    }

    function graphNodeSnapshot() {
        var nodes = []

        for (var nodeIndex = 0; nodeIndex < graphNodes.count; nodeIndex += 1) {
            var node = graphNodes.get(nodeIndex)
            var nodeDelegate = nodeRepeater.itemAt(nodeIndex)
            var nodeValue = node.value === undefined ? 0 : node.value

            if (nodeDelegate && nodeDelegate.nodeItem && nodeDelegate.nodeItem.value !== undefined) {
                nodeValue = nodeDelegate.nodeItem.value
            }

            nodes.push({
                "type": node.type,
                "value": nodeValue
            })
        }

        return nodes
    }

    function graphConnectionSnapshot() {
        var connections = []

        for (var connectionIndex = 0; connectionIndex < graphConnections.count; connectionIndex += 1) {
            var connection = graphConnections.get(connectionIndex)

            connections.push({
                "sourceNodeIndex": connection.sourceNodeIndex,
                "sourceSocket": connection.sourceSocket,
                "targetNodeIndex": connection.targetNodeIndex,
                "targetSocket": connection.targetSocket
            })
        }

        return connections
    }

    function applyLookupValues(lookupValues) {
        for (var nodeIndexText in lookupValues) {
            var nodeIndex = parseInt(nodeIndexText)

            if (!isNaN(nodeIndex) && nodeIndex >= 0 && nodeIndex < graphNodes.count) {
                graphNodes.setProperty(nodeIndex, "displayValue", lookupValues[nodeIndexText])
            }
        }
    }

    function computeGraph() {
        if (typeof graphRuntime === "undefined" || !graphRuntime) {
            graphComputed("Graph runtime is not available", "ERROR")
            return false
        }

        var result = graphRuntime.evaluate(graphNodeSnapshot(), graphConnectionSnapshot())

        if (result && result.lookupValues) {
            applyLookupValues(result.lookupValues)
        }

        if (!result || !result.ok) {
            graphComputed(result && result.message ? result.message : "Graph calculation failed", "ERROR")
            return false
        }

        graphComputed(result.message || "Graph computed", "INFO")
        return true
    }

    function viewOrigin() {
        zoom = 1.0
        offsetX = width / 2
        offsetY = height / 2
        requestGridPaint()
        requestConnectionPaint()
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
        requestConnectionPaint()
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

    ListModel {
        id: graphNodes
    }

    ListModel {
        id: graphConnections

        onCountChanged: requestConnectionPaint()
    }

    MouseArea {
        id: panArea

        property real lastX: 0
        property real lastY: 0

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.startConnectionCut(mouse.x, mouse.y)
                cursorShape = Qt.CrossCursor
                mouse.accepted = true
                return
            }

            root.clearSelection()
            lastX = mouse.x
            lastY = mouse.y
            cursorShape = Qt.ClosedHandCursor
        }

        onReleased: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.finishConnectionCut()
            }

            cursorShape = Qt.ArrowCursor
        }

        onCanceled: {
            cursorShape = Qt.ArrowCursor
        }

        onPositionChanged: function(mouse) {
            if (!pressed) {
                return
            }

            if ((mouse.buttons & Qt.RightButton) !== 0) {
                root.dragConnectionCut(mouse.x, mouse.y)
                return
            }

            root.offsetX += mouse.x - lastX
            root.offsetY += mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y
            root.requestGridPaint()
            root.requestConnectionPaint()
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
            root.requestConnectionPaint()
            wheel.accepted = true
        }
    }

    Canvas {
        id: connectionCanvas

        anchors.fill: parent
        z: 1

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 3
            ctx.strokeStyle = root.colors.nodeSocket

            function drawConnection(startX, startY, endX, endY) {
                var controlOffset = Math.max(60, Math.abs(endX - startX) * 0.45)

                ctx.beginPath()
                ctx.moveTo(startX, startY)
                ctx.bezierCurveTo(startX + controlOffset, startY, endX - controlOffset, endY, endX, endY)
                ctx.stroke()
            }

            function drawCutPath(points) {
                if (points.length < 2) {
                    return
                }

                ctx.save()
                ctx.lineWidth = 2
                ctx.strokeStyle = root.colors.accent

                for (var pointIndex = 1; pointIndex < points.length; pointIndex += 1) {
                    if (pointIndex % 2 === 0) {
                        continue
                    }

                    ctx.beginPath()
                    ctx.moveTo(points[pointIndex - 1].x, points[pointIndex - 1].y)
                    ctx.lineTo(points[pointIndex].x, points[pointIndex].y)
                    ctx.stroke()
                }

                ctx.restore()
            }

            for (var i = 0; i < graphConnections.count; i += 1) {
                var connection = graphConnections.get(i)
                var startPoint = root.socketCanvasPosition(connection.sourceNodeIndex, "right", connection.sourceSocket)
                var endPoint = root.socketCanvasPosition(connection.targetNodeIndex, "left", connection.targetSocket)

                if (startPoint && endPoint) {
                    drawConnection(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
                }
            }

            if (root.isConnecting) {
                drawConnection(root.connectionStartX, root.connectionStartY, root.connectionEndX, root.connectionEndY)
            }

            if (root.isCuttingConnections) {
                drawCutPath(root.connectionCutPoints)
            }
        }
    }

    Repeater {
        id: nodeRepeater

        model: graphNodes

        Item {
            id: nodeDelegate

            property Item nodeItem: nodeLoader.item
            property real nodeWidth: nodeLoader.item ? nodeLoader.item.width : 190
            property real nodeHeight: nodeLoader.item ? nodeLoader.item.height : 138

            x: root.offsetX + model.worldX * root.zoom - nodeWidth / 2
            y: root.offsetY + model.worldY * root.zoom - nodeHeight / 2
            width: nodeWidth
            height: nodeHeight
            z: 2
            scale: root.zoom
            transformOrigin: Item.Center

            Loader {
                id: nodeLoader

                sourceComponent: root.componentForNodeType(model.type)
            }

            Binding {
                target: nodeLoader.item
                property: "isSelected"
                value: root.isNodeSelected(index)
                when: nodeLoader.item !== null
            }

            Binding {
                target: nodeLoader.item
                property: "valueText"
                value: model.displayValue || "No value connected"
                when: nodeLoader.item !== null && model.type === "Lookup"
            }

            Connections {
                target: nodeLoader.item
                ignoreUnknownSignals: true

                function onSelected(additiveSelection) {
                    root.selectNode(index, additiveSelection)
                }

                function onMoved(screenDeltaX, screenDeltaY) {
                    var node = graphNodes.get(index)
                    graphNodes.setProperty(index, "worldX", node.worldX + screenDeltaX / root.zoom)
                    graphNodes.setProperty(index, "worldY", node.worldY + screenDeltaY / root.zoom)
                    root.requestConnectionPaint()
                }

                function onConnectionDragStarted(socketLabel, socketSide, sceneX, sceneY) {
                    root.startConnection(index, socketLabel, socketSide, sceneX, sceneY)
                }

                function onConnectionDragged(sceneX, sceneY) {
                    root.dragConnection(sceneX, sceneY)
                }

                function onConnectionDragFinished(sceneX, sceneY) {
                    root.finishConnection(sceneX, sceneY)
                }

                function onValueChanged() {
                    root.updateConnectedLookupValues(index)
                }
            }
        }
    }

    function componentForNodeType(nodeType) {
        if (nodeType === "Add") {
            return addNodeComponent
        } else if (nodeType === "Sub") {
            return subNodeComponent
        } else if (nodeType === "Mul") {
            return mulNodeComponent
        } else if (nodeType === "Button") {
            return buttonNodeComponent
        } else if (nodeType === "Int") {
            return intNodeComponent
        } else if (nodeType === "Float") {
            return floatNodeComponent
        } else if (nodeType === "Vector 2D") {
            return vector2DNodeComponent
        } else if (nodeType === "Vector 3D") {
            return vector3DNodeComponent
        } else if (nodeType === "Vector 4D") {
            return vector4DNodeComponent
        } else if (nodeType === "Bool") {
            return boolNodeComponent
        } else if (nodeType === "Str") {
            return strNodeComponent
        } else if (nodeType === "Lookup") {
            return lookupNodeComponent
        }

        return addNodeComponent
    }

    Component {
        id: addNodeComponent

        AddNode {}
    }

    Component {
        id: subNodeComponent

        SubNode {}
    }

    Component {
        id: mulNodeComponent

        MulNode {}
    }

    Component {
        id: buttonNodeComponent

        ButtonNode {}
    }

    Component {
        id: intNodeComponent

        IntNode {}
    }

    Component {
        id: floatNodeComponent

        FloatNode {}
    }

    Component {
        id: vector2DNodeComponent

        Vector2DNode {}
    }

    Component {
        id: vector3DNodeComponent

        Vector3DNode {}
    }

    Component {
        id: vector4DNodeComponent

        Vector4DNode {}
    }

    Component {
        id: boolNodeComponent

        BoolNode {}
    }

    Component {
        id: strNodeComponent

        StrNode {}
    }

    Component {
        id: lookupNodeComponent

        LookupNode {}
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
            font.pixelSize: 11
            text: "Pan: drag background  |  Move: drag node  |  Zoom: mouse wheel"
        }
    }
}
