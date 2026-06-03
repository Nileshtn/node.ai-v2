import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 400
    height: 170
    defaultTitle: "ones like"
    category: ""
    inputSockets: ["like"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "ones_like(like)"
        color: colors.textMain
        font.pixelSize: 20
    }

    Label {
        Layout.fillWidth: true
        text: "Matches scalar/vector shape with ones."
        color: colors.textMuted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}
