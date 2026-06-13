import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property real value: 0
    readonly property int controlWidth: 260

    width: 430
    height: 170
    defaultTitle: "float"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    function setValue(nextValue) {
        value = isNaN(nextValue) ? 0 : nextValue
    }

    onValueChanged: {
        if (isNaN(value)) {
            value = 0
        }
    }

    Rectangle {
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignHCenter
        color: colors.nodeControlBackground
        border.color: valueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
        border.width: 1
        radius: 3

        NodeTextInput {
            id: valueInput

            nodeTarget: root
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            text: root.value.toString()
            color: colors.nodeControlText
            selectedTextColor: colors.nodeControlBackground
            selectionColor: colors.nodeSocket
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 18
            selectByMouse: true

            onEditingFinished: {
                root.setValue(parseFloat(text || "0"))
                text = root.value.toString()
            }

            Connections {
                target: root

                function onValueChanged() {
                    valueInput.text = root.value.toString()
                }
            }
        }
    }

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        text: "Floating point number"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
