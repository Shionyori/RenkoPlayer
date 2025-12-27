import QtQuick
import QtQuick.Controls
import RenkoUI

Button {
    id: control

    property color customBackgroundColor: Theme.surface
    property color customAccentColor: Theme.accent
    property bool isIconOnly: false
    property string tooltip: ""
    ToolTip.text: tooltip

    ToolTip.visible: hovered && tooltip.length > 0
    ToolTip.delay: 500
    ToolTip.timeout: 5000

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal
    
    display: isIconOnly ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon
    palette.buttonText: control.highlighted ? Theme.textInverse : Theme.text

    background: Rectangle {
        implicitWidth: Math.max(control.isIconOnly ? 36 : 80, control.contentItem.implicitWidth + 32)
        implicitHeight: 36
        radius: Theme.radiusNormal
        color: {
            if (!control.enabled) return Theme.background
            if (control.down) return control.highlighted ? Qt.darker(control.customAccentColor, 1.2) : Qt.darker(Theme.surfaceHighlight, 1.1)
            if (control.hovered) return control.highlighted ? Qt.lighter(control.customAccentColor, 1.1) : Theme.surfaceHighlight
            return control.highlighted ? control.customAccentColor : control.customBackgroundColor
        }
        border.color: (control.highlighted || control.flat) ? "transparent" : Theme.border
        border.width: (control.highlighted || control.flat) ? 0 : 1
        
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
