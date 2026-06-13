import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 380
    height: 220
    defaultTitle: "if else"
    category: ""
    inputSockets: ["condition", "then", "else"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "if condition then else"
        color: colors.textMain
        font.pixelSize: 22
    }

    Label {
        Layout.fillWidth: true
        text: "Returns then when condition is true, otherwise else."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}
