import QtQuick 2.7
import Ubuntu.Components 1.3
import Morph.Web 0.1
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebEngine 1.7


Page {
    id: webAuthPage

    property var authURL

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: i18n.tr('Spotify Login')
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageStack.pop()
            }
        ]
        flickable: webView
    }

    WebView {
        id: webView
        anchors.fill: parent
        url: authURL
    }

}
