import QtQuick
import QtQuick.Controls
import RenkoUI

Slider {
    id: control

    property color trackColor: Theme.surfaceHighlight
    property color progressColor: Theme.accent
    property color handleColor: Theme.primary
    property color handleBorderColor: Theme.accent
    property int handleBorderWidth: 0
    property int handleSize: 16

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: control.trackColor

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: control.pressed ? Theme.accentPressed : control.progressColor
            radius: 2
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: control.handleSize
        implicitHeight: control.handleSize
        radius: control.handleSize / 2
        color: control.handleColor
        border.color: control.handleBorderColor
        border.width: control.handleBorderWidth
        
        Behavior on x { 
            enabled: !control.pressed
            NumberAnimation { duration: 100 } 
        }
    }
}
