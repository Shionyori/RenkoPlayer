import QtQuick
import QtQuick.Controls
import RenkoUI

Switch {
    id: control

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + Theme.spacingSmall
    }

    indicator: Rectangle {
        implicitWidth: 40
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 10
        color: control.checked ? Theme.accent : Theme.surfaceHighlight
        border.color: Theme.border
        border.width: 1

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: 2
            width: 16
            height: 16
            radius: 8
            color: Theme.primary
            Behavior on x {
                NumberAnimation { duration: 100 }
            }
        }
    }
}
