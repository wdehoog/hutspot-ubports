import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebEngine 1.7


Page {
    id: webAuthPage

    property string authURL: ""

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: i18n.tr('Spotify Login')
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        url: authURL
    }

}
