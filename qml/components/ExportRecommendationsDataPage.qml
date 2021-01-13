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
    property string saveDataPath

    Component.onCompleted: {
        // Content-Hub cannot handle overwriting files and FileManager
        // does not warn you so use a counter to reduce the chance that happens
        var counter = app.settings.recommendationsDataExportCounter
        app.settings.recommendationsDataExportCounter = counter + 1

        saveDataPath = app.tempDirectory + "/exported_recommendations-%1.json".arg(zeroPad(counter, 4))

        // write saveData to special file in temp dir
        if(!sysUtil.write(saveDataPath, saveData)) {
            app.showErrorMessage("Write Error", i18n.tr("Failed to export Recommendations Data."))
            pageStack.pop()
        }
    }

    function zeroPad(num, size) {
        num = num.toString()
        while (num.length < size)
            num = "0" + num
        return num
    }

    header: PageHeader {
        title: i18n.tr("Save Recommendations Data")
    }

    function __exportItemsWhenPossible(url) {
        if(exportPage.activeTransfer.state === ContentTransfer.InProgress) {
            console.log("Export: in progress for: " + saveDataPath)
            exportPage.activeTransfer.items = [ resultComponent.createObject(parent, {"url": "file://" + saveDataPath}) ]
            exportPage.activeTransfer.state = ContentTransfer.Charged
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
            peer.selectionType = ContentTransfer.Single
            exportPage.activeTransfer = peer.request()
            pageStack.pop()
            __exportItemsWhenPossible()
        }

        onCancelPressed: {
            pageStack.pop()
        }
    }

    Connections {
target: exportPage.activeTransfer ? exportPage.activeTransfer : null
        onStateChanged: {
            console.log("Export.curTransfer StateChanged: " + exportPage.activeTransfer.state);
            __exportItemsWhenPossible()
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
