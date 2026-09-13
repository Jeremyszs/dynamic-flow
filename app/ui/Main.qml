import QtQuick
import QtQuick.Window
import "components"

Window {
    id: window
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool

    width: controller.targetWidth
    height: controller.targetHeight
    x: controller.targetX
    y: controller.targetY

    Connections {
        target: controller
        function onViewChanged() {
            window.x = controller.targetX;
            window.y = controller.targetY;
        }
    }

    onScreenChanged: {
        if (controller && controller.updateScreenDpr) {
            controller.updateScreenDpr(window.screen);
        }
    }
    Component.onCompleted: {
        if (controller && controller.updateScreenDpr) {
            controller.updateScreenDpr(window.screen);
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuad
        }
    }
    Behavior on x {
        id: xAnim
        enabled: !window.isDragging
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }
    Behavior on y {
        id: yAnim
        enabled: !window.isDragging
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    // Dragging state
    property point dragStartCursor: Qt.point(0, 0)
    property point dragStartWinPos: Qt.point(0, 0)
    property bool isDragging: false
    property bool wasDragged: false

    function endDragAndClamp() {
        if (window.wasDragged) {
            window.isDragging = false;
            window.wasDragged = false;
            var res = controller.clampGeometry(window.x, window.y, window.width, window.height);
            window.x = res[0];
            window.y = res[1];
        }
    }

    // Root Container
    Item {
        id: rootContainer
        anchors.fill: parent

        // Single Island Capsule (No Split Bubble)
        IslandCapsule {
            id: mainCapsule
            anchors.fill: parent
            cornerRadius: controller.targetRadius
            isDockedNotch: controller.isDockedNotch
            isHovered: controller.isHovered
            isActivityActive: controller.isActivityActive || controller.fleetState === "BUSY"
            isActivityError: controller.isActivityError
        }

        // Min View Content
        MinView {
            id: minView
            objectName: "minView"
            visible: controller ? (controller.currentView === "min") : true
            enabled: visible
            opacity: visible ? 1.0 : 0.0
            anchors.fill: parent
            clip: true
            z: 1
        }

        // Normal View Content
        NormalView {
            id: normalView
            visible: controller ? (controller.currentView === "normal") : false
            enabled: visible
            opacity: visible ? 1.0 : 0.0
            anchors.fill: parent
            clip: true
            z: 5
        }

        // Detailed View Content
        DetailedView {
            id: detailedView
            visible: controller ? (controller.currentView === "detailed") : false
            enabled: visible
            opacity: visible ? 1.0 : 0.0
            anchors.fill: parent
            clip: true
            z: 100
        }

        // Background Window Drag Area
        MouseArea {
            id: windowDragArea
            anchors.fill: parent
            visible: controller ? (controller.currentView !== "detailed") : true
            enabled: visible
            z: -1
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.ArrowCursor

            onEntered: {
                controller.setHovered(true);
            }
            onExited: {
                controller.setHovered(false);
            }

            onPressed: function(mouse) {
                if (detailedView.visible && mouse.x > detailedView.width - 45 && mouse.y < 45) {
                    controller.quitApp();
                    return;
                }
                if (mouse.button === Qt.LeftButton) {
                    controller.startWindowDrag();
                    window.isDragging = false;
                    window.wasDragged = false;
                } else if (mouse.button === Qt.RightButton) {
                    controller.toggleDetailed();
                }
            }

            onPositionChanged: function(mouse) {
                if (mouse.buttons & Qt.LeftButton) {
                    var npos = controller.updateWindowDrag();
                    var nx = npos[0];
                    var ny = npos[1];
                    if (Math.abs(nx - window.x) > 2 || Math.abs(ny - window.y) > 2) {
                        window.isDragging = true;
                        window.wasDragged = true;
                        window.x = nx;
                        window.y = ny;
                    }
                }
            }

            onReleased: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    if (window.wasDragged) {
                        window.endDragAndClamp();
                    } else if (controller.currentView !== "detailed") {
                        controller.cycleView();
                    }
                }
            }
        }
    }
}
