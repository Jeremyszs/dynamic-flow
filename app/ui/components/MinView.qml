import QtQuick
import "."

Item {
    id: root

    function dp(px) { return controller.scaler.dp(px); }
    function sp(px) { return controller.scaler.sp(px); }

    // Left Half: Fleet Agent Telemetry (x = 0 to parent.width/2 - 1)
    Item {
        id: fleetSection
        anchors.left: parent.left
        anchors.right: centerDivider.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        // Status Dot on Left: x = dp(16)
        StatusDot {
            id: fleetDot
            x: root.dp(16) - (width / 2)
            anchors.verticalCenter: parent.verticalCenter
            active: controller.fleetState === "BUSY"
            error: false
        }

        // Active Agent / Fleet Idle Text: x = dp(28)
        Text {
            id: fleetText
            x: root.dp(28)
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.dp(10)
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
        height: root.dp(16)
        color: "#262629"
    }

    // Right Half: 9Router Spend / Token Telemetry
    Item {
        id: routerSection
        anchors.left: centerDivider.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        clip: true

        Text {
            id: metricsText
            anchors.right: parent.right
            anchors.rightMargin: root.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            color: {
                if (controller.flyingDeltaText !== "") return "#30D158";
                if (controller.isHovered) return "#f59e0b";
                return "#FFFFFF";
            }
            font.family: "SF Pro Display"
            font.pointSize: 9
            font.bold: true
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
