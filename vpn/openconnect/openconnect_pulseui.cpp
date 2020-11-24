/*
    SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

#include "openconnectui.h"

#include <KPluginFactory>

class OpenConnectPulseUi : public OpenconnectUiPlugin
{
    Q_OBJECT
public:
    explicit OpenConnectPulseUi(QObject *parent = nullptr, const QVariantList &args = QVariantList())
        : OpenconnectUiPlugin(parent, args)
    {
    }
};

K_PLUGIN_CLASS_WITH_JSON(OpenConnectPulseUi, "plasmanetworkmanagement_openconnect_pulseui.json")

#include "openconnect_pulseui.moc"
