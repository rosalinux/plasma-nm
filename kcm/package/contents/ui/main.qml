/*
    Copyright 2016-2018 Jan Grulich <jgrulich@redhat.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import "editor"

import QtQuick 2.6
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.kcm 1.2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.kirigami 2.12 as Kirigami

ScrollViewKCM {
    id: root

    ConfigModule.quickHelp: i18n("Connections")

    title: i18n("Edit your Network Connections")

    property bool currentConnectionExportable: false
    property string currentConnectionName
    property string currentConnectionPath

    property QtObject connectionSettingsObject: kcm.connectionSettings

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active
    }

    PlasmaNM.Handler {
        id: handler
    }

    PlasmaNM.KcmIdentityModel {
        id: connectionModel
    }

    PlasmaNM.EditorProxyModel {
        id: editorProxyModel

        sourceModel: connectionModel
    }

    header: Kirigami.SearchField {
        id: searchField

        focus: true
        onTextChanged: {
            editorProxyModel.setFilterRegExp(text)
        }
    }


    view: ListView {
        id: connectionView
        model: editorProxyModel
        currentIndex: -1
        activeFocusOnTab: true
        keyNavigationWraps: true
        Accessible.role: Accessible.List
        Keys.onTabPressed: {
            if (applicationWindow().wideScreen && root.pageStack.depth > 1) {
                connectionEditor.focus = true;
            }
        }

        section {
            property: "KcmConnectionType"
            delegate: Kirigami.ListSectionHeader {
                text: section
            }
        }

        delegate: ConnectionItemDelegate {
            width: connectionView.width
            onAboutToChangeConnection: {
                // Shouldn't be problem to set this in advance
                root.currentConnectionExportable = exportable
                if (kcm.needsSave) {
                    confirmSaveDialog.connectionName = name
                    confirmSaveDialog.connectionPath = path
                    confirmSaveDialog.open()
                } else {
                    selectConnectionInView(name, path)
                }
            }

            onAboutToExportConnection: {
                requestExportConnection(path)
            }

            onAboutToRemoveConnection: {
                deleteConfirmationDialog.connectionName = name
                deleteConfirmationDialog.connectionPath = path
                deleteConfirmationDialog.open()
            }
        }
    }

    footer: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Button {
            id: configureButton

            icon.name: "configure"

            Layout.alignment: Qt.AlignLeft

            QQC2.ToolTip.text: i18n("Configuration")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                configPopup.open()
            }

            PlasmaNM.Configuration {
                id: configuration
            }

            QQC2.Popup {
                id: configPopup
                x: 0
                y: -height
                modal: true
                focus: true

                Kirigami.FormLayout {
                    QQC2.CheckBox {
                        text: i18n("Ask for PIN on modem detection")
                        onToggled: configuration.unlockModemOnDetection = checked
                        Component.onCompleted: checked = configuration.unlockModemOnDetection
                    }

                    QQC2.CheckBox {
                        text: i18n("Show virtual connections")
                        onToggled: configuration.manageVirtualConnections = checked
                        Component.onCompleted: checked = configuration.manageVirtualConnections
                    }
                }
            }
        }

        QQC2.CheckBox {
            id: expertModeCheckbox
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            text: i18n("Enable expert mode")
        }

        QQC2.Button {
            id: exportConnectionButton
            Layout.alignment: Qt.AlignRight

            enabled: root.currentConnectionExportable
            icon.name: "document-export"

            QQC2.ToolTip.text: i18n("Export selected connection")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                kcm.requestExportConnection(root.currentConnectionPath)
            }
        }

        QQC2.Button {
            id: removeConnectionButton
            Layout.alignment: Qt.AlignRight

            enabled: root.currentConnectionPath && root.currentConnectionPath.length
            icon.name: "list-remove"

            QQC2.ToolTip.text: i18n("Remove selected connection")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                deleteConfirmationDialog.connectionName = root.currentConnectionName
                deleteConfirmationDialog.connectionPath = root.currentConnectionPath
                deleteConfirmationDialog.open()
            }
        }

        QQC2.Button {
            id: addConnectionButton
            Layout.alignment: Qt.AlignRight

            icon.name: "list-add"

            QQC2.ToolTip.text: i18n("Add new connection")
            QQC2.ToolTip.visible: hovered

            onClicked: addNewConnectionSheet.open()
        }

        QQC2.Button {
            visible: handler.hotspotSupported
            icon.name: "network-wireless-hotspot"

            QQC2.ToolTip.text: i18n("Configure Hotspot")
            QQC2.ToolTip.visible: hovered

            Layout.alignment: Qt.AlignRight

            onClicked: kcm.push("HotspotPage.qml")
        }
    }

    ConnectionEditor {
        id: connectionEditor
        visible: false
    }

    MessageDialog {
        id: deleteConfirmationDialog

        property string connectionName
        property string connectionPath

        /* Like QString::toHtmlEscaped */
        function toHtmlEscaped(s) {
            return s.replace(/[&<>]/g, function (tag) {
                return {
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;'
                }[tag] || tag
            });
        }

        icon: StandardIcon.Question
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: i18nc("@title:window", "Remove Connection")
        text: i18n("Do you want to remove the connection '%1'?", toHtmlEscaped(connectionName))

        onAccepted: {
            if (connectionPath == root.currentConnectionPath) {
                // Deselect now non-existing connection
                deselectConnectionsInView()
            }
            handler.removeConnection(connectionPath)
        }

        onRejected: selectConnectionInView(connectionName, connectionPath)
    }

    MessageDialog {
        id: confirmSaveDialog

        property string connectionName
        property string connectionPath

        icon: StandardIcon.Question
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        title: i18nc("@title:window", "Save Connection")
        text: i18n("Do you want to save changes made to the connection '%1'?", root.currentConnectionName)

        onAccepted: {
            kcm.save()
            selectConnectionInView(connectionName, connectionPath)
        }

        onRejected: selectConnectionInView(connectionName, connectionPath)
    }

    AddConnectionSheet {
        id: addNewConnectionSheet

        onRequestCreateConnection: {
            root.requestCreateConnection(type, vpnType, specificType, shared)
        }
    }

    onCurrentConnectionPathChanged: {
        if (currentConnectionPath) {
            if (kcm.depth < 2) {
                kcm.push(connectionEditor)
            } else {
                kcm.currentIndex = 1
            }
            kcm.selectConnection(root.currentConnectionPath)
        }
    }

    Component.onCompleted: {
        kcm.columnWidth = Kirigami.Units.gridUnit * 18
    }

    function loadConnectionSetting() {
        connectionEditor.loadConnectionSettings()
    }

    function deselectConnectionsInView() {
        root.currentConnectionPath = ""
    }

    function selectConnectionInView(connectionName, connectionPath) {
        root.currentConnectionName = connectionName
        root.currentConnectionPath = connectionPath
    }
}
