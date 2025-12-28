import QtQuick
import QtQuick.Controls
import RenkoUI

TextField {
    id: control

    property color backgroundColor: control.enabled ? Theme.surface : Theme.background

    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.textInverse
    placeholderTextColor: Theme.secondary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 36
        color: control.backgroundColor
        border.color: control.activeFocus ? Theme.accent : Theme.border
        border.width: control.activeFocus ? 2 : 1
        radius: Theme.radiusSmall
        
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }
}
