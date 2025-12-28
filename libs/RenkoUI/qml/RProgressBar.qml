import QtQuick
import QtQuick.Controls
import RenkoUI

ProgressBar {
    id: control

    property color backgroundColor: Theme.surfaceHighlight
    property color progressColor: Theme.accent
    property real radius: 3

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        color: control.backgroundColor
        radius: control.radius
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 4

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: control.radius - 1
            color: control.progressColor
        }
    }
}
