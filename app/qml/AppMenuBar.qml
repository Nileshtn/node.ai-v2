import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    signal actionTriggered(string action)

    readonly property AppColors colors: AppColors {}

    height: 34
    color: colors.menuBarBackground
    border.color: colors.menuBarBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 4

        Label {
            text: "Node.ai"
            color: colors.textMain
            font.bold: true
            font.pixelSize: 13
            rightPadding: 10
        }

        MenuButton {
            id: fileButton

            text: "File"
            active: fileMenu.opened
            onClicked: fileMenu.open()
        }

        MenuButton {
            id: editButton

            text: "Edit"
            active: editMenu.opened
            onClicked: editMenu.open()
        }

        MenuButton {
            id: viewButton

            text: "View"
            active: viewMenu.opened
            onClicked: viewMenu.open()
        }

        MenuButton {
            id: nodeButton

            text: "Node"
            active: nodeMenu.opened
            onClicked: nodeMenu.open()
        }

        MenuButton {
            id: runButton

            text: "Run"
            active: runMenu.opened
            onClicked: runMenu.open()
        }

        MenuButton {
            id: windowButton

            text: "Window"
            active: windowMenu.opened
            onClicked: windowMenu.open()
        }

        MenuButton {
            id: helpButton

            text: "Help"
            active: helpMenu.opened
            onClicked: helpMenu.open()
        }

        Item {
            Layout.fillWidth: true
        }
    }

    component AppMenuPopup: Popup {
        id: popupRoot

        property Item owner
        property Popup closeWith
        property var actions: []

        x: owner ? owner.x : 0
        y: root.height - 1
        width: 220
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: colors.menuBarBackground
            border.color: colors.menuBarBorder
            border.width: 1
            radius: 6
        }

        contentItem: ColumnLayout {
            spacing: 2

            Repeater {
                model: popupRoot.actions

                AppMenuItem {
                    text: modelData.text
                    shortcut: modelData.shortcut || ""
                    checked: modelData.checked === undefined ? false : modelData.checked
                    hasSubmenu: modelData.submenu === undefined ? false : modelData.submenu
                    itemEnabled: modelData.enabled === undefined ? true : modelData.enabled

                    onTriggered: {
                        popupRoot.close()

                        if (modelData.text === "Exit") {
                            Qt.quit()
                        } else {
                            if (popupRoot.closeWith) {
                                popupRoot.closeWith.close()
                            }

                            root.actionTriggered(modelData.text)
                        }
                    }
                }
            }
        }
    }

    AppMenuPopup {
        id: fileMenu

        owner: fileButton
        actions: [
            { "text": "New Project", "shortcut": "Ctrl+N" },
            { "text": "Open Project...", "shortcut": "Ctrl+O" },
            { "text": "Save", "shortcut": "Ctrl+S" },
            { "text": "Save As...", "shortcut": "Ctrl+Shift+S" },
            { "text": "Close Project" },
            { "text": "Exit" }
        ]
    }

    AppMenuPopup {
        id: editMenu

        owner: editButton
        actions: [
            { "text": "Undo", "shortcut": "Ctrl+Z" },
            { "text": "Redo", "shortcut": "Ctrl+Y" },
            { "text": "Select All", "shortcut": "Ctrl+A" },
            { "text": "Delete", "shortcut": "Del" },
            { "text": "Preferences...", "shortcut": "Ctrl+," }
        ]
    }

    AppMenuPopup {
        id: viewMenu

        owner: viewButton
        actions: [
            { "text": "View Origin", "shortcut": "Home" },
            { "text": "View Selected", "shortcut": "F" },
            { "text": "View All", "shortcut": "Shift+F" },
            { "text": "Go to Start Node" },
            { "text": "Go to End Node" },
            { "text": "Zoom In", "shortcut": "Ctrl++" },
            { "text": "Zoom Out", "shortcut": "Ctrl+-" },
            { "text": "Reset Zoom", "shortcut": "Ctrl+0" }
        ]
    }

    Popup {
        id: nodeMenu

        x: nodeButton.x
        y: root.height - 1
        width: 220
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: mathMenu.close()

        background: Rectangle {
            color: colors.menuBarBackground
            border.color: colors.menuBarBorder
            border.width: 1
            radius: 6
        }

        contentItem: ColumnLayout {
            spacing: 2

            AppMenuItem {
                text: "Mathematics"
                hasSubmenu: true

                onHovered: mathMenu.open()
                onTriggered: mathMenu.open()
            }
        }
    }

    AppMenuPopup {
        id: mathMenu

        closeWith: nodeMenu
        x: nodeMenu.x + nodeMenu.width + width < root.width ? nodeMenu.x + nodeMenu.width - 2 : nodeMenu.x - width + 2
        y: nodeMenu.y + nodeMenu.padding
        actions: [
            { "text": "Add" },
            { "text": "Sub" },
            { "text": "Mul" },
            { "text": "Button" }
        ]
    }

    AppMenuPopup {
        id: runMenu

        owner: runButton
        actions: [
            { "text": "Run", "shortcut": "Ctrl+R" },
            { "text": "Debug", "shortcut": "F5" },
            { "text": "Stop", "shortcut": "Shift+F5" },
            { "text": "Compute Selected" },
            { "text": "Compute Before" },
            { "text": "Compute After" }
        ]
    }

    AppMenuPopup {
        id: windowMenu

        owner: windowButton
        actions: [
            { "text": "Toolbar", "shortcut": "Ctrl+Alt+T" },
            { "text": "Component Bar", "shortcut": "Ctrl+Alt+C" },
            { "text": "Info Bar", "shortcut": "Ctrl+Alt+I" },
            { "text": "Reset Layout" }
        ]
    }

    AppMenuPopup {
        id: helpMenu

        owner: helpButton
        actions: [
            { "text": "About Node.ai" },
            { "text": "Check for Updates" },
            { "text": "Keyboard Shortcuts" },
            { "text": "Documentation" }
        ]
    }
}
