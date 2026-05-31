import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    signal triggered()
    signal hovered()

    property string text: ""
    property string shortcut: ""
    property bool checked: false
    property bool hasSubmenu: false
    property bool itemEnabled: true
    readonly property AppColors colors: AppColors {}

    Layout.fillWidth: true
    height: 28
    radius: 4
    color: itemEnabled && mouseArea.containsMouse ? colors.menuButtonHover : "transparent"
    opacity: itemEnabled ? 1 : 0.45

    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        width: 14
        text: root.checked ? "x" : ""
        color: colors.accent
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 30
        text: root.text
        color: colors.textMain
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 10
        text: root.hasSubmenu ? ">" : root.shortcut
        color: colors.textMuted
        visible: root.hasSubmenu || root.shortcut.length > 0
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.itemEnabled
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.triggered()
    }
}
