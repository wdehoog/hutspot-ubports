#ifndef SYSTEMUTIL_H
#define SYSTEMUTIL_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QDebug>

class SystemUtilEnums : public QObject
{
    Q_OBJECT

    Q_ENUMS(Signals)

public:
    enum Signals {
        SIGHUP = 1,
        SIGINT = 2,
        SIGQUIT = 3,
        SIGUSR1 = 10,
        SIGUSR2 = 12,
        SIGTERM = 15
    };
};

class SystemUtil : public QObject
{
    Q_OBJECT
public:
    explicit SystemUtil(QObject *parent = 0);

public slots:
    Q_INVOKABLE void pkill(uint pid, int signal);
    Q_INVOKABLE static QString env(const QString &name);
    Q_INVOKABLE bool write(const QString& source, const QString& data);
};

#endif // SYSTEMUTIL_H
