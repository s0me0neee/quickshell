pragma Singleton

import QtQuick
import Quickshell

// Sizes, fonts and motion shared by every part of the shell.
Singleton {
    // Bar: floating glass groups, no full-width background
    readonly property int barMarginTop: 5
    readonly property int barMarginSide: 6
    readonly property int groupHeight: 34
    readonly property int groupPadding: 4
    readonly property int groupGap: 6
    readonly property int circleSize: 26
    // The centre island stands a little taller than the side groups
    readonly property int islandHeight: 42
    // Height of the bar strip; popouts hang below it. Sized to the tallest thing in it.
    readonly property int barHeight: islandHeight

    // Shapes
    readonly property int radiusPanel: 24
    readonly property int radiusItem: 14

    // Spacing
    readonly property int spacingSmall: 4
    readonly property int spacing: 8
    readonly property int spacingLarge: 12
    readonly property int popoutGap: 6

    // Fonts
    readonly property string fontFamily: "JetBrains Mono"
    readonly property string iconFamily: "FiraCode Nerd Font"
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 12
    readonly property int iconSize: 16

    // Motion
    readonly property int animFast: 150
    readonly property int animNormal: 300
    readonly property int animSlow: 400
    readonly property list<real> curveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> curveEmphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    // Slight overshoot, for things that stretch or pop
    readonly property list<real> curveExpressive: [0.38, 1.21, 0.22, 1, 1, 1]
    // Island morph: springy when growing, calm when shrinking
    readonly property int expandDuration: 500
    readonly property int shrinkDuration: 360
    readonly property list<real> curveExpand: [0.1, 0.68, 0.28, 1.02, 0.64, 1.035, 0.78, 1.035, 0.96, 1, 1, 1]
    readonly property list<real> curveShrink: [0.16, 0.68, 0.36, 1, 1, 1]
}
