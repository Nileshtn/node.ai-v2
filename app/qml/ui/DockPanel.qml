import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    default property alias panelContent: contentHost.data

    property string title: "Panel"
    property string panelId: ""

    signal dockDragStarted(string panelId)
    signal dockDragMoved(real globalX, real globalY)
    signal dockDragEnded(string panelId, real globalX, real globalY)

    readonly property AppColors colors: AppColors {}

    ColumnLayout {
        anchors.fill: parent
        width: parent.width
        height: parent.height
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: colors.nodeHeaderBackground
            border.color: colors.panelBorder
            border.width: 1

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: colors.textMain
                font.pixelSize: 12
                font.bold: true
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "::"
                color: colors.textMuted
                font.pixelSize: 11
            }

            MouseArea {
                id: titleDragArea

                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: function(mouse) {
                    root.dockDragStarted(root.panelId)
                    mouse.accepted = true
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) {
                        return
                    }

                    var point = mapToItem(null, mouse.x, mouse.y)
                    root.dockDragMoved(point.x, point.y)
                    mouse.accepted = true
                }

                onReleased: function(mouse) {
                    var point = mapToItem(null, mouse.x, mouse.y)
                    root.dockDragEnded(root.panelId, point.x, point.y)
                    mouse.accepted = true
                }
            }
        }

        Item {
            id: contentHost

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 120
            Layout.minimumHeight: 80
            clip: true

            onChildrenChanged: contentHost.anchorPanelChildren()

            function anchorPanelChildren() {
                for (var i = 0; i < children.length; i += 1) {
                    var child = children[i]

                    if (!child) {
                        continue
                    }

                    child.anchors.fill = contentHost
                }
            }

            Component.onCompleted: anchorPanelChildren()
        }
    }
}
