import QtQuick
import QtQuick.Controls
import RenkoUI

ApplicationWindow {
    id: window
    
    property color backgroundColor: Theme.background
    
    color: backgroundColor
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    // Default background for the window
    background: Rectangle {
        color: window.backgroundColor
    }
    
    // You might want to add a custom title bar here later if you go frameless
}
