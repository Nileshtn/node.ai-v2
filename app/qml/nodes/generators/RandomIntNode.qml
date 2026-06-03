import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property var value: ({ "shape": "3", "min": 0, "max": 10 })
    readonly property int controlWidth: 260
    readonly property int fieldWidth: 126

    width: 430
    height: 240
    defaultTitle: "random int"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    function setField(fieldName, nextValue) {
        var next = {
            "shape": value.shape === undefined ? "3" : value.shape,
            "min": value.min === undefined ? 0 : value.min,
            "max": value.max === undefined ? 10 : value.max
        }
        next[fieldName] = isNaN(nextValue) ? next[fieldName] : Math.trunc(nextValue)
        value = next
    }

    function setShape(nextShape) {
        value = {
            "shape": nextShape.length > 0 ? nextShape : "1",
            "min": value.min === undefined ? 0 : value.min,
            "max": value.max === undefined ? 10 : value.max
        }
    }

    Rectangle {
        Layout.preferredWidth: root.controlWidth
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignHCenter
        color: colors.nodeControlBackground
        border.color: shapeInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
        border.width: 1
        radius: 3

        NodeTextInput {
            id: shapeInput

            nodeTarget: root
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            text: root.value.shape === undefined ? "3" : root.value.shape
            color: colors.nodeControlText
            selectedTextColor: colors.nodeControlBackground
            selectionColor: colors.nodeSocket
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 16
            selectByMouse: true

            onEditingFinished: {
                root.setShape(text)
                text = root.value.shape
            }

            Connections {
                target: root

                function onValueChanged() {
                    shapeInput.text = root.value.shape === undefined ? "3" : root.value.shape
                }
            }
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 4
            text: "shape"
            color: colors.textMuted
            font.pixelSize: 10
        }
    }

    RowLayout {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Repeater {
            model: ["min", "max"]

            Rectangle {
                Layout.preferredWidth: root.fieldWidth
                Layout.preferredHeight: 44
                color: colors.nodeControlBackground
                border.color: fieldInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                border.width: 1
                radius: 3

                NodeTextInput {
                    id: fieldInput

                    nodeTarget: root
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    text: (root.value[modelData] === undefined ? 0 : root.value[modelData]).toString()
                    color: colors.nodeControlText
                    selectedTextColor: colors.nodeControlBackground
                    selectionColor: colors.nodeSocket
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 16
                    selectByMouse: true

                    onEditingFinished: {
                        root.setField(modelData, parseFloat(text || "0"))
                        text = root.value[modelData].toString()
                    }

                    Connections {
                        target: root

                        function onValueChanged() {
                            fieldInput.text = (root.value[modelData] === undefined ? 0 : root.value[modelData]).toString()
                        }
                    }
                }

                Label {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 4
                    text: modelData
                    color: colors.textMuted
                    font.pixelSize: 10
                }
            }
        }
    }

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        text: "Shape plus integer min/max"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
