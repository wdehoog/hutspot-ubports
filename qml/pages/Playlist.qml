/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
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
    id: playlistPage
    objectName: "PlaylistPage"

    property string defaultImageSource : "image://theme/stock-music"
    property bool showBusy: false

    property var playlist
    property bool isFollowed: false

    property int currentIndex: -1

    // binding to playlist properties does not seem to work
    // (not updated when modified)
    property string playListName: ""
    property string playlistDescription: ""
    property string playlistMetaText: ""

    header: PageHeader {
        id: header
        title: i18n.tr("Playlist")
        flickable: listView
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Edit Details")
                iconName: "edit"
                onTriggered: app.editPlaylistDetails(playlist)

            }
        ]
    }

    ListModel {
        id: searchModel
    }

    SearchResultContextMenu {
        id: contextMenu
        property int index
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height // - app.dockedPanel.visibleSize
        //clip: app.dockedPanel.expanded

        header: Component { Column {
            id: lvColumn

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            anchors.bottomMargin: app.paddingLarge
            spacing: app.paddingMedium


            Image {
                id: imageItem
                source: (playlist && playlist.images)
                        ? playlist.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                     anchors.fill: parent
                     onClicked: app.controller.playContext(playlist)
                }
            }

            MetaInfoPanel {
                id: metaInfoPanel
                width: parent.width

                isFavorite: isFollowed

                // unfortunately binding to playlist properties (playlist.name)
                // does not work: the text is not updated when the property changes value
                firstLabelText: playListName
                secondLabelText: playlistDescription
                thirdLabelText: playlistMetaText

                onFirstLabelClicked: secondLabelClicked()
                onSecondLabelClicked: app.editPlaylistDetails(playlist)
                onThirdLabelClicked: secondLabelClicked()

                onToggleFavorite: app.toggleFollowPlaylist(playlist, isFollowed, function(followed) {
                    isFollowed = followed
                })
            }

            Rectangle {
                width: parent.width
                height: app.paddingMedium
                opacity: 0
            }
        }}

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            //contentHeight: app.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
                contextType: Util.SpotifyItemType.Playlist
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            onPressAndHold: {
                contextMenu.index = index
                contextMenu.contextType = Util.SpotifyItemType.Playlist
                contextMenu.open(model, listItem)
            }

            onClicked: app.pushPage(Util.HutspotPage.Album, {album: item.album})
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }
    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    // when the page is on the stack but not on top a refresh can wait
    property bool _needsRefresh: false

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    Connections {
        target: app

        onPlaylistEvent: {
            if(playlist.id !== event.playlistId)
                return
            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
                // in theory it has been added at the end of the list
                // so we could load the info and add it to the model but
                // we schedule a refresh
                if(playlistPage.status === PageStatus.Active)
                    refresh()
                else
                    _needsRefresh = true
                break
            case Util.PlaylistEventType.RemovedTrack:
                Util.removeFromListModel(searchModel, Spotify.ItemType.Track, event.trackId)
                break
            case Util.PlaylistEventType.ChangedDetails:
                refreshDetails()
                break
            }
        }

        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Playlist:
                if(playlist.id === event.id) {
                    isFollowed = event.isFavorite
                }
                break
            }
        }
    }

    onPlaylistChanged: refresh()

    // binding firstLabelText to playlist.name will not work since changing
    // playlist.name value does not seem to trigger an update
    function updatePlaylistTexts() {
        playListName = playlist.name
        playlistDescription = playlist.description ? playlist.description : ""
        var s = playlist.tracks.total + " " + qsTr("tracks")
        s += ", " + qsTr("by") + " " + playlist.owner.display_name
        if(playlist.followers && playlist.followers.total > 0)
            s += ", " + Util.abbreviateNumber(playlist.followers.total) + " " + qsTr("followers")
        if(playlist["public"])
            s += ", " +  qsTr("public")
        if(playlist.collaborative)
            s += ", " +  qsTr("collaborative")
        playlistMetaText = s
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()        
        append()
        app.isFollowingPlaylist(playlist.id, function(error, data) {
            if(data)
                isFollowed = data[0]
        })

        app.notifyHistoryUri(playlist.uri)

        // description is not send with getUserPlaylists so get it using getPlaylist
        refreshDetails()

        updatePlaylistTexts()
    }

    property bool _loading: false

    function append() {
        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        var i;
        app.getPlaylistTracks(playlist.id,
                              {offset: searchModel.count, limit: cursorHelper.limit},
                              function(error, data) {
            if(data) {
                try {
                    //console.log("number of PlaylistTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    app.loadTracksInModel(data, data.items.length, searchModel,
                                          function(data, i) {return data.items[i].track},
                                          function(data, i) {return {"added_at" :data.items[i].added_at}})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
            _loading = false
        })
    }

    function refreshDetails() {
        app.getPlaylist(playlist.id, function(error, data) {
            if(data) {
                // update details
                playlist.name = data.name
                playlist.description = data.description
                playlist['public'] = data['public']
                playlist.collaborative = data.collaborative
                updatePlaylistTexts()
            }
        })
    }

}
