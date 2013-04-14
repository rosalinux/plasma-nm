/*
    Copyright 2013 Jan Grulich <jgrulich@redhat.com>

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

#include "connectionwidget.h"
#include "ui_connectionwidget.h"
#include <KUser>

ConnectionWidget::ConnectionWidget(const NetworkManager::Settings::ConnectionSettings::Ptr &settings, QWidget* parent, Qt::WindowFlags f):
    QWidget(parent, f),
    m_widget(new Ui::ConnectionWidget),
    m_type(settings->connectionType())
{
    m_widget->setupUi(this);

    //TODO: populate firewall zones

    if (settings)
        loadConfig(settings);
}

ConnectionWidget::~ConnectionWidget()
{
}

void ConnectionWidget::loadConfig(const NetworkManager::Settings::ConnectionSettings::Ptr &settings)
{
    if (settings->permissions().isEmpty()) {
        m_widget->allUsers->setChecked(true);
    } else {
        m_widget->allUsers->setChecked(false);
    }

    m_widget->autoconnect->setChecked(settings->autoconnect());

    Q_UNUSED(settings);
}

NMVariantMapMap ConnectionWidget::setting() const
{
    NetworkManager::Settings::ConnectionSettings settings;

    settings.setConnectionType(m_type);
    settings.setAutoconnect(m_widget->autoconnect->isChecked());

    if (m_widget->allUsers->isChecked()) {
        settings.setPermissions(QHash<QString, QString>());
    } else {
        settings.addToPermissions(KUser().loginName(), QString());
    }

    //TODO: zones

    return settings.toMap();
}
