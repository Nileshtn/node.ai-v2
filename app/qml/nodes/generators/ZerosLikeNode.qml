import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 400
    height: 170
    title: "zeros like"
    category: ""
    inputSockets: ["like"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "zeros_like(like)"
        color: colors.textMain
        font.pixelSize: 20
    }

    Label {
        Layout.fillWidth: true
        text: "Matches scalar/vector shape with zeros."
        color: colors.textMuted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}
