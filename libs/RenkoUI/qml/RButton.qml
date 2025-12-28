import QtQuick
import QtQuick.Controls
import RenkoUI

Button {
    id: control

    property color backgroundColor: Theme.surface
    property color accentColor: Theme.accent
    property color textColor: control.highlighted ? Theme.textInverse : Theme.text
    property color borderColor: Theme.border
    property real borderWidth: 1
    property real radius: Theme.radiusNormal

    property bool isIconOnly: false
    property string tooltip: ""
    ToolTip.text: tooltip

    ToolTip.visible: hovered && tooltip.length > 0
    ToolTip.delay: 500
    ToolTip.timeout: 5000

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal
    
    display: isIconOnly ? AbstractButton.IconOnly : AbstractButton.TextBesideIcon
    palette.buttonText: textColor

    background: Rectangle {
        implicitWidth: Math.max(control.isIconOnly ? 36 : 80, control.contentItem.implicitWidth + 32)
        implicitHeight: 36
        radius: control.radius
        color: {
            if (!control.enabled) return Theme.background
            if (control.down) return control.highlighted ? Qt.darker(control.accentColor, 1.2) : Qt.darker(Theme.surfaceHighlight, 1.1)
            if (control.hovered) return control.highlighted ? Qt.lighter(control.accentColor, 1.1) : Theme.surfaceHighlight
            return control.highlighted ? control.accentColor : control.backgroundColor
        }
        border.color: (control.highlighted || control.flat) ? "transparent" : control.borderColor
        border.width: (control.highlighted || control.flat) ? 0 : control.borderWidth
        
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
