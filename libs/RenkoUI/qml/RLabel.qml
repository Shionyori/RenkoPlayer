import QtQuick
import RenkoUI

Text {
    font.family: Theme.fontFamily
    
    property bool isHeader: false
    property bool isSecondary: false
    property color textColor: isSecondary ? Theme.secondary : Theme.text
    property int textSize: isHeader ? Theme.fontSizeHeader : Theme.fontSizeNormal
    
    font.weight: isHeader ? Font.Bold : Font.Normal
    font.pixelSize: textSize
    color: textColor
}
