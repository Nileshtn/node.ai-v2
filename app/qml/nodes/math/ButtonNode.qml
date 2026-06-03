import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property bool value: false
    readonly property int controlWidth: 220

    width: 360
    height: 190
    defaultTitle: "button"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]

    Rectangle {
        Layout.preferredWidth: root.controlWidth
        Layout.preferredHeight: 52
        Layout.alignment: Qt.AlignHCenter
        color: buttonMouseArea.pressed || root.value ? colors.menuButtonHover : colors.nodeControlBackground
        border.color: root.value ? colors.nodeSocket : colors.nodeControlBorder
        border.width: 1
        radius: 4

        Label {
            anchors.centerIn: parent
            text: root.value ? "pressed" : "click"
            color: root.value ? colors.nodeSocket : colors.nodeControlText
            font.pixelSize: 18
        }

        MouseArea {
            id: buttonMouseArea

            anchors.fill: parent
            hoverEnabled: true
            onPressed: root.value = true
            onReleased: root.value = false
            onCanceled: root.value = false
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Outputs true while pressed."
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
