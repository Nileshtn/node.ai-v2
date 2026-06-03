import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GraphCanvas {
    id: root

    property var entries: []
    readonly property int entryCount: Array.isArray(entries) ? entries.length : 0

    gridEnabled: false
    panEnabled: false
    backgroundColor: colors.menuBarBackground

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Label {
            Layout.fillWidth: true
            text: root.entryCount === 0
                  ? "Select Lookup nodes on the graph to see values."
                  : root.entryCount === 1 ? "1 lookup node selected" : root.entryCount + " lookup nodes selected"
            color: colors.textMuted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: colors.nodeBackground
            border.color: colors.panelBorder
            border.width: 1
            radius: 4
            clip: true

            ListView {
                id: entryList

                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true
                model: root.entries

                delegate: Rectangle {
                    width: entryList.width > 0 ? entryList.width : 1
                    height: Math.max(48, valueLabel.implicitHeight + 28)
                    color: colors.menuBarBackground
                    border.color: colors.panelBorder
                    border.width: 1
                    radius: 4

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Label {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: colors.accent
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Label {
                            id: valueLabel

                            Layout.fillWidth: true
                            text: modelData.value
                            color: colors.textMain
                            font.pixelSize: 15
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
