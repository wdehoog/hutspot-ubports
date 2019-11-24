#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>
#include <QQmlContext>

//#include <QTranslator>
//#include <QDebug>

#include "qdeclarativeprocess.h"
#include "powerd.h"
#include "spotify.h"
#include "systemutil.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    
    QCoreApplication::setApplicationName("hutspot");
    QCoreApplication::setOrganizationName("wdehoog");
    QCoreApplication::setOrganizationDomain("wdehoog");

    qDebug() << "Starting app from main.cpp";


    QQuickView *view = new QQuickView();

    QString buildDateTime;
    buildDateTime.append(__DATE__);
    buildDateTime.append(" ");
    buildDateTime.append(__TIME__);
    view->rootContext()->setContextProperty("BUILD_DATE_TIME", buildDateTime);

    Powerd powerd;
    view->rootContext()->setContextProperty("powerd", &powerd);

    Spotify spotify;
    view->rootContext()->setContextProperty("spotify", &spotify);

    qmlRegisterUncreatableType<QDeclarativeProcessEnums>("org.hildon.components", 1, 0, "Processes", "");
    qmlRegisterType<QDeclarativeProcess>("org.hildon.components", 1, 0, "Process");

    SystemUtil systemUtil;
    qmlRegisterUncreatableType<SystemUtilEnums>("SystemUtil", 1, 0, "SystemUtil", "");
    view->rootContext()->setContextProperty("sysUtil", &systemUtil);

    view->setSource(QUrl(QStringLiteral("qml/Main.qml")));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}
