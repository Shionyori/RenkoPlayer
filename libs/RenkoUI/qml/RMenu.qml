import QtQuick
import QtQuick.Controls
import RenkoUI

Menu {
    id: control

    property color backgroundColor: Theme.surface
    property color borderColor: Theme.border
    property real radius: Theme.radiusSmall

    delegate: RMenuItem { }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 30
        color: control.backgroundColor
        border.color: control.borderColor
        radius: control.radius
    }
}
