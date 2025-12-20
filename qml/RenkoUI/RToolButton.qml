import QtQuick
import QtQuick.Controls
import RenkoUI

ToolButton {
    id: control

    property string tooltip: ""
    ToolTip.text: tooltip

    ToolTip.visible: hovered && tooltip.length > 0
    ToolTip.delay: 500
    ToolTip.timeout: 5000

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    palette.buttonText: control.highlighted ? Theme.accent : Theme.text
    
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        color: control.down ? Theme.surfaceHighlight : "transparent"
        radius: Theme.radiusSmall
        border.color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceHighlight
            opacity: control.hovered && !control.down ? 0.5 : 0
            radius: Theme.radiusSmall
        }
    }
}
