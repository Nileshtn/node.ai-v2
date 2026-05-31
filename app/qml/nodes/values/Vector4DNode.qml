import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property var value: [0, 0, 0, 0]
    readonly property int controlWidth: 340
    readonly property int fieldWidth: 79

    width: 500
    height: 190
    title: "vector 4d"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    function setComponent(componentIndex, nextValue) {
        var next = [value[0], value[1], value[2], value[3]]
        next[componentIndex] = isNaN(nextValue) ? 0 : nextValue
        value = next
    }

    RowLayout {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Repeater {
            model: ["x", "y", "z", "w"]

            Rectangle {
                Layout.preferredWidth: root.fieldWidth
                Layout.preferredHeight: 44
                color: colors.nodeControlBackground
                border.color: componentInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
                border.width: 1
                radius: 3

                TextInput {
                    id: componentInput

                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    text: root.value[index].toString()
                    color: colors.nodeControlText
                    selectedTextColor: colors.nodeControlBackground
                    selectionColor: colors.nodeSocket
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 16
                    selectByMouse: true

                    onEditingFinished: {
                        root.setComponent(index, parseFloat(text || "0"))
                        text = root.value[index].toString()
                    }

                    Connections {
                        target: root

                        function onValueChanged() {
                            componentInput.text = root.value[index].toString()
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
        text: "4 component vector"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
