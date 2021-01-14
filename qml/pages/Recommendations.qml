/**
 * Copyright (C) 2021 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Ubuntu.Content 1.3

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: genreMoodPage
    objectName: "RecommendationsPage"

    property bool showBusy: true
    property url defaultUnlinkedImage: Qt.resolvedUrl("../resources/broken-link.svg")
    property url defaultLinkedImage: "image://theme/stock_music"

    property int currentIndex: -1

    ListModel {
        id: recommendationsModel
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Recommendations")
        flickable: listView
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add New")
                iconName: "add"
                onTriggered: addNewSet()
            },
            Action {
                text: i18n.tr("Save")
                iconName: "document-save"
                onTriggered: saveSeedsAndAttributes()
            },
            Action {
                text: i18n.tr("Load")
                iconName: "document-open"
                onTriggered: loadSeedsAndAttributes()
            }
        ]
    }

    property alias contextMenu: contextMenu

    Item {
        id: contextMenu
        property var model

        function open(theModel, item) {
            model = theModel
            PopupUtils.open(popup, item)
        }

        Component {
            id: popup
            ContextMenuPopover {

                actions: ActionList {
                    Action {
                        property int idx: 0
                        //id: a
                        //property int idx: enabled ? 0 : -1
                        text: i18n.tr("Refresh Playlist Tracks")
                        enabled: contextMenu.model.recommendationSet.playlist_id
                                 ? true : false
                        onTriggered: generatePlaylist(contextMenu.model)
                    }
                    Action {
                        property int idx: 1
                        //id: b
                        //property int idx: enabled ? (a.idx + 1) : a.idx
                        text: contextMenu.model.recommendationSet.playlist_id
                            ? i18n.tr("Link to other Playlist")
                            : i18n.tr("Link to Playlist")
                        onTriggered: linkToPlaylist(contextMenu.model)
                    }
                    Action {
                        property int idx: 2
                        //id: c
                        //property int idx: enabled ? (b.idx + 1) : a.idx
                        text: i18n.tr("Rename")
                        onTriggered: renameSet(contextMenu.model)
                    }
                    Action {
                        property int idx: 3
                        //id: d
                        //property int idx: enabled ? (c.idx + 1) : b.idx
                        text: i18n.tr("Edit")
                        onTriggered: editSet(contextMenu.model)
                    }
                    Action {
                        property int idx: 4
                        //id: e
                        //property int idx: enabled ? (d.idx + 1) : c.idx
                        text: i18n.tr("Delete")
                        onTriggered: deleteSet(contextMenu.model)
                    }
                }
            }
        }
    }

    ListView {
        id: listView
        model: recommendationsModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height


        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            Row {
                width: parent.width
                spacing: app.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: playlistImage
                    height: listItem.height - app.paddingSmall
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: getCoverImage(recommendationSet.playlist_id)
                }

                Column {
                    width: parent.width - playlistImage.width - app.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        elide: Text.ElideRight
                        text: recommendationSet.name
                    }
                    Label {
                        text: i18n.tr("#seeds: %1, use attributes: %2".arg(recommendationSet.seeds.length).arg(recommendationSet.use_attributes? i18n.tr("yes") : i18n.tr("no") ))
                    }
                }
            }

            onClicked: editSet(model)
            onPressAndHold: contextMenu.open(model, listItem)
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    ActivityIndicator {
        id: activity
        width: app.itemSizeLarge
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        running: showBusy
        visible: running
        z: 1
    }

    function refresh() {
        recommendationsModel.clear()
        loadRecommendationsData()
    }

    function loadRecommendationsData() {
        var rs = app.recommendationSets
        for(var i=0;i<rs.length;i++) {
            // if we don't have cache info the playlist is probably deleted
            // and user will have to relink
            var uri = spotifyDataCache.getPlaylistProperty(rs[i].playlist_id, "uri")
            if(!uri)
                rs[i].playlist_id = undefined
            recommendationsModel.append({recommendationSet: rs[i]})
        }
    }

    function addNewSet() {
        var rs = {
            name: "New Recommendations",
            seeds: [],
            attributes: [],
            use_attributes: false
        }
        recommendationsModel.append({recommendationSet: rs})
        app.addRecommendationSet(rs)
    }

    function deleteSet(model) {
        var index = model.index
        app.showConfirmDialog(i18n.tr("Do you want to delete<br>%1?".arg(model.recommendationSet.name)),
            function() {
                recommendationsModel.remove(index)
                app.removeRecommendationSet(index)
            }
        )
    }

    function _updateSet(model, index, rs) {
        // these do not work
        //recommendationsModel.set(index, recommendationSet)
        //recommendationsModel.get(index).recommendationSet.name = newName.text

        // this gives an error but does seem to work
        //recommendationsModel.setProperty(index, "recommendationSet", recommendationSet)
        // this works
        recommendationsModel.remove(index, 1)
        recommendationsModel.insert(index, {recommendationSet: rs})

        app.updateRecommendationSet(index, rs)
    }

    function editSet(model) {
        var index = model.index
        var page = app.pageStack.push(Qt.resolvedUrl("Recommended.qml"))
        page.setRecommendationData(model.recommendationSet)
        page.closed.connect(function() {
            var rs = page.recommendationData.getSaveData()
            _updateSet(recommendationsModel, index, rs)
        })
    }

    function renameSet(model) {
        var dialog = PopupUtils.open(renameDialog)
        dialog.oldName = model.recommendationSet.name
        dialog.recommendationSet = model.recommendationSet
        dialog.index = model.index
    }

    RecommendationData {
        id: tempRD
    }

    function linkToPlaylist(model) {
        var index = model.index
        var rs = model.recommendationSet
        app.choosePlaylist(i18n.tr("Select Playlist to Link to"), model.recommendationSet.name, function(item) {
            rs.playlist_id = item.id
            _updateSet(recommendationsModel, index, rs)
        })
    }

    function generatePlaylist(model) {
        var name = model.recommendationSet.name
        app.showConfirmDialog(
            i18n.tr("Do you want to update the tracks of linked playlist for<br><b>%1</b>").arg(name), function() {

            tempRD.loadData(model.recommendationSet)
            app.updatePlaylistFromRecommendations(tempRD, function(playlistId, snapshotId) {
                showConfirmDialog(
                    i18n.tr("Refreshing Tracks in Playlist succeeded. Do you want to start playing %1?").arg(name),
                    function() {
                        app.ensurePlaylistIsPlaying(playlistId, snapshotId)
                    }
                )
            })
        })
    }

    /*function generatePlaylist(model) {
        app.showConfirmDialog(
            i18n.tr("Do you want to create or update %1?").arg(model.name), function(info) {

            tempRD.loadData(model.recommendationSet)
            app.createPlaylistFromRecommendations(tempRD.name, i18n.tr("Hutspot playlist based on a Recommendation Set"), tempRD)
        })
    }*/

    Component {
        id: renameDialog

        Dialog {
            id: dialogRename
            title: i18n.tr("Rename")

            property string oldName: ""
            property var recommendationSet
            property var index

            TextField {
                id: newName
                inputMethodHints: Qt.ImhNoPredictiveText
                text: oldName
            }

            Button {
                text: i18n.tr("Change")
                enabled: newName.text.length > 0
                onClicked: {
                    recommendationSet.name = newName.text
                     _updateSet(recommendationsModel, index, recommendationSet)
                    PopupUtils.close(dialogRename)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogRename)
            }
            Component.onCompleted: newName.forceActiveFocus()
        }
    }


    function getCoverImage(playlist_id) {
        if(!playlist_id)
            return defaultUnlinkedImage
        var url = app.spotifyDataCache.getPlaylistProperty(playlist_id, "image")
        if(url)
            return url
        return defaultLinkedImage
    }


    function updateForPlaylist(playlistId) {
        for(var i=0;i<recommendationsModel.count;i++) {
            // testing if this will update the ListElement
            var rs = recommendationsModel.get(i).recommendationSet
            if(rs.playlist_id && rs.playlist_id == playlistId)
                recommendationsModel.setProperty(index, "recommendationSet", rs)
        }
    }

    function saveSeedsAndAttributes() {
        var page = app.pageStack.push(Qt.resolvedUrl("../components/ExportRecommendationsDataPage.qml"), {saveData: app.settings.recommendationsData})
    }

    function loadSeedsAndAttributes() {
        var page = app.pageStack.push(Qt.resolvedUrl("../components/ImportRecommendationsDataPage.qml"))
        page.imported.connect(function(data) {
            console.log("imported recommendations: " + data)
            app.pageStack.pop()
            app.importRecommendationSets(data)
            refresh()
        })
    }

    Connections {
        target: app.spotifyDataCache

        onSpotifyDataCacheReady: {
            showBusy = false
            loadRecommendationsData()
        }

        onPlaylistDetailsUpdated: {
            //console.log("Recommendations.onPlaylistDetailsUpdated " + id)
            for(var i=0;i<recommendationsModel.count;i++) {
                var rs = recommendationsModel.get(i).recommendationSet
                if(rs.playlist_id && rs.playlist_id == id) {
                    //console.log("update image of " + id)
                    rs.image = details.image
                    // update
                    recommendationsModel.setProperty(i, "recommendationSet", rs)
                }
            }
        }
    }

    Component.onCompleted: {
        // we need the cache
        if(app.spotifyDataCache.ready) {
            showBusy = false
            refresh()
        }
    }

    Connections {
        target: app

        onPlaylistEvent: {
            switch(event.type) {
            case Util.PlaylistEventType.ReplacedAllTracks:
                updateForPlaylist(event.id)
                break
            }
        }
    }
}
