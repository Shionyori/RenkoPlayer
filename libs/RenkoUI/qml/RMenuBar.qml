import QtQuick
import QtQuick.Controls
import RenkoUI

MenuBar {
    id: control

    delegate: MenuBarItem {
        id: menuBarItem
        font.pixelSize: Theme.fontSizeNormal

        contentItem: Text {
            text: menuBarItem.text
            font: menuBarItem.font
            opacity: enabled ? 1.0 : 0.3
            color: menuBarItem.highlighted ? Theme.textInverse : Theme.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 60
            implicitHeight: 30
            opacity: enabled ? 1 : 0.3
            color: menuBarItem.highlighted ? Theme.accent : "transparent"
            radius: Theme.radiusSmall
        }
    }

    background: Rectangle {
        color: Theme.surface
    }
}
