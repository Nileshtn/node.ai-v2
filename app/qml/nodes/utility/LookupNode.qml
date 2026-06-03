import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    width: 320
    height: 150
    defaultTitle: "lookup"
    category: ""
    inputSockets: ["value"]
    outputSockets: []

    Label {
        Layout.fillWidth: true
        text: "Connect any output to inspect its value."
        color: colors.textMain
        font.pixelSize: 15
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    Label {
        Layout.fillWidth: true
        text: "Select this node, then press N or click the Lookup tab on the right to expand the sidebar."
        color: colors.textMuted
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
