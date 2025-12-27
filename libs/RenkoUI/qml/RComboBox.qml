import QtQuick
import QtQuick.Controls
import RenkoUI

ComboBox {
    id: control

    delegate: ItemDelegate {
        width: control.width
        height: 32
        contentItem: Text {
            text: modelData
            color: Theme.text
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            height: parent.height
            leftPadding: Theme.spacingNormal
        }
        background: Rectangle {
            color: pressed ? Theme.accentPressed : (control.highlightedIndex === index ? Theme.surfaceHighlight : Theme.surface)
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        Connections {
            target: control
            function onPressedChanged() { canvas.requestPaint(); }
        }

        onPaint: {
            context.reset();
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.lineTo(width / 2, height);
            context.closePath();
            context.fillStyle = Theme.text;
            context.fill();
        }
    }

    contentItem: Text {
        leftPadding: Theme.spacingNormal
        rightPadding: control.indicator.width + control.spacing

        text: control.displayText
        font: control.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 35
        color: control.pressed ? Theme.surfaceHighlight : Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusSmall
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        height: Math.min(contentItem.implicitHeight, 200)
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            border.color: Theme.border
            color: Theme.surface
            radius: Theme.radiusSmall
        }
    }
}
