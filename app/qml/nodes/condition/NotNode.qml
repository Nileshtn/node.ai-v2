import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 320
    height: 150
    defaultTitle: "not"
    category: ""
    inputSockets: ["a"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "not a"
        color: colors.textMain
        font.pixelSize: 22
    }

    Label {
        Layout.fillWidth: true
        text: "Inverts a boolean input."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}
