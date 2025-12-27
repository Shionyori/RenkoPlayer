import QtQuick
import QtQuick.Controls
import RenkoUI

CheckBox {
    id: control

    text: qsTr("CheckBox")
    
    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + Theme.spacingSmall
    }

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: Theme.radiusSmall
        border.color: control.down ? Theme.accent : Theme.border
        color: Theme.surface

        Rectangle {
            width: 12
            height: 12
            x: 4
            y: 4
            radius: 2
            color: Theme.accent
            visible: control.checked
        }
    }
}
