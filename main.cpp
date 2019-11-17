#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>
#include <QQmlContext>

//#include <QTranslator>
//#include <QDebug>

#include "spotify.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    
    QCoreApplication::setApplicationName("hutspot");
    QCoreApplication::setOrganizationName("wdehoog");
    QCoreApplication::setOrganizationDomain("wdehoog");

    qDebug() << "Starting app from main.cpp";


    QQuickView *view = new QQuickView();

    Spotify spotify;
    view->rootContext()->setContextProperty("spotify", &spotify);

    view->setSource(QUrl(QStringLiteral("qml/Main.qml")));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}
