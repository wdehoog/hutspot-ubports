#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QDesktopServices>
#include <QDebug>

#include "spotify.h"

#include "o2/o0globals.h"
#include "o2/o2requestor.h"
#include "o2/o0settingsstore.h"

//#error Setup your Spotify application "https://beta.developer.spotify.com/dashboard/applications"
const char O2_CONSUMER_KEY[] = "e8c4417050da441ba75bb34314bb75cc";
const char O2_CONSUMER_SECRET[] = "1c85c26db85342ce9e7d8d9a1a605ea1";
const int localPort = 8888;

const char O2_REPLY_CONTENT[] =
"<!DOCTYPE html>"
"<html>"
"<head>"
"<style type=\"text/css\">"
"  h1 {text-align: center;}"
"</style>"
"</head>"
"<body>"
"<h1>Hutspot</h1>"
"<br>"
"<h3>Spotify authorization redirected</h3>"
"<br>"
"<h3>You can close this page (and return to the App).</h3>"
"</body>"
"</html>";

Spotify::Spotify(QObject *parent) : QObject(parent)
{
    o2Spotify = new O2Spotify(this);
    o2Spotify->setClientId(O2_CONSUMER_KEY);
    o2Spotify->setClientSecret(O2_CONSUMER_SECRET);
    o2Spotify->setLocalPort(localPort);

    // Create a store object for writing the received tokens
    O0SettingsStore *store = new O0SettingsStore(O2_ENCRYPTION_KEY);
    store->setGroupKey("spotify");
    o2Spotify->setGrantFlow(O2::GrantFlowAuthorizationCode);
    o2Spotify->setStore(store);
    o2Spotify->setReplyContent(O2_REPLY_CONTENT);

    // Connect signals
    connect(o2Spotify, SIGNAL(linkedChanged()), this, SLOT(onLinkedChanged()));
    connect(o2Spotify, SIGNAL(linkingFailed()), this, SLOT(onLinkingFailed()));
    connect(o2Spotify, SIGNAL(linkingSucceeded()), this, SLOT(onLinkingSucceeded()));
    connect(o2Spotify, SIGNAL(openBrowser(QUrl)), this, SLOT(onOpenBrowser(QUrl)));
    connect(o2Spotify, SIGNAL(closeBrowser()), this, SLOT(onCloseBrowser()));
    connect(o2Spotify, SIGNAL(refreshFinished(QNetworkReply::NetworkError, QString)), this, SLOT(onRefreshFinished(QNetworkReply::NetworkError, QString)));

    // for http requests
    manager = new QNetworkAccessManager(this);
    QObject::connect(manager, SIGNAL(finished(QNetworkReply*)),this, SLOT(onRequestFinished(QNetworkReply*)));
}

void Spotify::doO2Auth(const QString &scope) {
    if (scope.length() > 0)
        o2Spotify->setScope(scope);

    qDebug() << "Starting OAuth...";
    o2Spotify->unlink();
    o2Spotify->link();
}

QString Spotify::getUserName() {
    if(o2Spotify)
        return o2Spotify->username();
    return "";
}

QString Spotify::getToken() {
    if(o2Spotify)
        return o2Spotify->token();
    return "";
}

void Spotify::refreshToken() {
    if(o2Spotify)
        o2Spotify->refresh();
}

int Spotify::getExpires() {
    if(o2Spotify)
        return o2Spotify->expires();
    return -1;
}

void Spotify::onOpenBrowser(const QUrl &url) {
    qDebug() << "Opening browser with URL" << url.toString();
    //QDesktopServices::openUrl(url);
    emit openBrowser(url);
}

void Spotify::onCloseBrowser() {
    // don't know how to close the broser tab/window and switch to ourselves
    qDebug() << "Spotify::onCloseBrowser()";
    emit closeBrowser();
}

void Spotify::onRefreshFinished(QNetworkReply::NetworkError error, QString errorString) {
    //QNetworkReply *tokenReply = qobject_cast<QNetworkReply *>(sender());
    //qDebug() << "Spotify::onRefreshFinished(): " << error << ", " << tokenReply->errorString();
    qDebug() << "Spotify::onRefreshFinished(): " << error;
    emit refreshFinished(error, errorString);
}

void Spotify::onLinkedChanged() {
    qDebug() << "Linked changed!";
    emit linkedChanged();
}

void Spotify::onLinkingSucceeded() {
    O2Spotify *o2s = qobject_cast<O2Spotify *>(sender());
    if (!o2s->linked()) {
        return;
    }
    QVariantMap extraTokens = o2s->extraTokens();
    if (!extraTokens.isEmpty()) {
        emit extraTokensReady(extraTokens);
        qDebug() << "Extra tokens in response:";
        foreach (QString key, extraTokens.keys()) {
            qDebug() << "\t" << key << ":" << (extraTokens.value(key).toString().left(3) + "...");
        }
    }
    emit linkingSucceeded();
}

void Spotify::onLinkingFailed() {
    qDebug() << "Linking failed!";
    emit linkingFailed();
}

bool Spotify::isLinked() {
    return o2Spotify->linked();
}

void Spotify::performRequest(QString url, QString verb, QString data, QString token) {
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply * reply = manager->sendCustomRequest(request, verb.toUtf8(), data.toUtf8());
    QObject::connect(reply, SIGNAL(error(QNetworkReply::NetworkError)),this, SLOT(onRequestError(QNetworkReply::NetworkError)));
}

void Spotify::onRequestFinished(QNetworkReply *reply) {

    if (reply->error() == QNetworkReply::NoError) {
        qDebug() << "Spotify::onRequestFinished: " << reply->readAll();
        Q_EMIT requestFinished(reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt(), reply->readAll());
    } else {
        qWarning() << "Spotify::onRequestFinished: Error: " << reply->error() << ": " << reply->errorString();
        Q_EMIT requestError(reply->error(), reply->errorString());
    }
}

void Spotify::onRequestError(QNetworkReply::NetworkError error) { 
    QNetworkReply *resp = qobject_cast<QNetworkReply *>(sender());
    qWarning() << "Spotify::onRequestError: " << error << ": " << resp->errorString();
    qDebug() << "Spotify::onRequestError: " << resp->readAll();
    Q_EMIT requestError(error, resp->errorString());
}
