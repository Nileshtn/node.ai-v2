import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 340
    height: 170
    defaultTitle: "and"
    category: ""
    inputSockets: ["a", "b"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "a and b"
        color: colors.textMain
        font.pixelSize: 22
    }

    Label {
        Layout.fillWidth: true
        text: "Returns true when both inputs are true."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}
