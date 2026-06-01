import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property var value: ({ "shape": "3" })
    readonly property int controlWidth: 260

    width: 430
    height: 170
    title: "ones"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    function setShape(nextShape) {
        value = { "shape": nextShape.length > 0 ? nextShape : "1" }
    }

    Rectangle {
        Layout.preferredWidth: root.controlWidth
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignHCenter
        color: colors.nodeControlBackground
        border.color: shapeInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
        border.width: 1
        radius: 3

        TextInput {
            id: shapeInput

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

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        text: "Shape examples: 3 or 2,3"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
