import QtQuick
import RenkoUI

Text {
    font.family: Theme.fontFamily
    
    property bool isHeader: false
    property bool isSecondary: false
    
    font.weight: isHeader ? Font.Bold : Font.Normal
    font.pixelSize: isHeader ? Theme.fontSizeHeader : Theme.fontSizeNormal
    color: isSecondary ? Theme.secondary : Theme.text
}
