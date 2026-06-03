import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property var value: ({ "start": 0, "stop": 10, "step": 1 })
    readonly property int controlWidth: 300
    readonly property int fieldWidth: 94

    width: 460
    height: 190
    defaultTitle: "range"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    function setField(fieldName, nextValue) {
        var next = {
            "start": value.start === undefined ? 0 : value.start,
            "stop": value.stop === undefined ? 10 : value.stop,
            "step": value.step === undefined ? 1 : value.step
        }
        next[fieldName] = isNaN(nextValue) ? next[fieldName] : nextValue
        value = next
    }

    RowLayout {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Repeater {
            model: ["start", "stop", "step"]

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
        text: "Sequence from start to stop"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
