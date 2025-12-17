import QtQuick
import QtQuick.Controls
import RenkoUI

ProgressBar {
    id: control

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        color: Theme.surfaceHighlight
        radius: 3
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 4

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }
}
