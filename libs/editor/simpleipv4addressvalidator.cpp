/*
    SPDX-FileCopyrightText: 2009 Paul Marchouk <pmarchouk@gmail.com>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

#include "simpleipv4addressvalidator.h"

#include <QStringList>
#include <QVector>

SimpleIpV4AddressValidator::SimpleIpV4AddressValidator(AddressStyle style, QObject *parent)
    : QValidator(parent)
    , m_addressStyle(style)
{
    switch (style) {
    case Base:
        m_validator.setRegularExpression(QRegularExpression(QStringLiteral("[0-9, ]{1,3}\\.[0-9, ]{1,3}\\.[0-9, ]{1,3}\\.[0-9, ]{1,3}")));
        break;
    case WithCidr:
        m_validator.setRegularExpression(QRegularExpression(QStringLiteral("([0-9]{1,3}\\.){3,3}[0-9]{1,3}/[0-9]{1,2}")));
        break;
    case WithPort:
        m_validator.setRegularExpression(QRegularExpression(QStringLiteral("([0-9]{1,3}\\.){3,3}[0-9]{1,3}:[0-9]{1,5}")));
        break;
    }
}

SimpleIpV4AddressValidator::~SimpleIpV4AddressValidator() = default;

QValidator::State SimpleIpV4AddressValidator::validate(QString &address, int &pos) const
{
    QValidator::State maskResult = checkWithInputMask(address, pos);
    if (QValidator::Invalid == maskResult) {
        return QValidator::Invalid;
    }

    // this list will be filled with tetrad values. It can be used to make
    // some additional correctness checks on the last validation step.
    QList<int> tetrads;

    QValidator::State tetradResult = checkTetradsRanges(address, tetrads);
    if (QValidator::Invalid == tetradResult)
        return QValidator::Invalid;
    else if (QValidator::Intermediate == tetradResult || QValidator::Intermediate == maskResult)
        return QValidator::Intermediate;
    else
        return QValidator::Acceptable;
}

QValidator::State SimpleIpV4AddressValidator::checkWithInputMask(QString &value, int &pos) const
{
    return m_validator.validate(value, pos);
}

QValidator::State SimpleIpV4AddressValidator::checkTetradsRanges(QString &value, QList<int> &tetrads) const
{
    QStringList temp;
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QVector<QStringRef> addrParts;
#else
    QVector<QStringView> addrParts;
#endif
    QStringList cidrParts;
    QStringList portParts;

    switch (m_addressStyle) {
    case Base:
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        addrParts = value.splitRef(QLatin1Char('.'));
#else
        addrParts = QStringView(value).split(QLatin1Char('.'));
#endif
        break;

    case WithCidr:
        cidrParts = value.split(QLatin1Char('/'));
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        addrParts = cidrParts[0].splitRef(QLatin1Char('.'));
#else
        addrParts = QStringView(cidrParts[0]).split(QLatin1Char('.'));
#endif
        break;

    case WithPort:
        portParts = value.split(QLatin1Char(':'));
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        addrParts = portParts[0].splitRef(QLatin1Char('.'));
#else
        addrParts = QStringView(portParts[0]).split(QLatin1Char('.'));
#endif
        break;
    }

    int i = 0;
    // fill in the list with invalid values
    tetrads << -1 << -1 << -1 << -1;

    // lets check address parts
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    for (const QStringRef &part : std::as_const(addrParts)) {
#else
    for (const QStringView &part : std::as_const(addrParts)) {
#endif
        if (part.isEmpty()) {
            if (i != (addrParts.size() - 1)) {
                // qCDebug(PLASMA_NM_EDITOR_LOG) << "part.isEmpty()";
                return QValidator::Invalid;
            }
            // the last tetrad can be empty, continue...
            return QValidator::Intermediate;
        }

        tetrads[i] = part.toInt();

        if (tetrads[i] > 255) {
            // qCDebug(PLASMA_NM_EDITOR_LOG) << "tetrads[i] > 255";
            return QValidator::Invalid;
        }

        // correct tetrad value: for example, 001 -> 1
        temp.append(QString::number(tetrads[i]));

        i++;
    }

    // replace input string with the corrected version
    value = temp.join(QLatin1String("."));

    if (i < 4) {
        // not all tetrads are filled... continue
        // qCDebug(PLASMA_NM_EDITOR_LOG) << "QValidator::Intermediate";
        return QValidator::Intermediate;
    } else {
        if (m_addressStyle == WithCidr) {
            if (cidrParts.size() > 1) {
                value += QLatin1String("/");
                if (!cidrParts[1].isEmpty()) {
                    int cidrValue = cidrParts[1].toInt();
                    if (cidrValue > 32) {
                        return QValidator::Invalid;
                    } else {
                        value += cidrParts[1];
                        return QValidator::Acceptable;
                    }
                } else {
                    return QValidator::Intermediate;
                }
            }
        } else if (m_addressStyle == WithPort) {
            if (portParts.size() > 1) {
                value += QLatin1String(":");
                if (!portParts[1].isEmpty()) {
                    int portValue = portParts[1].toInt();
                    if (portValue > 65535) {
                        return QValidator::Invalid;
                    } else {
                        value += portParts[1];
                        return QValidator::Acceptable;
                    }
                } else {
                    return QValidator::Intermediate;
                }
            }
        }

        // qCDebug(PLASMA_NM_EDITOR_LOG) << "QValidator::Acceptable";
        return QValidator::Acceptable;
    }
}
