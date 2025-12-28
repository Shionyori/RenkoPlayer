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

    property color hoverColor: Theme.surfaceHighlight
    property color downColor: Theme.surfaceHighlight
    property real radius: Theme.radiusSmall

    palette.buttonText: control.highlighted ? Theme.accent : Theme.text
    
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        color: control.down ? control.downColor : "transparent"
        radius: control.radius
        border.color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            color: control.hoverColor
            opacity: control.hovered && !control.down ? 0.5 : 0
            radius: control.radius
        }
    }
}
