import QtQuick
import "../theme"

Item {
    id: root

    default property alias centralContent: centerHost.data

    property alias sidebarOpen: viewportSidebar.open
    property alias sidebarWidth: viewportSidebar.panelWidth
    property var lookupEntries: viewportSidebar.lookupEntries
    readonly property real sidebarInset: viewportSidebar.totalWidth

    readonly property AppColors colors: AppColors {}

    function toggleSidebar() {
        viewportSidebar.toggle()
        relayoutCanvas()
    }

    function showLookupPanel() {
        viewportSidebar.open = true
        relayoutCanvas()
    }

    function hideLookupPanel() {
        viewportSidebar.open = false
        relayoutCanvas()
    }

    function refreshLookupEntries(entries) {
        viewportSidebar.lookupEntries = entries || []
    }

    function relayoutCanvas() {
        for (var i = 0; i < centerHost.children.length; i += 1) {
            var child = centerHost.children[i]

            if (!child || child === viewportSidebar) {
                continue
            }

            child.anchors.fill = centerHost
            child.anchors.rightMargin = sidebarInset
        }
    }

    onSidebarInsetChanged: relayoutCanvas()

    Item {
        id: centerHost

        anchors.fill: parent
        clip: true

        onChildrenChanged: Qt.callLater(root.relayoutCanvas)

        ViewportSidebar {
            id: viewportSidebar

            lookupEntries: root.lookupEntries

            onOpenChanged: root.relayoutCanvas()
            onPanelWidthChanged: root.relayoutCanvas()
            onToggled: function(isOpen) {
                root.relayoutCanvas()
            }
        }
    }

    Component.onCompleted: relayoutCanvas()
}
