import QtQuick
import QtQuick.Controls
import RenkoUI

ScrollBar {
    id: control

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 100
        radius: width / 2
        color: control.pressed ? Theme.accentPressed : (control.hovered ? Theme.accentHover : Theme.surfaceHighlight)
        opacity: control.policy === ScrollBar.AlwaysOn || (control.active && control.size < 1.0) ? 0.75 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    
    background: Rectangle {
        implicitWidth: 6
        implicitHeight: 100
        color: "transparent"
    }
}
