import QtQuick
import QtQuick.Controls
import RenkoUI

CheckBox {
    id: control

    text: qsTr("CheckBox")
    property color indicatorColor: Theme.surface
    property real indicatorSize: 20
    
    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + Theme.spacingSmall
    }

    indicator: Rectangle {
        implicitWidth: control.indicatorSize
        implicitHeight: control.indicatorSize
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: Theme.radiusSmall
        border.color: control.down ? Theme.accent : Theme.border
        color: control.indicatorColor

        Rectangle {
            width: control.indicatorSize * 0.6
            height: control.indicatorSize * 0.6
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            radius: 2
            color: Theme.accent
            visible: control.checked
        }
    }
}
