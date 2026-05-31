import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property string valueText: "No value connected"

    width: 360
    height: 190
    title: "lookup"
    category: ""
    inputSockets: ["value"]
    outputSockets: []

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        color: colors.nodeControlBackground
        border.color: colors.nodeControlBorder
        border.width: 1
        radius: 3

        Label {
            anchors.fill: parent
            anchors.margins: 10
            text: root.valueText
            color: colors.nodeControlText
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Connect any output to print its value."
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
