#ifndef POWERD_H
#define POWERD_H

#include <QObject>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusPendingCallWatcher>
#include <QtDBus/QDBusPendingReply>

class Powerd : public QObject
{
    Q_OBJECT
public:
    explicit Powerd(QObject *parent = 0);

    Q_SIGNAL void sysStateActiveChanged(bool hasSysStateActive);

public slots:
    Q_INVOKABLE void requestSysStateActive(QString name);
    Q_INVOKABLE void clearSysStateActive();
    Q_INVOKABLE bool hasSysStateActive();

protected:
    void onWakeLockAcquired(QDBusPendingCallWatcher *call);

    bool m_hasWakeLock;
    QByteArray m_cookie;
    QDBusInterface *m_powerd;
};

#endif // POWERD_H
