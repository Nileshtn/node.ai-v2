import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property bool value: false
    readonly property int controlWidth: 260

    width: 430
    height: 170
    title: "bool"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    Rectangle {
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignHCenter
        color: valueMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
        border.color: colors.nodeControlBorder
        border.width: 1
        radius: 3

        Label {
            anchors.centerIn: parent
            text: root.value ? "true" : "false"
            color: root.value ? colors.nodeSocket : colors.nodeControlText
            font.pixelSize: 18
        }

        MouseArea {
            id: valueMouseArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.value = !root.value
        }
    }

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        text: "Click to toggle"
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
