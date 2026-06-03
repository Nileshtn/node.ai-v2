import QtQuick

TextInput {
    id: control

    property Item nodeTarget: null

    selectByMouse: true

    onEditingFinished: {
        focus = false
    }

    Keys.onPressed: function(event) {
        if (event.key !== Qt.Key_Delete || event.modifiers !== Qt.NoModifier) {
            return
        }

        if (!nodeTarget || !nodeTarget.isSelected) {
            return
        }

        if (control.selectedText.length > 0) {
            return
        }

        if (control.cursorPosition < control.text.length) {
            return
        }

        focus = false
        nodeTarget.deleteRequested()
        event.accepted = true
    }
}
