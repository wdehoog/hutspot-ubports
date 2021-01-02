/**
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * Based on ImportPage from Gelek by Stefano Verzegnassi 
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

    signal imported(var data)

    header: PageHeader {
        title: i18n.tr("Load with")
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
            importPage.activeTransfer.stateChanged.connect(function() {

                if (importPage.activeTransfer.state === ContentTransfer.InProgress) {
                    console.log("Import in Progress");
                    importPage.activeTransfer.items = importPage.activeTransfer.items[0].url;
                }

                if (importPage.activeTransfer.state === ContentTransfer.Charged) {
                    console.log("Import Charged");
                    loadDataUrl = importPage.activeTransfer.items[0].url
                    console.log("received url: " + loadDataUrl)
                    importPage.activeTransfer = null

                    var xhr = new XMLHttpRequest;
                    xhr.open("GET", loadDataUrl);
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            var response = xhr.responseText;
                            console.log("read: " + response)
                            imported(response)
                        }
                    }
                    xhr.send()

                }
            })
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
