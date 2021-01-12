/**
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * Based on ExportPage from Gelek by Stefano Verzegnassi 
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import Ubuntu.Content 1.3


Page {
    id: exportPage

    property var activeTransfer
    property string saveData
    property string saveDataPath: app.tempDirectory + "/exported_recommendations.json"

    header: PageHeader {
        title: i18n.tr("Save Recommendations Data")
    }

    onSaveDataChanged: {
        // write saveData to special file in temp dir
        if(!sysUtil.write(saveDataPath, saveData)) {
            app.showErrorMessage("Write Error", i18n.tr("Failed to export Recommendations Data."))
            pageStack.pop()
        }
    }

    ContentPeerPicker {
        anchors {
            fill: parent
            topMargin: exportPage.header.height
        }

        visible: parent.visible
        showTitle: false
        contentType: ContentType.All
        handler: ContentHandler.Destination

        onPeerSelected: {
            exportPage.activeTransfer = peer.request()
            exportPage.activeTransfer.stateChanged.connect(function() {
                if (exportPage.activeTransfer.state === ContentTransfer.InProgress) {
                    console.log("Save: In progress");
                    exportPage.activeTransfer.items = [ resultComponent.createObject(parent, {"url": "file://" + saveDataPath}) ];
                    exportPage.activeTransfer.state = ContentTransfer.Charged;
                    pageStack.pop()
                }
            })
        }

        onCancelPressed: {
            pageStack.pop()
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: exportPage.activeTransfer
    }

    Component {
        id: resultComponent

        ContentItem {}
    }
}
