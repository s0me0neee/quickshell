pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Sizes, fonts and motion shared by every part of the shell.
Singleton {
    // Bar: floating glass groups, no full-width background
    readonly property int barMarginTop: 4
    readonly property int barMarginSide: 6
    readonly property int groupHeight: 38
    readonly property int groupPadding: 4
    readonly property int groupGap: 6
    readonly property int circleSize: 30
    // The centre island is the same height as the side groups
    readonly property int islandHeight: groupHeight
    // Height of the bar strip; popouts hang below it. Sized to the tallest thing in it.
    readonly property int barHeight: islandHeight

    // Shapes. The panel radius is a setting; the item radius follows it so a rounder
    // panel doesn't end up with square rows inside it
    readonly property int radiusPanel: Settings.data.radiusPanel
    readonly property int radiusItem: Math.round(radiusPanel * 14 / 24)

    // Spacing
    readonly property int spacingSmall: 4
    readonly property int spacing: 8
    readonly property int spacingLarge: 12
    readonly property int popoutGap: 6

    // Fonts
    readonly property string fontFamily: "JetBrains Mono"
    readonly property string iconFamily: "FiraCode Nerd Font"
    readonly property int fontSize: Settings.data.fontSize
    readonly property int fontSizeSmall: fontSize - 2
    readonly property int iconSize: 18
    // App icons come from the icon theme rather than the font, and a theme only holds
    // artwork at the sizes it ships. Ask for one it doesn't have and Qt renders the
    // nearest and rescales it, which is what left the tray looking smeared at 18. These
    // two are the freedesktop panel and menu sizes, so every theme has a clean entry.
    readonly property int themeIconSize: 22
    readonly property int themeIconSizeSmall: 16

    // State layer opacities, one scale for every interactive surface (see
    // components/StateLayer.qml). Material's values; `active` is ours, for a toggle
    // that is currently on.
    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.1
    readonly property real statePress: 0.12
    readonly property real stateActive: 0.18

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
