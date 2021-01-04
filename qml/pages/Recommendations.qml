/**
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: genreMoodPage
    objectName: "RecommendationsPage"

    property bool showBusy: false
    property url defaultImage: Qt.resolvedUrl("../resources/broken-link.svg")

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
                        id: a
                        property int idx: enabled ? 0 : -1
                        text: contextMenu.model.recommendationSet.playlist_id
                            ? i18n.tr("Refresh Playlist Tracks")
                            : i18n.tr("Link to Playlist")
                        onTriggered: contextMenu.model.recommendationSet.playlist_id
                            ? generatePlaylist(contextMenu.model)
                            : linkToPlaylist(contextMenu.model)
                    }
                    Action {
                        id: b
                        property int idx: enabled ? (a.idx + 1) : a.idx
                        text: i18n.tr("Rename")
                        onTriggered: renameSet(contextMenu.model)
                    }
                    Action {
                        id: c
                        property int idx: enabled ? (b.idx + 1) : b.idx
                        text: i18n.tr("Edit")
                        onTriggered: editSet(contextMenu.model)
                    }
                    Action {
                        id: d
                        property int idx: enabled ? (c.idx + 1) : c.idx
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
                    height: app.itemSizeMedium //parent.height - app.paddingSmall
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: getCoverImage(recommendationSet.playlist_id)
                }

                Column {
                    width: parent.width - playlistImage.width - app.paddingMedium
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

    function refresh() {
        recommendationsModel.clear()
        loadRecommendationsData(app.settings.recommendationsData)
    }

    function loadRecommendationsData(recommendationsData) {
        //console.log("load: " + recommendationsData)
        var rs = JSON.parse(recommendationsData)
        if(!Util.isArray(rs)) {
            app.showErrorMessage(undefined, "Invalid Recommendations Data")
            return
        }

        var i
        for(i=0;i<rs.length;i++) {
            recommendationsModel.append({recommendationSet: rs[i]})
        }
    }

    function saveTosettings() {
        var rs = [recommendationsModel.count]
        for(var i=0;i<recommendationsModel.count;i++)
            rs[i] = recommendationsModel.get(i).recommendationSet
        //console.log("save: " + JSON.stringify(rs))
        app.settings.recommendationsData = JSON.stringify(rs)
    }

    function addNewSet() {
        var rs = {
            name: "New Recommendations",
            seeds: [],
            attributes: [],
            use_attributes: false
        }
        recommendationsModel.append({recommendationSet: rs})
        saveTosettings()
    }

    function deleteSet(model) {
        app.showConfirmDialog(i18n.tr("Do you want to delete<br>%1?".arg(model.recommendationSet.name)),
            function() {
                recommendationsModel.remove(model.index)
                saveTosettings()
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
        saveTosettings()
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
        app.showConfirmDialog(
            i18n.tr("Do you want to update the tracks of linked playlist for<br><b>%1</b>").arg(model.recommendationSet.name), function() {
           
            tempRD.loadData(model.recommendationSet)
            app.updatePlaylistFromRecommendations(tempRD)
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
        var url = app.spotifyDataCache.getPlaylistImage()
        if(!url)
            url = defaultImage
        return url      
    }

    /*Connections {
        target: app.spotifyDataCache

        // if this is the first page data might already be loaded before the data cache is ready
        onSpotifyDataCacheReady: {
            var i
            for(i=0;i<recommendationsModel.count;i++) {
                var obj = recommendationsModel.get(i)
                if(obj  
            }
        }
    }*/

    Component.onCompleted: {
        loadRecommendationsData(app.settings.recommendationsData)
    }
}
