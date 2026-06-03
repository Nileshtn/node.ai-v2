import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 360
    height: 190
    defaultTitle: "sub"
    category: ""
    inputSockets: ["a", "b"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "a - b"
        color: colors.textMain
        font.pixelSize: 22
    }

    Label {
        Layout.fillWidth: true
        text: "Subtracts b from a and returns the result."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}
