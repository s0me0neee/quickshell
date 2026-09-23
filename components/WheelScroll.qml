import QtQuick

// Touchpad scrolling at a usable speed in a Flickable. Hyprland's touchpad scroll_factor
// is 0.2 here, which suits apps that accelerate on their own, but Qt moves a list by the
// raw pixel delta, so a swipe crawled. Wheel notches carry no pixel delta and keep Qt's step.
WheelHandler {
    id: root

    required property Flickable view
    property real touchpadFactor: 5

    target: null

    onWheel: event => {
        const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y * touchpadFactor : event.angleDelta.y;
        const top = view.originY;
        const bottom = view.originY + Math.max(0, view.contentHeight - view.height);
        view.cancelFlick();
        view.contentY = Math.max(top, Math.min(bottom, view.contentY - dy));
        event.accepted = true;
    }
}
