import QtQuick
import QtQuick.Controls
import RenkoUI

MenuBar {
    id: control

    property color backgroundColor: Theme.surface
    property color itemHighlightColor: Theme.accent
    property color itemTextColor: Theme.text
    property color itemHighlightTextColor: Theme.textInverse

    delegate: MenuBarItem {
        id: menuBarItem
        font.pixelSize: Theme.fontSizeNormal

        contentItem: Text {
            text: menuBarItem.text
            font: menuBarItem.font
            opacity: enabled ? 1.0 : 0.3
            color: menuBarItem.highlighted ? control.itemHighlightTextColor : control.itemTextColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 60
            implicitHeight: 30
            opacity: enabled ? 1 : 0.3
            color: menuBarItem.highlighted ? control.itemHighlightColor : "transparent"
            radius: Theme.radiusSmall
        }
    }

    background: Rectangle {
        color: control.backgroundColor
    }
}
