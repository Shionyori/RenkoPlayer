import QtQuick
import QtQuick.Controls
import RenkoUI

Slider {
    id: control

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: Theme.surfaceHighlight

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: control.pressed ? Theme.accentPressed : Theme.accent
            radius: 2
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        radius: 8
        color: Theme.primary
        border.color: Theme.accent
        border.width: 0
        
        // Add a subtle shadow or glow if possible, but keeping it simple for now.
        // Renko's theme: White dot on Brown line (like stars in the sky or her ribbon)
        
        Behavior on x { 
            enabled: !control.pressed
            NumberAnimation { duration: 100 } 
        }
    }
}
