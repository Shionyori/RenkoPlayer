import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RenkoUI

Popup {
    id: control

    default property alias contentData: contentArea.data
    property string title: ""
    property url iconSource: ""
    property int standardButtons: Dialog.NoButton
    
    signal accepted()
    signal rejected()

    function accept() {
        accepted()
        close()
    }

    function reject() {
        rejected()
        close()
    }

    // Popup properties
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape
    
    // Center manually on show to allow smooth dragging
    onAboutToShow: {
        if (parent) {
            x = (parent.width - width) / 2
            y = (parent.height - height) / 2 - 48
        }
    }

    // Styling
    padding: 0
    
    property color headerColor: "#20201F"
    property color headerBorderColor: "#333333"
    property color backgroundColor: Theme.surface
    property real radius: Theme.radiusNormal

    background: Rectangle {
        color: "transparent"
        
        // 1. Main Body Background (White, Rounded)
        RPanel {
            anchors.fill: parent
            anchors.topMargin: 30 // Leave space for header
            
            // Remove top radius to merge with header
            radius: control.radius
            backgroundColor: control.backgroundColor
            
            // Patch to make top corners square (so they join with header)
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: control.radius
                color: parent.color
            }
        }

        // 2. Header Background (Black, Rounded Top)
        Rectangle {
            id: headerBg
            width: parent.width
            height: 30
            anchors.top: parent.top
            color: control.headerColor
            radius: control.radius
            
            // Patch to make bottom corners square
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: control.radius
                color: parent.color
            }
            
            // Bottom border for header
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: control.headerBorderColor
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            
            // Drag Handler
            MouseArea {
                anchors.fill: parent
                property point clickPos
                onPressed: (mouse) => { 
                    clickPos = Qt.point(mouse.x, mouse.y) 
                }
                onPositionChanged: (mouse) => {
                    var deltaX = mouse.x - clickPos.x
                    var deltaY = mouse.y - clickPos.y
                    
                    var newX = control.x + deltaX
                    var newY = control.y + deltaY
                    
                    if (control.parent) {
                        newX = Math.max(0, Math.min(newX, control.parent.width - control.width))
                        newY = Math.max(0, Math.min(newY, control.parent.height - control.height))
                    }
                    
                    control.x = newX
                    control.y = newY
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingNormal
                anchors.rightMargin: Theme.spacingSmall
                spacing: Theme.spacingSmall

                Image {
                    id: iconImage
                    source: control.iconSource
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: control.iconSource.toString() !== ""
                }

                Label {
                    Layout.fillWidth: true
                    text: control.title
                    elide: Label.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.bold: true
                    color: "white"
                }

                RButton {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    text: "✕"
                    isIconOnly: true
                    flat: true
                    backgroundColor: "transparent"
                    onClicked: control.reject()
                    
                    // Custom hover for close button (red)
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: parent.hovered ? "#E81123" : "transparent"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Content Area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: childrenRect.height
            implicitWidth: childrenRect.width
        }

        // Footer
        DialogButtonBox {
            id: buttonBox
            visible: count > 0
            standardButtons: control.standardButtons
            
            background: Rectangle { color: "transparent" }
            alignment: Qt.AlignRight
            Layout.fillWidth: true
            
            delegate: RButton {
                Layout.margins: Theme.spacingSmall
            }
            
            padding: Theme.spacingNormal
            
            onAccepted: control.accept()
            onRejected: control.reject()
        }
    }
}