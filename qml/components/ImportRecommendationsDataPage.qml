/**
 * Copyright (C) 2021 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import Ubuntu.Content 1.3


Page {
    id: importPage

    property var activeTransfer
    property string loadDataUrl
    property string response

    signal imported(var response)

    header: PageHeader {
        title: i18n.tr("Load Recommendations Data")
    }

    function __importItemsWhenPossible(url) {
        if(importPage.activeTransfer.state === ContentTransfer.Charged) {
            console.log("Import Charged");
            importPage.loadDataUrl = importPage.activeTransfer.items[0].url
            console.log("received url: " + loadDataUrl)
            importPage.activeTransfer = null

            var xhr = new XMLHttpRequest;
            xhr.open("GET", loadDataUrl);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    importPage.response = xhr.responseText;
                    console.log("read: " + importPage.response)
                    imported(importPage.response)
                }
            }
            xhr.send()
        }
    }

    ContentPeerPicker {
        anchors {
            fill: parent;
            topMargin: importPage.header.height
        }

        visible: parent.visible
        showTitle: false
        contentType: ContentType.All
        handler: ContentHandler.Source

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            importPage.activeTransfer = peer.request()
            __importItemsWhenPossible()
        }
    }

    Connections {
        target: importPage.activeTransfer ? importPage.activeTransfer : null
        onStateChanged: {
            console.log("Import.curTransfer StateChanged: " + importPage.activeTransfer.state);
            __importItemsWhenPossible()
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: importPage.activeTransfer
    }

    Component {
        id: resultComponent

        ContentItem {}
    }
}
