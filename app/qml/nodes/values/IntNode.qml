import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared"
import "../../theme"

Node {
    id: root

    property real value: 0
    readonly property int controlWidth: 260
    readonly property int stepperWidth: 26
    width: 430
    height: 190
    defaultTitle: "int"
    category: ""
    inputSockets: []
    outputSockets: ["Name"]
    readonly property var intTypes: ["int4", "int8", "int16", "int32", "int64"]
    property int typeIndex: 3
    readonly property string currentType: intTypes[typeIndex]

    function bitWidth() {
        return parseInt(currentType.replace("int", ""))
    }

    function minValue() {
        return -Math.pow(2, bitWidth() - 1)
    }

    function maxValue() {
        return Math.pow(2, bitWidth() - 1) - 1
    }

    function clampValue(nextValue) {
        if (isNaN(nextValue)) {
            return 0
        }

        return Math.max(minValue(), Math.min(maxValue(), Math.trunc(nextValue)))
    }

    function setValue(nextValue) {
        value = clampValue(nextValue)
    }

    RowLayout {
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignHCenter
        spacing: 6

        Rectangle {
            Layout.preferredWidth: root.controlWidth - root.stepperWidth - 6
            Layout.minimumWidth: root.controlWidth - root.stepperWidth - 6
            Layout.maximumWidth: root.controlWidth - root.stepperWidth - 6
            Layout.fillHeight: true
            color: colors.nodeControlBackground
            border.color: valueInput.activeFocus ? colors.nodeSocket : colors.nodeControlBorder
            border.width: 1

            NodeTextInput {
                id: valueInput

                nodeTarget: root
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                text: root.value.toString()
                color: colors.nodeControlText
                selectedTextColor: colors.nodeControlBackground
                selectionColor: colors.nodeSocket
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 18
                selectByMouse: true

                onEditingFinished: {
                    root.setValue(parseFloat(text || "0"))
                    text = root.value.toString()
                }

                Connections {
                    target: root

                    function onValueChanged() {
                        valueInput.text = root.value.toString()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.stepperWidth
            Layout.minimumWidth: root.stepperWidth
            Layout.maximumWidth: root.stepperWidth
            Layout.fillHeight: true
            spacing: 2

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: plusMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
                border.color: colors.nodeControlBorder
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: "+"
                    color: colors.nodeControlText
                    font.pixelSize: 14
                }

                MouseArea {
                    id: plusMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setValue(root.value + 1)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: minusMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
                border.color: colors.nodeControlBorder
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: "-"
                    color: colors.nodeControlText
                    font.pixelSize: 14
                }

                MouseArea {
                    id: minusMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setValue(root.value - 1)
                }
            }
        }
    }

    Rectangle {
        id: typeSelector
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.preferredHeight: 34
        Layout.alignment: Qt.AlignHCenter
        color: typeMouseArea.containsMouse ? colors.menuButtonHover : colors.nodeControlBackground
        border.color: colors.nodeControlBorder
        border.width: 1
        radius: 3

        Label {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 24
            text: root.currentType
            color: colors.nodeControlText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "v"
            color: colors.nodeControlText
            font.pixelSize: 13
        }

        MouseArea {
            id: typeMouseArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: typePopup.open()
        }

        Popup {
            id: typePopup

            x: typeSelector.x
            y: typeSelector.y + typeSelector.height + 2
            width: typeSelector.width
            height: typeList.contentHeight + 2
            padding: 1
            modal: false
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                color: colors.nodeControlBackground
                border.color: colors.nodeControlBorder
                border.width: 1
                radius: 3
            }

            contentItem: ListView {
                id: typeList

                model: root.intTypes
                clip: true

                delegate: Rectangle {
                    width: typeList.width
                    height: 30
                    color: typeOptionMouseArea.containsMouse || index === root.typeIndex ? colors.menuButtonHover : colors.nodeControlBackground

                    Label {
                        anchors.centerIn: parent
                        text: modelData
                        color: colors.nodeControlText
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: typeOptionMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.typeIndex = index
                            root.setValue(root.value)
                            typePopup.close()
                        }
                    }
                }
            }
        }
    }

    Label {
        Layout.preferredWidth: root.controlWidth
        Layout.minimumWidth: root.controlWidth
        Layout.maximumWidth: root.controlWidth
        Layout.preferredHeight: 14
        Layout.alignment: Qt.AlignHCenter
        text: "Range: " + root.minValue() + " to " + root.maxValue()
        color: colors.textMuted
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
