import QtQuick
import QtQuick.Controls
import RenkoUI

Button {
    id: control

    property color customBackgroundColor: Theme.surface
    property color customAccentColor: Theme.accent
    property bool isIconOnly: false

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal
    
    display: isIconOnly ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon
    palette.buttonText: control.highlighted ? Theme.textInverse : Theme.text

    background: Rectangle {
        implicitWidth: control.isIconOnly ? 36 : 100
        implicitHeight: 36
        radius: Theme.radiusNormal
        color: {
            if (!control.enabled) return Theme.background
            if (control.down) return control.highlighted ? Qt.darker(control.customAccentColor, 1.2) : Qt.darker(Theme.surfaceHighlight, 1.1)
            if (control.hovered) return control.highlighted ? Qt.lighter(control.customAccentColor, 1.1) : Theme.surfaceHighlight
            return control.highlighted ? control.customAccentColor : control.customBackgroundColor
        }
        border.color: control.highlighted ? "transparent" : Theme.border
        border.width: control.highlighted ? 0 : 1
        
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
