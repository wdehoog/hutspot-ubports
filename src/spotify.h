#ifndef SPOTIFY_H
#define SPOTIFY_H

#include <QObject>
#include <QNetworkReply>

#include "o2/o2spotify.h"

class Spotify : public QObject
{
    Q_OBJECT
public:
    explicit Spotify(QObject *parent = 0);

signals:
    void extraTokensReady(const QVariantMap &extraTokens);
    void linkingFailed();
    void linkingSucceeded();
    void linkedChanged();
    void refreshFinished(int errorCode, QString errorString);
    void openBrowser(const QUrl &url);
    void closeBrowser();
    void requestFinished(int status, QString response);
    void requestError(int status, QString error);

public slots:
    Q_INVOKABLE void doO2Auth(const QString &scope);
    Q_INVOKABLE QString getUserName();
    Q_INVOKABLE QString getToken();
    Q_INVOKABLE void refreshToken();
    Q_INVOKABLE int getExpires();
    Q_INVOKABLE bool isLinked();
    Q_INVOKABLE void performRequest(QString url, QString verb, QString data, QString token);

private slots:
    void onLinkedChanged();
    void onLinkingSucceeded();
    void onLinkingFailed();
    void onOpenBrowser(const QUrl &url);
    void onCloseBrowser();
    void onRefreshFinished(QNetworkReply::NetworkError error, QString errorString);

    void onRequestFinished(QNetworkReply *reply);
    void onRequestError(QNetworkReply::NetworkError error);

private:
    O2Spotify * o2Spotify;
    QNetworkAccessManager * manager;
};

#endif // SPOTIFY_H
