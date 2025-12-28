import QtQuick
import RenkoUI

Rectangle {
    id: control

    property color backgroundColor: Theme.surface
    property color borderColor: Theme.border
    property real borderWidth: 1
    
    color: backgroundColor
    radius: Theme.radiusNormal
    border.color: borderColor
    border.width: borderWidth
    
    // Default padding for content inside
    property int padding: Theme.spacingNormal
}
