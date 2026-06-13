import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    width: 400
    height: 280
    defaultTitle: "switch"
    category: ""
    inputSockets: ["index", "0", "1", "2", "default"]
    outputSockets: ["Name"]

    Label {
        Layout.fillWidth: true
        text: "switch index"
        color: colors.textMain
        font.pixelSize: 22
    }

    Label {
        Layout.fillWidth: true
        text: "Selects case 0, 1, or 2 by index. Uses default for other values."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
}
