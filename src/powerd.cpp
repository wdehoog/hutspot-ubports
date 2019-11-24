/**
 * Most code is copied from sharedwakelock.cpp from qt-mir.
 * Therefore license is LGPL
 */

#include "powerd.h"
#include <QDebug>


const int POWERD_SYS_STATE_ACTIVE = 1; // copied from private header file powerd.h

Powerd::Powerd(QObject *parent) 
  : m_hasWakeLock(false),
    m_powerd(nullptr) {
    m_powerd = new QDBusInterface(QStringLiteral("com.canonical.powerd"),
                                  QStringLiteral("/com/canonical/powerd"),
                                  QStringLiteral("com.canonical.powerd"),
                                  QDBusConnection::systemBus(), this);
}

bool Powerd::hasSysStateActive() {
    return m_hasWakeLock;
}

void Powerd::requestSysStateActive() {
    // one is enough?
    //if(m_hasWakeLock)
    //    return;

    QDBusPendingCall pcall = m_powerd->asyncCall(QStringLiteral("requestSysState"), "active", POWERD_SYS_STATE_ACTIVE);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(pcall, this);
    QObject::connect(watcher, &QDBusPendingCallWatcher::finished,
                     this, &Powerd::onWakeLockAcquired);
}

void Powerd::onWakeLockAcquired(QDBusPendingCallWatcher *call) {

    QDBusPendingReply<QString> reply = *call;
    if (reply.isError()) {
        qDebug() << "Wakelock was NOT acquired, error:"
                                << QDBusError::errorString(reply.error().type());
        if (m_hasWakeLock) {
            m_hasWakeLock = false;
            Q_EMIT sysStateActiveChanged(false);
        }

        call->deleteLater();
        return;
    }
    QByteArray cookie = reply.argumentAt<0>().toLatin1();
    call->deleteLater();

    /*if (!m_wakelockEnabled || !m_cookie.isEmpty()) {
        // notified wakelock was created, but we either don't want it, or already have one - release it immediately
        dbusInterface()->asyncCall(QStringLiteral("clearSysState"), QString(cookie));
        return;
    }*/

    m_cookie = cookie;
    m_hasWakeLock = true;

    qDebug() << "Wakelock acquired" << m_cookie;
    Q_EMIT sysStateActiveChanged(true);
}

void Powerd::clearSysStateActive() {
    if(!m_hasWakeLock)
        return;

    m_hasWakeLock = false;
    Q_EMIT sysStateActiveChanged(false);

    /*if (!serviceAvailable()) {
        qWarning() << "com.canonical.powerd DBus interface not available, presuming no wakelocks held";
        return;
    }*/

    if (!m_cookie.isEmpty()) {
        m_powerd->asyncCall(QStringLiteral("clearSysState"), QString(m_cookie));
        qDebug() << "Wakelock released" << m_cookie;
        m_cookie.clear();
    }
}
