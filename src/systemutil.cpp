#include "systemutil.h"
#include <signal.h>

SystemUtil::SystemUtil(QObject *parent) {

}

void SystemUtil::pkill(uint pid, int signal) {
    kill(pid, signal);
}

QString SystemUtil::env(const QString& name) {
    return qgetenv(qPrintable(name));
}

bool SystemUtil::write(const QString& source, const QString& data) {
    if (source.isEmpty())
        return false;

    QFile file(source);
    if (!file.open(QFile::WriteOnly | QFile::Truncate))
        return false;

    QTextStream out(&file);
    out << data;
    file.close();

    return true;
}