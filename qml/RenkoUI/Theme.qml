pragma Singleton
import QtQuick

QtObject {
    // Renko Usami Color Palette (Desaturated Light Version)
    // Lighter brown, lower saturation, soft greyish surfaces

    readonly property color background: "#F0F0F0" // Very Light Grey
    readonly property color surface: "#FAFAFA"    // Almost White Surface (Slightly Grey)
    readonly property color surfaceHighlight: "#EEEEEE" // Subtle Hover

    readonly property color accent: "#A1887F"      // Lighter Brown (Desaturated)
    readonly property color accentHover: "#BCAAA4" // Very Light Brown
    readonly property color accentPressed: "#8D6E63" // Previous Base Brown

    readonly property color primary: "#616161"     // Soft Grey (Hat)
    readonly property color secondary: "#9E9E9E"   // Light Grey

    readonly property color text: "#424242"        // Soft Dark Text
    readonly property color textInverse: "#FFFFFF" // Text on accent

    readonly property color border: "#E0E0E0"      // Very Subtle Border
    readonly property color divider: "#EEEEEE"

    readonly property color success: "#81C784"     // Pastel Green
    readonly property color error: "#E57373"       // Pastel Red
    readonly property color warning: "#FFB74D"     // Pastel Orange

    // Typography
    readonly property string fontFamily: "Segoe UI, Roboto, Helvetica, Arial, sans-serif"
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeHeader: 24

    // Spacing & Radius
    readonly property int radiusSmall: 4
    readonly property int radiusNormal: 8
    readonly property int radiusLarge: 12

    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 16
}
