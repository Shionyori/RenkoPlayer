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
    
    property real indicatorWidth: 40
    property real indicatorHeight: 20
    property real handleSize: 16

    indicator: Rectangle {
        implicitWidth: control.indicatorWidth
        implicitHeight: control.indicatorHeight
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: height / 2
        color: control.checked ? control.checkedColor : control.uncheckedColor
        border.color: control.borderColor
        border.width: 1

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: (parent.height - height) / 2
            width: control.handleSize
            height: control.handleSize
            radius: width / 2
            color: control.handleColor
            Behavior on x {
                NumberAnimation { duration: 100 }
            }
        }
    }
}
