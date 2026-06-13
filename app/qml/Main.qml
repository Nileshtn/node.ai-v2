import QtQuick

import QtQuick.Controls

import QtQuick.Layouts

import "canvas"

import "ui"



ApplicationWindow {

    id: root



    property string currentProjectPath: ""



    function projectFileName(path) {

        var normalizedPath = path.replace(/\\/g, "/")

        var parts = normalizedPath.split("/")

        return parts.length > 0 ? parts[parts.length - 1] : "Node.ai"

    }



    function setProjectPath(path) {

        currentProjectPath = path || ""

        title = currentProjectPath.length > 0 ? "Node.ai - " + projectFileName(currentProjectPath) : "Node.ai"

    }



    function showProjectResult(result, successLevel) {

        infoBar.level = result && (result.ok || result.cancelled) ? successLevel : "ERROR"

        infoBar.message = result && result.message ? result.message : "Project file operation failed"

    }



    function saveProject(path) {

        var result = projectFiles.saveProject(canvas.projectSnapshot(), path)



        if (result.ok) {

            setProjectPath(result.path)

        }



        showProjectResult(result, "INFO")

    }



    function saveProjectAs() {

        var result = projectFiles.saveProjectAs(canvas.projectSnapshot())



        if (result.ok) {

            setProjectPath(result.path)

        }



        showProjectResult(result, result.cancelled ? "INFO" : "INFO")

    }



    function openProject() {

        var result = projectFiles.openProjectDialog()



        if (result.ok && canvas.loadProject(result.project)) {

            setProjectPath(result.path)

        }



        showProjectResult(result, result.cancelled ? "INFO" : "INFO")

    }



    function newProject() {

        canvas.clearProject()

        setProjectPath("")

    }



    function toggleLookupSidebar() {
        dockWorkspace.toggleSidebar()

        if (dockWorkspace.sidebarOpen) {
            canvas.computeGraph()
            dockWorkspace.refreshLookupEntries(canvas.selectedLookupEntries())
        }
    }



    width: 1280

    height: 800

    minimumWidth: 960

    minimumHeight: 600

    visible: true

    title: "Node.ai"



    Shortcut {

        sequence: StandardKey.Delete

        context: Qt.ApplicationShortcut

        onActivated: canvas.deleteSelectedNodes()

    }



    Shortcut {

        sequence: "Escape"

        context: Qt.ApplicationShortcut

        onActivated: canvas.cancelGraphOperation()

    }



    Shortcut {
        sequence: "N"
        context: Qt.ApplicationShortcut
        onActivated: root.toggleLookupSidebar()
    }

    Shortcut {
        sequence: "Ctrl+Alt+L"
        context: Qt.ApplicationShortcut
        onActivated: root.toggleLookupSidebar()
    }



    ColumnLayout {

        anchors.fill: parent

        spacing: 0



        AppMenuBar {

            Layout.fillWidth: true



            onActionTriggered: function(action) {

                if (action === "New Project") {

                    root.newProject()

                    return

                } else if (action === "Open Project...") {

                    root.openProject()

                    return

                } else if (action === "Save") {

                    root.saveProject(root.currentProjectPath)

                    return

                } else if (action === "Save As...") {

                    root.saveProjectAs()

                    return

                } else if (action === "Close Project") {

                    root.newProject()

                    return

                } else if (action === "View Origin" || action === "View All" || action === "Reset Zoom") {

                    canvas.viewOrigin()

                } else if (action === "Zoom In") {

                    canvas.zoomBy(1.1)

                } else if (action === "Zoom Out") {

                    canvas.zoomBy(0.9)

                } else if (action === "Run" || action === "Debug" || action === "Compute Selected" || action === "Compute Before" || action === "Compute After") {

                    canvas.computeGraph()

                    return

                } else if (action === "Delete") {

                    canvas.deleteSelectedNodes()

                    return

                } else if (action === "Add" || action === "Sub" || action === "Mul" || action === "Div") {

                    canvas.createMathNode(action)

                } else if (action === "Random" || action === "Random Like" || action === "Ones" || action === "Ones Like" || action === "Zeros" || action === "Zeros Like" || action === "Random Int" || action === "Range") {

                    canvas.createGeneratorNode(action)

                } else if (action === "Int" || action === "Float" || action === "Vector 2D" || action === "Vector 3D" || action === "Vector 4D" || action === "Bool" || action === "Str") {

                    canvas.createVarNode(action)

                } else if (action === "If Else" || action === "Switch" || action === "Compare" || action === "And" || action === "Or" || action === "Not") {

                    canvas.createConditionNode(action)

                } else if (action === "Lookup") {

                    canvas.createUtilityNode("Lookup")

                    return

                } else if (action === "Toggle Sidebar" || action === "Show Lookup") {

                    root.toggleLookupSidebar()

                    return

                }



                infoBar.message = action + " selected"

                infoBar.level = "INFO"

            }

        }



        DockWorkspace {

            id: dockWorkspace



            Layout.fillWidth: true

            Layout.fillHeight: true



            InfiniteGraphCanvas {

                id: canvas



                anchors.fill: parent



                onGraphComputed: function(message, level) {

                    infoBar.message = message

                    infoBar.level = level

                }



                onLookupDisplayChanged: {
                    if (dockWorkspace.sidebarOpen) {
                        dockWorkspace.refreshLookupEntries(canvas.selectedLookupEntries())
                    }
                }

                onPropertiesDisplayChanged: {
                    if (dockWorkspace.sidebarOpen) {
                        dockWorkspace.refreshProperties(canvas.selectedNodeProperties())
                    }
                }

            }

        }



        InfoBar {

            id: infoBar



            Layout.fillWidth: true

            message: "Canvas ready"

            detail: "Zoom " + Math.round(canvas.zoom * 100) + "%  |  Pan " + Math.round(canvas.offsetX) + ", " + Math.round(canvas.offsetY)

        }

    }

}


