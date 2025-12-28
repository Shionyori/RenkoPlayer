import QtQuick
import QtQuick.Controls
import RenkoUI

ScrollBar {
    id: control

    property color handleColor: Theme.surfaceHighlight
    property color handleHoverColor: Theme.accentHover
    property color handlePressedColor: Theme.accentPressed
    property color backgroundColor: "transparent"
    
    property real thickness: 6

    contentItem: Rectangle {
        implicitWidth: control.orientation === Qt.Vertical ? control.thickness : 100
        implicitHeight: control.orientation === Qt.Horizontal ? control.thickness : 100
        radius: control.thickness / 2
        color: control.pressed ? control.handlePressedColor : (control.hovered ? control.handleHoverColor : control.handleColor)
        opacity: control.policy === ScrollBar.AlwaysOn || (control.active && control.size < 1.0) ? 0.75 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    
    background: Rectangle {
        implicitWidth: control.orientation === Qt.Vertical ? control.thickness : 100
        implicitHeight: control.orientation === Qt.Horizontal ? control.thickness : 100
        color: control.backgroundColor
    }
}
