/*
 *   Copyright 2018 Martin Kacej <m.kacej@atlas.sk>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef CELLURALSETTINGS_H
#define CELLURALSETTINGS_H

#include <KQuickAddons/ConfigModule>

class CelluralSettings : public KQuickAddons::ConfigModule
{
    Q_OBJECT
    Q_PROPERTY(bool mobileDataActive READ mobileDataActive WRITE setMobileDataActive NOTIFY mobileDataActiveChanged)

public:
    CelluralSettings(QObject *parent, const QVariantList &args);
    virtual ~CelluralSettings();
    bool mobileDataActive();
    void setMobileDataActive(bool active);
    Q_SIGNAL void mobileDataActiveChanged(bool active);
    Q_INVOKABLE QString getModemDevice();
    void setupMobileNetwork();
    Q_INVOKABLE QString getAPN();

private:
    bool m_mobileDataActive;
};

#endif // CELLURALSETTINGS_H
