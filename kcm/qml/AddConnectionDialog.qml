/*
    SPDX-FileCopyrightText: 2016 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.3
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.5 as QQC2
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

Dialog {
    id: dialog
    title: i18nc("@title:window", "Choose a Connection Type")

    signal requestCreateConnection(int type, string vpnType, string specificType, bool shared)

    contentItem: Item {
        implicitHeight: 600
        implicitWidth: 500

        PlasmaNM.CreatableConnectionsModel {
            id: connectionModel
        }

        Rectangle {
            id: background
            anchors.fill: parent
            focus: true
            color: baseColor
        }

        QQC2.ScrollView {
            id: scrollView
            anchors {
                bottom: buttonRow.top
                bottomMargin: Math.round(Kirigami.Units.gridUnit / 2)
                left: parent.left
                right: parent.right
                top: parent.top
            }
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            ListView {
                id: view

                property int currentlySelectedIndex: -1
                property bool connectionShared
                property string connectionSpecificType
                property int connectionType
                property string connectionVpnType

                clip: true
                model: connectionModel
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                section.property: "ConnectionTypeSection"
                section.delegate: Kirigami.ListSectionHeader { text: section }
                delegate: ListItem {
                    checked: mouseArea.containsMouse || view.currentlySelectedIndex == index
                    height: connectionTypeBase.height
                    width: view.width

                    Item {
                        id: connectionTypeBase

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            // Reset top margin from PlasmaComponents.ListItem
                            topMargin: -Math.round(Kirigami.Units.gridUnit / 3)
                        }
                        height: Math.max(Kirigami.Units.iconSizes.medium, connectionNameLabel.height + connectionDescriptionLabel.height) + Math.round(Kirigami.Units.gridUnit / 2)

                        KQuickControlsAddons.QIconItem {
                            id: connectionIcon

                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            height: Kirigami.Units.iconSizes.medium; width: height
                            icon: ConnectionIcon
                        }

                        Text {
                            id: connectionNameLabel

                            anchors {
                                bottom: ConnectionType == 11 ? connectionIcon.verticalCenter : undefined
                                left: connectionIcon.right
                                leftMargin: Math.round(Kirigami.Units.gridUnit / 2)
                                right: parent.right
                                verticalCenter: ConnectionType == 11 ? undefined : parent.verticalCenter
                            }
                            color: textColor
                            height: paintedHeight
                            elide: Text.ElideRight
                            text: ConnectionTypeName
                            textFormat: Text.PlainText
                        }

                        Text {
                            id: connectionDescriptionLabel

                            anchors {
                                left: connectionIcon.right
                                leftMargin: Math.round(Kirigami.Units.gridUnit / 2)
                                right: parent.right
                                top: connectionNameLabel.bottom
                            }
                            color: textColor
                            height: visible ? paintedHeight : 0
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.6
                            text: ConnectionDescription
                            visible: ConnectionType == 11 // VPN
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            createButton.enabled = true
                            view.currentlySelectedIndex = index
                            view.connectionSpecificType = ConnectionSpecificType
                            view.connectionShared = ConnectionShared
                            view.connectionType = ConnectionType
                            view.connectionVpnType = ConnectionVpnType
                        }

                        onDoubleClicked: {
                            dialog.close()
                            dialog.requestCreateConnection(view.connectionType, view.connectionVpnType, view.connectionSpecificType, view.connectionShared)
                        }
                    }
                }
            }
        }

        Row {
            id: buttonRow
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: Math.round(Kirigami.Units.gridUnit / 2)
            }
            spacing: Math.round(Kirigami.Units.gridUnit / 2)

            QQC2.Button {
                id: createButton
                enabled: false
                text: i18n("Create")

                onClicked: {
                    dialog.close()
                    dialog.requestCreateConnection(view.connectionType, view.connectionVpnType, view.connectionSpecificType, view.connectionShared)
                }
            }

            QQC2.Button {
                id: cancelButton
                text: i18n("Cancel")

                onClicked: {
                    dialog.close()
                }
            }
        }

        QQC2.ToolButton {
            id: configureButton
            anchors {
                bottom: parent.bottom
                left: parent.left
                margins: Math.round(Kirigami.Units.gridUnit / 2)
            }
            icon.name: "configure"

            QQC2.ToolTip.text: i18n("Configuration")
            QQC2.ToolTip.visible: hovered

            onClicked: {
                configurationDialog.open()
            }
        }
    }
}
