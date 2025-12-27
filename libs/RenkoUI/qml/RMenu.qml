import QtQuick
import QtQuick.Controls
import RenkoUI

Menu {
    id: control

    delegate: RMenuItem { }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 30
        color: Theme.surface
        border.color: Theme.border
        radius: Theme.radiusSmall
    }
}
