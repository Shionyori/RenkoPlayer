import QtQuick
import QtQuick.Controls
import RenkoUI

MenuItem {
    id: control

    property color highlightColor: Theme.accent
    property color textColor: Theme.text
    property color highlightTextColor: Theme.textInverse

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.highlighted ? control.highlightTextColor : control.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 30
        opacity: enabled ? 1 : 0.3
        color: control.highlighted ? control.highlightColor : "transparent"
        radius: Theme.radiusSmall
    }
}
