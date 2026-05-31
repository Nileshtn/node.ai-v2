import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    signal clicked()

    property string text: ""
    property bool active: false
    readonly property AppColors colors: AppColors {}

    Layout.preferredWidth: label.implicitWidth + 22
    Layout.preferredHeight: 26
    radius: 4
    color: mouseArea.containsMouse || active ? colors.menuButtonHover : "transparent"

    Label {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: colors.textMain
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
