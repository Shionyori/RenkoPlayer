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

    property color checkedColor: Theme.accent
    property color uncheckedColor: Theme.surfaceHighlight
    property color handleColor: Theme.primary
    property color borderColor: Theme.border

    indicator: Rectangle {
        implicitWidth: 40
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 10
        color: control.checked ? control.checkedColor : control.uncheckedColor
        border.color: control.borderColor
        border.width: 1

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: 2
            width: 16
            height: 16
            radius: 8
            color: control.handleColor
            Behavior on x {
                NumberAnimation { duration: 100 }
            }
        }
    }
}
