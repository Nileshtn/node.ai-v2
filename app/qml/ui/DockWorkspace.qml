import QtQuick
import "../theme"

Item {
    id: root

    default property alias centralContent: centerHost.data

    property alias sidebarOpen: viewportSidebar.open
    property alias sidebarWidth: viewportSidebar.panelWidth
    property var lookupEntries: viewportSidebar.lookupEntries
    property var nodeProperties: viewportSidebar.nodeProperties
    property alias graphCanvas: viewportSidebar.graphCanvas
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

    function refreshProperties(properties) {
        viewportSidebar.nodeProperties = properties || null
    }

    function pullPropertiesFromCanvas() {
        if (!graphCanvas || !graphCanvas.selectedNodeProperties) {
            refreshProperties(null)
            return
        }

        refreshProperties(graphCanvas.selectedNodeProperties())
    }

    function attachGraphCanvas() {
        for (var i = 0; i < centerHost.children.length; i += 1) {
            var child = centerHost.children[i]

            if (child && child.selectedNodeProperties !== undefined) {
                graphCanvas = child
                viewportSidebar.graphCanvas = child
                return
            }
        }
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
            onRequestPropertiesRefresh: root.pullPropertiesFromCanvas()
        }
    }

    Component.onCompleted: {
        attachGraphCanvas()
        relayoutCanvas()
    }

    onChildrenChanged: Qt.callLater(attachGraphCanvas)
}
