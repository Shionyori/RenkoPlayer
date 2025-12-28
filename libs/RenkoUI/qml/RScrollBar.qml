import QtQuick
import QtQuick.Controls
import RenkoUI

ScrollBar {
    id: control

    property color handleColor: Theme.surfaceHighlight
    property color handleHoverColor: Theme.accentHover
    property color handlePressedColor: Theme.accentPressed
    property color backgroundColor: "transparent"

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 100
        radius: width / 2
        color: control.pressed ? control.handlePressedColor : (control.hovered ? control.handleHoverColor : control.handleColor)
        opacity: control.policy === ScrollBar.AlwaysOn || (control.active && control.size < 1.0) ? 0.75 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    
    background: Rectangle {
        implicitWidth: 6
        implicitHeight: 100
        color: control.backgroundColor
    }
}
