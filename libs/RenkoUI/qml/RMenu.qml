import QtQuick
import QtQuick.Controls
import RenkoUI

Menu {
    id: control

    property color backgroundColor: Theme.surface
    property color borderColor: Theme.border
    property real radius: Theme.radiusSmall
    
    property real menuWidth: 200

    delegate: RMenuItem { }

    background: Rectangle {
        implicitWidth: control.menuWidth
        implicitHeight: 30
        color: control.backgroundColor
        border.color: control.borderColor
        radius: control.radius
    }
}
