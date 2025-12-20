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
    
    background: Rectangle {
        color: "transparent"
        
        // 1. Main Body Background (White, Rounded)
        RPanel {
            anchors.fill: parent
            anchors.topMargin: 30 // Leave space for header
            
            // Remove top radius to merge with header
            radius: Theme.radiusNormal
            
            // Patch to make top corners square (so they join with header)
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: Theme.radiusNormal
                color: parent.color
            }
        }

        // 2. Header Background (Black, Rounded Top)
        Rectangle {
            id: headerBg
            width: parent.width
            height: 30
            anchors.top: parent.top
            color: "#20201F"
            radius: Theme.radiusNormal
            
            // Patch to make bottom corners square
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.radiusNormal
                color: parent.color
            }
            
            // Bottom border for header
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#333333"
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
                    var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                    control.x += delta.x
                    control.y += delta.y
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
                    customBackgroundColor: "transparent"
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