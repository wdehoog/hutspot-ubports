#include "mdns.h"

#include "qmdnsengine/resolver.h"
#include "qmdnsengine/service.h"

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

MDNS::MDNS(QObject *parent) : QObject(parent) {
    this->server = new  QMdnsEngine::Server();
    this->cache = new QMdnsEngine::Cache();
    this->browser = new QMdnsEngine::Browser(server, "_spotify-connect._tcp.local.", cache);

    connect(browser, &QMdnsEngine::Browser::serviceAdded, this, &MDNS::serviceAddedCallback);
    connect(browser, &QMdnsEngine::Browser::serviceUpdated, this, &MDNS::serviceUpdatedCallback);
    connect(browser, &QMdnsEngine::Browser::serviceRemoved, this, &MDNS::serviceRemovedCallback);
}

void MDNS::serviceChangedHandler(const QMdnsEngine::Service &service, bool added) {
    QJsonObject properties;
    properties["name"] = QString::fromStdString(service.name().toStdString());
    properties["CPath"] = QString::fromStdString(service.attributes()["CPath"].toStdString());
    properties["VERSION"] = QString::fromStdString(service.attributes()["VERSION"].toStdString());
    properties["host"] = QString::fromStdString(service.hostname().toStdString());
    properties["port"] = service.port();
    properties["type"] = QString::fromStdString(service.type().toStdString());
    QJsonDocument doc(properties);
    QString json = doc.toJson(QJsonDocument::Compact);
    if(added)
        emit serviceAdded(json);
    else
        emit serviceUpdated(json);

    // resolve it
    if(resolvers.contains(service.hostname())) { // already one
        //qDebug() << "Resolver already exists for: " << service.hostname();
        QMdnsEngine::Resolver * old = resolvers[service.hostname()];
        resolvers.remove(service.hostname());
        delete old;
    }

    QMdnsEngine::Resolver * resolver = new QMdnsEngine::Resolver(server, service.hostname(), cache);
    connect(resolver, &QMdnsEngine::Resolver::resolved, this, &MDNS::resolvedCallback);
    resolvers[service.hostname()] = resolver;
    //qDebug() << "Created resolver for: " << service.hostname();
}

void MDNS::serviceAddedCallback(const QMdnsEngine::Service &service) {
    //qDebug() << service.name() << " discovered";
    serviceChangedHandler(service, true);
}

void MDNS::serviceUpdatedCallback(const QMdnsEngine::Service &service) {
    //qDebug() << service.name() << " updated";
    serviceChangedHandler(service, false);
}

void MDNS::serviceRemovedCallback(const QMdnsEngine::Service &service) {
    emit serviceRemoved(service.name());
}

void MDNS::resolvedCallback(QString name, const QHostAddress &address) {
    //qDebug() << "resolved " << name << " to " << address;
    if(address.protocol() == QAbstractSocket::IPv4Protocol)
        emit serviceResolved(name, address.toString());
}


