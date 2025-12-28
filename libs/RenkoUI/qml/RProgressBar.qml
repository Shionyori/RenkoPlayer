import QtQuick
import QtQuick.Controls
import RenkoUI

ProgressBar {
    id: control

    property color backgroundColor: Theme.surfaceHighlight
    property color progressColor: Theme.accent
    property real radius: 3
    
    property real preferredHeight: 6
    property real preferredWidth: 200

    background: Rectangle {
        implicitWidth: control.preferredWidth
        implicitHeight: control.preferredHeight
        color: control.backgroundColor
        radius: control.radius
    }

    contentItem: Item {
        implicitWidth: control.preferredWidth
        implicitHeight: control.preferredHeight - 2

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: control.radius - 1
            color: control.progressColor
        }
    }
}
