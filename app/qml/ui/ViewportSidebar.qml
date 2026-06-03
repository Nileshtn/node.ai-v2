import QtQuick
import QtQuick.Controls
import "../canvas"
import "../theme"

Item {
    id: root

    property bool open: false
    property real panelWidth: 300
    property real minPanelWidth: 220
    property real maxPanelWidthRatio: 0.45
    property int splitterWidth: 4
    property int tabStripWidth: 28
    property var lookupEntries: []
    property string activeTab: "lookup"

    readonly property AppColors colors: AppColors {}
    readonly property real collapsedWidth: tabStripWidth
    readonly property real expandedWidth: panelWidth + tabStripWidth + splitterWidth
    readonly property real totalWidth: open ? expandedWidth : collapsedWidth
    readonly property var tabs: ["lookup"]

    signal toggled(bool open)

    function toggle() {
        open = !open
        toggled(open)
    }

    function expand() {
        if (!open) {
            open = true
            toggled(true)
        }
    }

    function tabLabel(tabId) {
        return tabId.charAt(0).toUpperCase() + tabId.slice(1)
    }

    function clampPanelWidth(nextWidth) {
        var maxWidth = parent ? parent.width * maxPanelWidthRatio : nextWidth

        return Math.max(minPanelWidth, Math.min(nextWidth, maxWidth))
    }

    width: totalWidth
    height: parent.height
    anchors.top: parent.top
    anchors.right: parent.right
    z: 10

    Rectangle {
        id: resizeSplitter

        visible: root.open
        x: 0
        y: 0
        width: splitterWidth
        height: parent.height
        z: 1
        color: resizeMouseArea.containsMouse || resizeMouseArea.pressed ? colors.accent : colors.panelBorder

        MouseArea {
            id: resizeMouseArea

            anchors.fill: parent
            enabled: root.open
            hoverEnabled: true
            cursorShape: Qt.SplitHCursor

            property real resizeStartGlobalX: 0
            property real resizeStartWidth: 0

            onPressed: function(mouse) {
                resizeStartGlobalX = mapToItem(null, mouse.x, mouse.y).x
                resizeStartWidth = root.panelWidth
            }

            onPositionChanged: function(mouse) {
                if (!pressed) {
                    return
                }

                var globalX = mapToItem(null, mouse.x, mouse.y).x
                var delta = globalX - resizeStartGlobalX

                root.panelWidth = root.clampPanelWidth(resizeStartWidth - delta)
            }
        }
    }

    Rectangle {
        id: panelShell

        x: root.open ? splitterWidth : 0
        y: 0
        width: root.open ? tabStripWidth + panelWidth : tabStripWidth
        height: parent.height
        z: 2
        color: colors.menuBarBackground
        border.color: colors.panelBorder
        border.width: 1
        clip: true

        Rectangle {
            id: tabRail

            x: 0
            y: 0
            width: tabStripWidth
            height: parent.height
            z: 2
            color: colors.nodeHeaderBackground

            Rectangle {
                width: 2
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                visible: root.open
                color: colors.accent
            }

            Rectangle {
                width: 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                visible: root.open
                color: colors.panelBorder
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                spacing: 4

                Repeater {
                    model: root.tabs

                    Rectangle {
                        width: tabRail.width - 4
                        height: 64
                        x: 2
                        radius: root.open && root.activeTab === modelData ? 0 : 3
                        color: {
                            if (root.activeTab !== modelData) {
                                return tabMouseArea.containsMouse ? colors.menuButtonHover : "transparent"
                            }

                            return root.open ? colors.menuBarBackground : colors.menuButtonHover
                        }

                        Label {
                            anchors.centerIn: parent
                            width: parent.height - 8
                            text: root.tabLabel(modelData)
                            rotation: -90
                            color: root.activeTab === modelData ? colors.textMain : colors.textMuted
                            font.pixelSize: 11
                            font.bold: root.activeTab === modelData
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: tabMouseArea

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                if (root.open && root.activeTab === modelData) {
                                    root.toggle()
                                    return
                                }

                                root.activeTab = modelData
                                root.expand()
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: contentPane

            visible: root.open
            x: tabStripWidth
            y: 0
            width: panelWidth
            height: parent.height
            z: 1

            LookupCanvas {
                anchors.fill: parent
                entries: root.lookupEntries
            }
        }
    }
}
