import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RenkoUI

RDialog {
    id: control
    
    property string text: ""
    property string informativeText: ""
    property color textColor: Theme.text
    property color informativeTextColor: Theme.text
    
    // Default width constraint
    width: Math.min(400, parent ? parent.width * 0.9 : 400)
    
    standardButtons: Dialog.Ok

    Item {
        width: parent.width
        height: layout.implicitHeight + Theme.spacingLarge * 2

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingNormal
            
            RLabel {
            text: control.text
            font.pixelSize: Theme.fontSizeNormal
            font.bold: true
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            visible: text !== ""
            color: control.textColor
        }
        
        RLabel {
            text: control.informativeText
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            visible: text !== ""
            color: control.informativeTextColor
            opacity: 0.8
        }
    }
}}