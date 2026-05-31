import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string message: "Ready"
    property string detail: ""
    property string level: "INFO"
    readonly property AppColors colors: AppColors {}

    height: 30
    color: colors.infoBarBackground
    border.color: colors.infoBarBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Label {
            text: root.level
            color: colors.textMain
            font.bold: true
            font.pixelSize: 12
        }

        Rectangle {
            width: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: colors.infoBarBorder
        }

        Label {
            text: root.message
            color: colors.textMain
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Label {
            text: root.detail
            color: colors.textMuted
            visible: root.detail.length > 0
        }
    }
}
