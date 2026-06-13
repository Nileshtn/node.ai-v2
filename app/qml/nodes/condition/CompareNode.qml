import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property var value: ({ "op": "eq" })

    readonly property var compareOps: ["eq", "neq", "lt", "lte", "gt", "gte"]
    readonly property int controlWidth: 300

    width: 400
    height: 230
    defaultTitle: "compare"
    category: ""
    inputSockets: ["a", "b"]
    outputSockets: ["Name"]

    function currentOp() {
        if (value && value.op !== undefined) {
            return value.op
        }

        return "eq"
    }

    function opSymbolFor(op) {
        if (op === "eq") {
            return "=="
        }

        if (op === "neq") {
            return "!="
        }

        if (op === "lt") {
            return "<"
        }

        if (op === "lte") {
            return "<="
        }

        if (op === "gt") {
            return ">"
        }

        if (op === "gte") {
            return ">="
        }

        return "=="
    }

    function setCompareOp(op) {
        value = { "op": op }
    }

    readonly property string opSymbol: opSymbolFor(currentOp())

    RowLayout {
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        Repeater {
            model: root.compareOps

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 34
                color: opMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
                border.color: root.currentOp() === modelData ? colors.nodeSocket : colors.nodeControlBorder
                border.width: root.currentOp() === modelData ? 2 : 1
                radius: 3

                Label {
                    anchors.centerIn: parent
                    text: root.opSymbolFor(modelData)
                    color: root.currentOp() === modelData ? colors.nodeSocket : colors.nodeControlText
                    font.pixelSize: 14
                    font.bold: root.currentOp() === modelData
                }

                MouseArea {
                    id: opMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setCompareOp(modelData)
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: "a " + root.opSymbol + " b"
        color: colors.textMain
        font.pixelSize: 22
        horizontalAlignment: Text.AlignHCenter
    }

    Label {
        Layout.fillWidth: true
        text: "Click an operator above to compare inputs."
        color: colors.textMuted
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
