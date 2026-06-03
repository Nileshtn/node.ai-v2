import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property string value: ""
    readonly property int controlWidth: 260

    width: 430
    height: 170
    defaultTitle: "str"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

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
            text: root.value
            color: colors.nodeControlText
            selectedTextColor: colors.nodeControlBackground
            selectionColor: colors.nodeSocket
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 18
            selectByMouse: true

            onTextEdited: root.value = text
        }
    }

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        text: "Text value"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
