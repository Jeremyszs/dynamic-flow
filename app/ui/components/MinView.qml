import QtQuick
import "."

Item {
    id: root
    anchors.fill: parent

    function dp(px) { return controller.scaler.dp(px); }
    function sp(px) { return controller.scaler.sp(px); }

    // Interactive view cycle & drag on min view
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: function(mouse) {
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
                } else {
                    controller.cycleView();
                }
            }
        }
        onEntered: controller.setHovered(true)
        onExited: controller.setHovered(false)
    }

    // Left Half: Fleet Agent Telemetry (Left margin: dp(14))
    Item {
        id: fleetSection
        anchors.left: parent.left
        anchors.leftMargin: root.dp(16)
        anchors.right: centerDivider.left
        anchors.rightMargin: root.dp(12)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        // Status Dot on Left
        StatusDot {
            id: fleetDot
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            active: controller.fleetState === "BUSY"
            error: false
        }

        // Active Agent / Fleet Idle Text
        Text {
            id: fleetText
            anchors.left: fleetDot.right
            anchors.leftMargin: root.dp(8)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: controller.activeAgent
            color: controller.fleetState === "BUSY" ? "#38bdf8" : "#9ca3af"
            font.family: "SF Pro Display"
            font.pointSize: 9
            font.bold: true
            elide: Text.ElideRight
        }
    }

    // Centered Dividing Line (Vertical divider)
    Rectangle {
        id: centerDivider
        anchors.centerIn: parent
        width: 1
        height: root.dp(14)
        color: "#262629"
    }

    // Right Half: 9Router Spend / Token Telemetry
    Item {
        id: routerSection
        anchors.left: centerDivider.right
        anchors.leftMargin: root.dp(12)
        anchors.right: parent.right
        anchors.rightMargin: root.dp(16)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        Text {
            id: metricsText
            anchors.right: parent.right
            anchors.left: parent.left
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            color: {
                if (controller.flyingDeltaText !== "") return "#30D158";
                if (controller.isHovered) return "#f59e0b";
                return "#FFFFFF";
            }
            font.family: "SF Pro Display"
            font.pointSize: 9
            font.bold: true
            elide: Text.ElideRight
            text: {
                if (controller.flyingDeltaText !== "") {
                    return controller.flyingDeltaText;
                }
                if (controller.isHovered) {
                    var peekParts = [];
                    if (controller.latestTpsStr !== "") peekParts.push(controller.latestTpsStr);
                    if (controller.primaryResetTimeLeft !== "") peekParts.push("Resets " + controller.primaryResetTimeLeft);
                    if (peekParts.length > 0) return peekParts.join(" • ");
                    return "Peek Ready";
                }
                return controller.totalTokensStr + " tok • " + controller.costStr;
            }
        }
    }
}
