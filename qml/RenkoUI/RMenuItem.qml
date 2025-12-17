import QtQuick
import QtQuick.Controls
import RenkoUI

MenuItem {
    id: control

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.highlighted ? Theme.textInverse : Theme.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 30
        opacity: enabled ? 1 : 0.3
        color: control.highlighted ? Theme.accent : "transparent"
        radius: Theme.radiusSmall
    }
}
