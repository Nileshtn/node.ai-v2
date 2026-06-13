import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GraphCanvas {
    id: root

    property var nodeProperties: null
    property var graphCanvas: null
    property bool syncingFromModel: false

    readonly property bool hasSingleSelection: nodeProperties && !nodeProperties.multi
    readonly property var valueEditor: hasSingleSelection ? nodeProperties.valueEditor : null
    readonly property real contentWidth: Math.max(180, width - 20)

    gridEnabled: false
    panEnabled: false
    backgroundColor: colors.menuBarBackground

    function syncFromModel() {
        if (!root.hasSingleSelection) {
            return
        }

        syncingFromModel = true
        displayNameField.text = nodeProperties.displayName || ""
        outputFieldsModel.clear()

        for (var i = 0; i < nodeProperties.outputs.length; i += 1) {
            var output = nodeProperties.outputs[i]
            outputFieldsModel.append({
                "socketId": output.socketId,
                "label": output.label
            })
        }

        valueEditorPanel.syncValueFields()
        syncingFromModel = false
    }

    onNodePropertiesChanged: syncFromModel()
    onWidthChanged: {
        scrollFlickable.contentWidth = contentWidth
    }

    ListModel {
        id: outputFieldsModel
    }

    ListModel {
        id: vectorFieldsModel
    }

    Flickable {
        id: scrollFlickable

        anchors.fill: parent
        anchors.margins: 10
        contentWidth: root.contentWidth
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn

            width: scrollFlickable.contentWidth
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: {
                    if (!nodeProperties) {
                        return "Select a node on the graph to edit properties."
                    }

                    if (nodeProperties.multi) {
                        return nodeProperties.count + " nodes selected. Select one node to edit."
                    }

                    return nodeProperties.typeTitle + " (" + nodeProperties.type + ")"
                }
                color: colors.textMain
                font.pixelSize: 13
                font.bold: nodeProperties && !nodeProperties.multi
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                visible: root.hasSingleSelection
                text: "Display name"
                color: colors.textMuted
                font.pixelSize: 11
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                visible: root.hasSingleSelection
                color: colors.nodeControlBackground
                border.color: displayNameField.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                border.width: 1
                radius: 3

                TextInput {
                    id: displayNameField

                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    color: colors.nodeControlText
                    font.pixelSize: 13
                    selectByMouse: true
                    maximumLength: 64
                    verticalAlignment: TextInput.AlignVCenter

                    onEditingFinished: commitDisplayName()
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            commitDisplayName()
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: root.hasSingleSelection && outputFieldsModel.count > 0
                text: "Output names"
                color: colors.textMuted
                font.pixelSize: 11
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.hasSingleSelection && outputFieldsModel.count > 0
                spacing: 6

                Repeater {
                    model: outputFieldsModel

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: model.socketId
                            color: colors.textMuted
                            font.pixelSize: 10
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            color: colors.nodeControlBackground
                            border.color: outputFieldInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                            border.width: 1
                            radius: 3

                            TextInput {
                                id: outputFieldInput

                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: model.label
                                color: colors.nodeControlText
                                font.pixelSize: 12
                                selectByMouse: true
                                maximumLength: 32
                                verticalAlignment: TextInput.AlignVCenter

                                property string boundSocketId: model.socketId

                                onEditingFinished: commitOutputLabel()
                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        commitOutputLabel()
                                    }
                                }

                                function commitOutputLabel() {
                                    if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeOutputLabel) {
                                        return
                                    }

                                    graphCanvas.updateSelectedNodeOutputLabel(boundSocketId, text)
                                }
                            }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: root.hasSingleSelection && valueEditor && valueEditor.kind !== "none"
                text: "Value"
                color: colors.textMuted
                font.pixelSize: 11
            }

            ColumnLayout {
                id: valueEditorPanel

                Layout.fillWidth: true
                visible: root.hasSingleSelection && valueEditor && valueEditor.kind !== "none"
                spacing: 8

                function syncValueFields() {
                    if (!root.hasSingleSelection || !root.valueEditor) {
                        return
                    }

                    var value = nodeProperties.value
                    var kind = valueEditor.kind

                    scalarBox.visible = kind === "int" || kind === "float" || kind === "text" || kind === "shape"
                    scalarCaption.visible = scalarBox.visible
                    boolRow.visible = kind === "bool"
                    vectorRow.visible = kind === "vector"
                    randomIntRow.visible = kind === "randomInt"
                    rangeRow.visible = kind === "range"
                    compareRow.visible = kind === "compare"

                    if (kind === "int" || kind === "float" || kind === "text" || kind === "shape") {
                        scalarCaption.text = kind === "shape" ? "Shape" : (kind === "text" ? "Text" : "Number")

                        if (kind === "shape" && value && value.shape !== undefined) {
                            scalarValueInput.text = value.shape.toString()
                        } else {
                            scalarValueInput.text = value === undefined || value === null ? "" : value.toString()
                        }
                    } else if (kind === "bool") {
                        boolValueLabel.text = value ? "true" : "false"
                    } else if (kind === "vector") {
                        vectorFieldsModel.clear()
                        var axisLabels = ["x", "y", "z", "w"]
                        var axisCount = valueEditor.size || 2

                        for (var axisIndex = 0; axisIndex < axisCount; axisIndex += 1) {
                            vectorFieldsModel.append({
                                "title": axisLabels[axisIndex],
                                "text": (value && value[axisIndex] !== undefined) ? value[axisIndex].toString() : "0"
                            })
                        }
                    } else if (kind === "randomInt") {
                        shapeValueInput.text = value && value.shape !== undefined ? value.shape.toString() : "3"
                        minValueInput.text = value && value.min !== undefined ? value.min.toString() : "0"
                        maxValueInput.text = value && value.max !== undefined ? value.max.toString() : "10"
                    } else if (kind === "range") {
                        startValueInput.text = value && value.start !== undefined ? value.start.toString() : "0"
                        stopValueInput.text = value && value.stop !== undefined ? value.stop.toString() : "10"
                        stepValueInput.text = value && value.step !== undefined ? value.step.toString() : "1"
                    } else if (kind === "compare") {
                        compareOpLabel.text = compareRow.labelForOp(value && value.op !== undefined ? value.op : "eq")
                    }
                }

                Label {
                    id: scalarCaption

                    Layout.fillWidth: true
                    visible: false
                    color: colors.textMuted
                    font.pixelSize: 10
                }

                Rectangle {
                    id: scalarBox

                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    visible: false
                    color: colors.nodeControlBackground
                    border.color: scalarValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                    border.width: 1
                    radius: 3

                    TextInput {
                        id: scalarValueInput

                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        color: colors.nodeControlText
                        font.pixelSize: 13
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        onEditingFinished: valueEditorPanel.commitScalarValue()
                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                valueEditorPanel.commitScalarValue()
                            }
                        }
                    }
                }

                function commitScalarValue() {
                    if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeValue || !root.valueEditor) {
                        return
                    }

                    var kind = valueEditor.kind
                    var text = scalarValueInput.text.trim()

                    if (kind === "int") {
                        var intValue = parseInt(text, 10)
                        graphCanvas.updateSelectedNodeValue(isNaN(intValue) ? 0 : intValue)
                    } else if (kind === "float") {
                        var floatValue = parseFloat(text)
                        graphCanvas.updateSelectedNodeValue(isNaN(floatValue) ? 0 : floatValue)
                    } else if (kind === "text") {
                        graphCanvas.updateSelectedNodeValue(text)
                    } else if (kind === "shape") {
                        graphCanvas.updateSelectedNodeValue({ "shape": text.length > 0 ? text : "1" })
                    }
                }

                RowLayout {
                    id: boolRow

                    Layout.fillWidth: true
                    visible: false
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: "Boolean"
                        color: colors.textMuted
                        font.pixelSize: 10
                    }

                    Rectangle {
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 30
                        color: boolMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
                        border.color: colors.nodeControlBorder
                        border.width: 1
                        radius: 3

                        Label {
                            id: boolValueLabel

                            anchors.centerIn: parent
                            color: colors.nodeControlText
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: boolMouseArea

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeValue) {
                                    return
                                }

                                graphCanvas.updateSelectedNodeValue(boolValueLabel.text !== "true")
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: vectorRow

                    Layout.fillWidth: true
                    visible: false
                    spacing: 6

                    Repeater {
                        model: vectorFieldsModel

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                Layout.fillWidth: true
                                text: model.title
                                color: colors.textMuted
                                font.pixelSize: 10
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: colors.nodeControlBackground
                                border.color: vectorInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                                border.width: 1
                                radius: 3

                                TextInput {
                                    id: vectorInput

                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    text: model.text
                                    color: colors.nodeControlText
                                    font.pixelSize: 12
                                    selectByMouse: true
                                    verticalAlignment: TextInput.AlignVCenter

                                    property int axisIndex: index

                                    onEditingFinished: commitVectorAxis()
                                    onActiveFocusChanged: {
                                        if (!activeFocus) {
                                            commitVectorAxis()
                                        }
                                    }

                                    function commitVectorAxis() {
                                        if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeVectorComponent) {
                                            return
                                        }

                                        var axisValue = parseFloat(text || "0")
                                        graphCanvas.updateSelectedNodeVectorComponent(axisIndex, isNaN(axisValue) ? 0 : axisValue)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: randomIntRow

                    Layout.fillWidth: true
                    visible: false
                    spacing: 6

                    function commitRandomInt() {
                        if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeValue) {
                            return
                        }

                        graphCanvas.updateSelectedNodeValue({
                            "shape": shapeValueInput.text.trim().length > 0 ? shapeValueInput.text.trim() : "3",
                            "min": parseFloat(minValueInput.text || "0"),
                            "max": parseFloat(maxValueInput.text || "0")
                        })
                    }

                    Label { Layout.fillWidth: true; text: "Shape"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: shapeValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: shapeValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: randomIntRow.commitRandomInt()
                            onActiveFocusChanged: if (!activeFocus) randomIntRow.commitRandomInt()
                        }
                    }

                    Label { Layout.fillWidth: true; text: "Min"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: minValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: minValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: randomIntRow.commitRandomInt()
                            onActiveFocusChanged: if (!activeFocus) randomIntRow.commitRandomInt()
                        }
                    }

                    Label { Layout.fillWidth: true; text: "Max"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: maxValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: maxValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: randomIntRow.commitRandomInt()
                            onActiveFocusChanged: if (!activeFocus) randomIntRow.commitRandomInt()
                        }
                    }
                }

                ColumnLayout {
                    id: rangeRow

                    Layout.fillWidth: true
                    visible: false
                    spacing: 6

                    function commitRange() {
                        if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeValue) {
                            return
                        }

                        graphCanvas.updateSelectedNodeValue({
                            "start": parseFloat(startValueInput.text || "0"),
                            "stop": parseFloat(stopValueInput.text || "0"),
                            "step": parseFloat(stepValueInput.text || "1")
                        })
                    }

                    Label { Layout.fillWidth: true; text: "Start"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: startValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: startValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: rangeRow.commitRange()
                            onActiveFocusChanged: if (!activeFocus) rangeRow.commitRange()
                        }
                    }

                    Label { Layout.fillWidth: true; text: "Stop"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: stopValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: stopValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: rangeRow.commitRange()
                            onActiveFocusChanged: if (!activeFocus) rangeRow.commitRange()
                        }
                    }

                    Label { Layout.fillWidth: true; text: "Step"; color: colors.textMuted; font.pixelSize: 10 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: colors.nodeControlBackground
                        border.color: stepValueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                        border.width: 1
                        radius: 3
                        TextInput {
                            id: stepValueInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: colors.nodeControlText
                            font.pixelSize: 12
                            selectByMouse: true
                            onEditingFinished: rangeRow.commitRange()
                            onActiveFocusChanged: if (!activeFocus) rangeRow.commitRange()
                        }
                    }
                }

                RowLayout {
                    id: compareRow

                    Layout.fillWidth: true
                    visible: false
                    spacing: 8

                    readonly property var compareOps: ["eq", "neq", "lt", "lte", "gt", "gte"]

                    function labelForOp(op) {
                        if (op === "eq") {
                            return "Equals (==)"
                        }

                        if (op === "neq") {
                            return "Not equal (!=)"
                        }

                        if (op === "lt") {
                            return "Less than (<)"
                        }

                        if (op === "lte") {
                            return "Less or equal (<=)"
                        }

                        if (op === "gt") {
                            return "Greater than (>)"
                        }

                        if (op === "gte") {
                            return "Greater or equal (>=)"
                        }

                        return "Equals (==)"
                    }

                    function cycleCompareOp() {
                        if (root.syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeValue) {
                            return
                        }

                        var current = nodeProperties.value && nodeProperties.value.op !== undefined
                                ? nodeProperties.value.op
                                : "eq"
                        var nextIndex = (compareOps.indexOf(current) + 1) % compareOps.length

                        graphCanvas.updateSelectedNodeValue({ "op": compareOps[nextIndex] })
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Operator"
                        color: colors.textMuted
                        font.pixelSize: 10
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: compareMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
                        border.color: colors.nodeControlBorder
                        border.width: 1
                        radius: 3

                        Label {
                            id: compareOpLabel

                            anchors.centerIn: parent
                            color: colors.nodeControlText
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: compareMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: compareRow.cycleCompareOp()
                        }
                    }
                }
            }
        }
    }

    function commitDisplayName() {
        if (syncingFromModel || !graphCanvas || !graphCanvas.updateSelectedNodeDisplayName) {
            return
        }

        graphCanvas.updateSelectedNodeDisplayName(displayNameField.text)
    }
}
