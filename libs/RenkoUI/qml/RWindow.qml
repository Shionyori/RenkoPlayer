import QtQuick
import QtQuick.Controls
import RenkoUI

ApplicationWindow {
    id: window
    
    color: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeNormal

    // Default background for the window
    background: Rectangle {
        color: window.color
    }
    
    // You might want to add a custom title bar here later if you go frameless
}
