/*
    SPDX-FileCopyrightText: 2016 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.1
import QtQuick.Dialogs 1.1
import QtQuick.Controls 2.5 as QQC2
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.kirigami 2.15 as Kirigami

Item {
    id: root

    focus: true

    signal selectedConnectionChanged(string connection)
    signal requestCreateConnection(int type, string vpnType, string specificType, bool shared)
    signal requestExportConnection(string connection)
    signal requestToChangeConnection(string name, string path)

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    Connections {
        target: PlasmaNM.Configuration
        function onManageVirtualConnectionsChanged() {
            editorProxyModel.invalidate()
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        focus: true
        color: Kirigami.Theme.backgroundColor
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

    Kirigami.SearchField {
        id: searchField

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        onTextChanged: {
            editorProxyModel.setFilterFixedString(text)
        }
    }

    QQC2.ScrollView {
        id: scrollView

        Component.onCompleted: scrollView.background.visible = true // show frame

        anchors {
            bottom: rightButtonRow.top
            bottomMargin: Kirigami.Units.smallSpacing
            left: parent.left
            right: parent.right
            top: searchField.bottom
        }

        ListView {
            id: connectionView

            property bool currentConnectionExportable: false
            property string currentConnectionName
            property string currentConnectionPath

            clip: true
            focus: true
            activeFocusOnTab: true
            model: editorProxyModel
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            section.property: "KcmConnectionType"
            section.delegate: Kirigami.ListSectionHeader { text: section }
            delegate: ConnectionItem {
                onAboutToChangeConnection: {
                    // Shouldn't be problem to set this in advance
                    connectionView.currentConnectionExportable = exportable
                    if (connectionModified) {
                        requestToChangeConnection(name, path)
                    } else {
                        connectionView.currentConnectionName = name
                        connectionView.currentConnectionPath = path
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

            onCurrentConnectionPathChanged: {
                root.selectedConnectionChanged(currentConnectionPath)
            }
        }
    }

    Row {
        id: rightButtonRow

        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        QQC2.ToolButton {
            id: addConnectionButton

            icon.name: "list-add"

            QQC2.ToolTip.text: i18n("Add new connection")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                addNewConnectionDialog.open()
            }
        }

        QQC2.ToolButton {
            id: removeConnectionButton

            enabled: connectionView.currentConnectionPath && connectionView.currentConnectionPath.length
            icon.name: "list-remove"

            QQC2.ToolTip.text: i18n("Remove selected connection")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                deleteConfirmationDialog.connectionName = connectionView.currentConnectionName
                deleteConfirmationDialog.connectionPath = connectionView.currentConnectionPath
                deleteConfirmationDialog.open()
            }
        }

        QQC2.ToolButton {
            id: exportConnectionButton

            enabled: connectionView.currentConnectionExportable
            icon.name: "document-export"

            QQC2.ToolTip.text: i18n("Export selected connection")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                root.requestExportConnection(connectionView.currentConnectionPath)
            }
        }
    }

    Row {
        id: leftButtonRow

        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        QQC2.ToolButton {
            id: configureButton

            icon.name: "configure"

            QQC2.ToolTip.text: i18n("Configuration")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                configurationDialog.open()
            }
        }
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
            if (connectionPath == connectionView.currentConnectionPath) {
                // Deselect now non-existing connection
                deselectConnections()
            }
            handler.removeConnection(connectionPath)
        }
    }

    AddConnectionDialog {
        id: addNewConnectionDialog

        onRequestCreateConnection: {
            root.requestCreateConnection(type, vpnType, specificType, shared)
        }
    }

    ConfigurationDialog {
        id: configurationDialog
    }

    function deselectConnections() {
        connectionView.currentConnectionPath = ""
    }

    function selectConnection(connectionName, connectionPath) {
        connectionView.currentConnectionName = connectionName
        connectionView.currentConnectionPath = connectionPath
    }
}
