import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.ToolButton {
    id: root

    property string toolTipText: ""
    // Honor configured buttonSize (upstream hardcodes iconSizes and clips in thin panels)
    readonly property int btn: Math.max(14, Plasmoid.configuration.buttonSize || 18)
    readonly property int ico: Math.max(10, btn - 4)

    Layout.preferredWidth: btn
    Layout.preferredHeight: btn
    Layout.minimumWidth: btn
    Layout.minimumHeight: btn
    Layout.maximumWidth: btn
    Layout.maximumHeight: btn

    implicitWidth: btn
    implicitHeight: btn

    flat: true
    hoverEnabled: true
    text: ""
    padding: 0
    display: PlasmaComponents3.AbstractButton.IconOnly

    icon.width: ico
    icon.height: ico

    opacity: enabled ? 1.0 : 0.45

    scale: hovered && Plasmoid.configuration.enableHoverEffect ? 1.06 : 1.0

    Behavior on scale {
        enabled: Plasmoid.configuration.enableAnimations
        NumberAnimation {
            duration: Math.max(80, Plasmoid.configuration.animationDuration / 2)
            easing.type: Easing.OutCubic
        }
    }

    PlasmaComponents3.ToolTip.text: root.toolTipText
    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
}
