import QtQuick
import QtQuick.Controls
import "../nodes/generators"
import "../nodes/math"
import "../nodes/utility"
import "../nodes/values"
GraphCanvas {
    id: root

    signal graphComputed(string message, string level)
    signal lookupDisplayChanged()
    property int selectedNodeIndex: -1
    property var selectedNodeIndices: []
    property int hoveredNodeIndex: -1
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

    function requestConnectionPaint() {
        connectionCanvas.requestPaint()
    }

    onViewportChanged: requestConnectionPaint()

    onCanvasPressed: function(mouse) {
        if (mouse.button === Qt.RightButton) {
            startConnectionCut(mouse.x, mouse.y)
            panArea.cursorShape = Qt.CrossCursor
            return
        }

        clearSelection()
    }

    onCanvasReleased: function(mouse) {
        if (mouse.button === Qt.RightButton) {
            finishConnectionCut()
        }
    }

    onCanvasPanned: function(deltaX, deltaY, mouse) {
        if ((mouse.buttons & Qt.RightButton) !== 0) {
            dragConnectionCut(mouse.x, mouse.y)
        }
    }

    function isNodeSelected(nodeIndex) {
        return selectedNodeIndices.indexOf(nodeIndex) >= 0
    }

    function selectNode(nodeIndex, additiveSelection) {
        if (!additiveSelection) {
            selectedNodeIndices = [nodeIndex]
            selectedNodeIndex = nodeIndex
            lookupDisplayChanged()
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
        lookupDisplayChanged()
    }

    function clearSelection() {
        selectedNodeIndices = []
        selectedNodeIndex = -1
        lookupDisplayChanged()
    }

    function selectedLookupEntries() {
        var entries = []

        for (var selectionIndex = 0; selectionIndex < selectedNodeIndices.length; selectionIndex += 1) {
            var nodeIndex = selectedNodeIndices[selectionIndex]
            var node = graphNodes.get(nodeIndex)

            if (!node || node.type !== "Lookup") {
                continue
            }

            entries.push({
                "nodeIndex": nodeIndex,
                "label": nodeDisplayLabel(node),
                "value": node.displayValue || "No value connected"
            })
        }

        return entries
    }

    function setHoveredNode(nodeIndex, hovered) {
        if (hovered) {
            hoveredNodeIndex = nodeIndex
        } else if (hoveredNodeIndex === nodeIndex) {
            hoveredNodeIndex = -1
        }
    }

    function clearProject() {
        graphConnections.clear()
        graphNodes.clear()
        clearSelection()
        isConnecting = false
        isCuttingConnections = false
        connectionCutPoints = []
        viewOrigin()
        graphComputed("New project ready", "INFO")
    }

    function defaultNodeTitle(nodeType) {
        if (nodeType === "Add") {
            return "add"
        } else if (nodeType === "Sub") {
            return "sub"
        } else if (nodeType === "Mul") {
            return "mul"
        } else if (nodeType === "Button") {
            return "button"
        } else if (nodeType === "Random") {
            return "random"
        } else if (nodeType === "Random Like") {
            return "random like"
        } else if (nodeType === "Ones") {
            return "ones"
        } else if (nodeType === "Ones Like") {
            return "ones like"
        } else if (nodeType === "Zeros") {
            return "zeros"
        } else if (nodeType === "Zeros Like") {
            return "zeros like"
        } else if (nodeType === "Random Int") {
            return "random int"
        } else if (nodeType === "Range") {
            return "range"
        } else if (nodeType === "Int") {
            return "int"
        } else if (nodeType === "Float") {
            return "float"
        } else if (nodeType === "Vector 2D") {
            return "vector 2d"
        } else if (nodeType === "Vector 3D") {
            return "vector 3d"
        } else if (nodeType === "Vector 4D") {
            return "vector 4d"
        } else if (nodeType === "Bool") {
            return "bool"
        } else if (nodeType === "Str") {
            return "str"
        } else if (nodeType === "Lookup") {
            return "lookup"
        }

        return nodeType.length > 0 ? nodeType.toLowerCase() : "node"
    }

    function cloneLabelMap(labels) {
        var copy = {}

        if (!labels) {
            return copy
        }

        for (var key in labels) {
            copy[key] = labels[key]
        }

        return copy
    }

    function nodeDisplayLabel(node) {
        if (!node) {
            return "node"
        }

        if (node.displayName !== undefined && node.displayName.length > 0) {
            return node.displayName
        }

        if (node.title !== undefined && node.title.length > 0) {
            return node.title
        }

        return defaultNodeTitle(node.type || "")
    }

    function outputSocketLabelForModel(node, socketId) {
        if (!node || !node.outputLabels) {
            return socketId
        }

        if (node.outputLabels[socketId] !== undefined && node.outputLabels[socketId].length > 0) {
            return node.outputLabels[socketId]
        }

        return socketId
    }

    function createMathNode(nodeType) {
        var center = visibleCenterWorldPosition()

        graphNodes.append({
            "type": nodeType,
            "worldX": center.x,
            "worldY": center.y,
            "displayName": "",
            "outputLabels": {},
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
            "displayName": "",
            "outputLabels": {},
            "value": 0,
            "displayValue": ""
        })
        selectNode(graphNodes.count - 1, false)
        requestConnectionPaint()
    }

    function generatorDefaultValue(nodeType) {
        if (nodeType === "Random") {
            return { "shape": "3" }
        } else if (nodeType === "Random Int") {
            return { "shape": "3", "min": 0, "max": 10 }
        } else if (nodeType === "Ones" || nodeType === "Zeros") {
            return { "shape": "3" }
        } else if (nodeType === "Range") {
            return { "start": 0, "stop": 10, "step": 1 }
        }

        return {}
    }

    function createGeneratorNode(nodeType) {
        var center = visibleCenterWorldPosition()

        graphNodes.append({
            "type": nodeType,
            "worldX": center.x,
            "worldY": center.y,
            "displayName": "",
            "outputLabels": {},
            "value": generatorDefaultValue(nodeType),
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
            "displayName": "",
            "outputLabels": {},
            "value": 0,
            "displayValue": "No value connected"
        })
        selectNode(graphNodes.count - 1, false)
        requestConnectionPaint()
    }

    function nodeItemAt(nodeIndex) {
        for (var i = 0; i < nodeRepeater.count; i += 1) {
            if (i !== nodeIndex) {
                continue
            }

            var delegate = nodeRepeater.itemAt(i)

            return delegate ? delegate.nodeItem : null
        }

        return null
    }

    function clearTextFocusOnSelectedNodes() {
        for (var selectionIndex = 0; selectionIndex < selectedNodeIndices.length; selectionIndex += 1) {
            var nodeItem = nodeItemAt(selectedNodeIndices[selectionIndex])

            if (nodeItem && nodeItem.clearTextFocus) {
                nodeItem.clearTextFocus()
            }
        }
    }

    function deleteSelectedNodes() {
        clearTextFocusOnSelectedNodes()

        if (selectedNodeIndices.length === 0) {
            if (hoveredNodeIndex < 0 || hoveredNodeIndex >= graphNodes.count) {
                graphComputed("No selected nodes to delete", "INFO")
                return
            }

            selectNode(hoveredNodeIndex, false)
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
        hoveredNodeIndex = -1
        computeGraph()
        requestConnectionPaint()
        graphComputed("Deleted " + deletedCount + (deletedCount === 1 ? " node" : " nodes"), "INFO")
    }

    function socketCanvasPosition(nodeIndex, socketSide, socketLabel) {
        var nodeDelegate = nodeRepeater.itemAt(nodeIndex)

        if (!nodeDelegate || !nodeDelegate.nodeItem) {
            return null
        }

        return nodeDelegate.nodeItem.socketCanvasPosition(socketSide, socketLabel)
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

    function startConnection(nodeIndex, socketLabel, socketSide, canvasX, canvasY) {
        var canvasPoint = {
            "x": canvasX,
            "y": canvasY
        }

        if (socketSide === "left") {
            var sourcePoint = detachFromInput(nodeIndex, socketLabel)

            if (!sourcePoint) {
                return
            }

            canvasPoint = sourcePoint
        } else {
            connectionSourceNodeIndex = nodeIndex
            connectionSourceSocket = socketLabel

            var outputPoint = socketCanvasPosition(nodeIndex, "right", socketLabel)

            if (outputPoint) {
                canvasPoint = outputPoint
            }
        }

        isConnecting = true
        connectionSourceSide = "right"
        connectionStartX = canvasPoint.x
        connectionStartY = canvasPoint.y
        connectionEndX = canvasPoint.x
        connectionEndY = canvasPoint.y
        requestConnectionPaint()
    }

    function dragConnection(canvasX, canvasY) {
        if (!isConnecting) {
            return
        }

        connectionEndX = canvasX
        connectionEndY = canvasY
        requestConnectionPaint()
    }

    function finishConnection(canvasX, canvasY) {
        if (!isConnecting) {
            return
        }

        var releasePoint = {
            "x": canvasX,
            "y": canvasY
        }
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

        var sourceNode = graphNodes.get(sourceNodeIndex)

        return nodeDisplayLabel(sourceNode) + "." + outputSocketLabelForModel(sourceNode, sourceSocket)
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

    function projectNodeSnapshot() {
        var nodes = []

        for (var nodeIndex = 0; nodeIndex < graphNodes.count; nodeIndex += 1) {
            var node = graphNodes.get(nodeIndex)
            var nodeDelegate = nodeRepeater.itemAt(nodeIndex)
            var nodeValue = node.value === undefined ? 0 : node.value

            if (nodeDelegate && nodeDelegate.nodeItem && nodeDelegate.nodeItem.value !== undefined) {
                nodeValue = nodeDelegate.nodeItem.value
            }

            var outputLabels = cloneLabelMap(node.outputLabels)

            if (nodeDelegate && nodeDelegate.nodeItem) {
                outputLabels = cloneLabelMap(nodeDelegate.nodeItem.outputLabels)
            }

            nodes.push({
                "type": node.type,
                "displayName": node.displayName || "",
                "outputLabels": outputLabels,
                "worldX": node.worldX,
                "worldY": node.worldY,
                "value": nodeValue,
                "displayValue": node.displayValue || ""
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

    function projectSnapshot() {
        return {
            "format": "node.ai.project",
            "version": 1,
            "view": viewportSnapshot(),
            "nodes": projectNodeSnapshot(),
            "connections": graphConnectionSnapshot()
        }
    }

    function loadProject(project) {
        if (!project || project.format !== "node.ai.project" || project.version !== 1) {
            graphComputed("Project file is not supported", "ERROR")
            return false
        }

        graphConnections.clear()
        graphNodes.clear()
        clearSelection()
        isConnecting = false
        isCuttingConnections = false
        connectionCutPoints = []

        var projectNodes = project.nodes || []

        for (var nodeIndex = 0; nodeIndex < projectNodes.length; nodeIndex += 1) {
            var node = projectNodes[nodeIndex]

            graphNodes.append({
                "type": node.type || "",
                "displayName": node.displayName || node.title || "",
                "outputLabels": cloneLabelMap(node.outputLabels),
                "worldX": node.worldX || 0,
                "worldY": node.worldY || 0,
                "value": node.value === undefined ? 0 : node.value,
                "displayValue": node.displayValue || ""
            })
        }

        var projectConnections = project.connections || []

        for (var connectionIndex = 0; connectionIndex < projectConnections.length; connectionIndex += 1) {
            var connection = projectConnections[connectionIndex]

            graphConnections.append({
                "sourceNodeIndex": connection.sourceNodeIndex,
                "sourceSocket": connection.sourceSocket,
                "targetNodeIndex": connection.targetNodeIndex,
                "targetSocket": connection.targetSocket
            })
        }

        applyViewport(project.view)
        requestConnectionPaint()
        computeGraph()
        graphComputed("Project loaded", "INFO")
        return true
    }

    function applyLookupValues(lookupValues) {
        for (var nodeIndexText in lookupValues) {
            var nodeIndex = parseInt(nodeIndexText)

            if (!isNaN(nodeIndex) && nodeIndex >= 0 && nodeIndex < graphNodes.count) {
                graphNodes.setProperty(nodeIndex, "displayValue", lookupValues[nodeIndexText])
            }
        }

        lookupDisplayChanged()
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

    ListModel {
        id: graphNodes
    }

    ListModel {
        id: graphConnections

        onCountChanged: requestConnectionPaint()
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

                onLoaded: {
                    if (!item) {
                        return
                    }

                    if (item.value !== undefined && model.value !== undefined) {
                        item.value = model.value
                    }

                    item.graphCanvas = root
                    item.displayName = model.displayName || ""
                    item.outputLabels = root.cloneLabelMap(model.outputLabels)
                }
            }

            Binding {
                target: nodeLoader.item
                property: "graphCanvas"
                value: root
                when: nodeLoader.item !== null
            }

            Binding {
                target: nodeLoader.item
                property: "isSelected"
                value: root.isNodeSelected(index)
                when: nodeLoader.item !== null
            }

            Binding {
                target: nodeLoader.item
                property: "displayName"
                value: model.displayName || ""
                when: nodeLoader.item !== null
            }

            Binding {
                target: nodeLoader.item
                property: "outputLabels"
                value: root.cloneLabelMap(model.outputLabels)
                when: nodeLoader.item !== null
            }

            Connections {
                target: nodeLoader.item
                ignoreUnknownSignals: true

                function onSelected(additiveSelection) {
                    root.selectNode(index, additiveSelection)
                }

                function onDeleteRequested() {
                    root.deleteSelectedNodes()
                }

                function onDisplayNameEdited(newDisplayName) {
                    graphNodes.setProperty(index, "displayName", newDisplayName)

                    if (nodeLoader.item) {
                        nodeLoader.item.displayName = newDisplayName
                    }

                    root.lookupDisplayChanged()
                    root.updateConnectedLookupValues(index)
                }

                function onOutputLabelsEdited(labels) {
                    var savedLabels = root.cloneLabelMap(labels)

                    graphNodes.setProperty(index, "outputLabels", savedLabels)

                    if (nodeLoader.item) {
                        nodeLoader.item.outputLabels = savedLabels
                    }

                    root.lookupDisplayChanged()
                    root.updateConnectedLookupValues(index)
                }

                function onNodeHoverChanged(hovered) {
                    root.setHoveredNode(index, hovered)
                }

                function onMoved(screenDeltaX, screenDeltaY) {
                    var node = graphNodes.get(index)
                    graphNodes.setProperty(index, "worldX", node.worldX + screenDeltaX / root.zoom)
                    graphNodes.setProperty(index, "worldY", node.worldY + screenDeltaY / root.zoom)
                    root.requestConnectionPaint()
                }

                function onConnectionDragStarted(socketLabel, socketSide, canvasX, canvasY) {
                    root.startConnection(index, socketLabel, socketSide, canvasX, canvasY)
                }

                function onConnectionDragged(canvasX, canvasY) {
                    root.dragConnection(canvasX, canvasY)
                }

                function onConnectionDragFinished(canvasX, canvasY) {
                    root.finishConnection(canvasX, canvasY)
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
        } else if (nodeType === "Random") {
            return randomNodeComponent
        } else if (nodeType === "Random Like") {
            return randomLikeNodeComponent
        } else if (nodeType === "Ones") {
            return onesNodeComponent
        } else if (nodeType === "Ones Like") {
            return onesLikeNodeComponent
        } else if (nodeType === "Zeros") {
            return zerosNodeComponent
        } else if (nodeType === "Zeros Like") {
            return zerosLikeNodeComponent
        } else if (nodeType === "Random Int") {
            return randomIntNodeComponent
        } else if (nodeType === "Range") {
            return rangeNodeComponent
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
        id: randomNodeComponent

        RandomNode {}
    }

    Component {
        id: randomLikeNodeComponent

        RandomLikeNode {}
    }

    Component {
        id: onesNodeComponent

        OnesNode {}
    }

    Component {
        id: onesLikeNodeComponent

        OnesLikeNode {}
    }

    Component {
        id: zerosNodeComponent

        ZerosNode {}
    }

    Component {
        id: zerosLikeNodeComponent

        ZerosLikeNode {}
    }

    Component {
        id: randomIntNodeComponent

        RandomIntNode {}
    }

    Component {
        id: rangeNodeComponent

        RangeNode {}
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
}
