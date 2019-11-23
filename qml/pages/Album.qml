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
    id: albumPage
    objectName: "AlbumPage"

    property string defaultImageSource : "image://theme/stock-music"
    property bool showBusy: false
    property var album
    property var albumArtists
    property bool isAlbumSaved: false

    property int currentIndex: -1

    property string currentTrackId: ""

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Album")
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageStack.pop()
            }
        ]
        flickable: listView
    }

    Component {
        id: headerComponent
    Column {

        width: parent.width - 2*app.paddingMedium
        x: app.paddingMedium
        anchors.bottomMargin: app.paddingLarge
        spacing: app.paddingLarge

        Image {
            id: imageItem
            source:  (album && album.images)
                     ? album.images[0].url : defaultImageSource
            width: parent.width * 0.75
            height: width
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
            MouseArea {
                 anchors.fill: parent
                 onClicked: app.controller.playContext(album)
            }
        }

        MetaInfoPanel {
            id: metaLabels
            width: parent.width
            firstLabelText: album.name
            secondLabelText: Util.createItemsString(album.artists, i18n.tr("no artist known"))
            thirdLabelText: {
                var s = ""
                var n = searchModel.count
                if(album.tracks)
                    n = album.tracks.total
                else if(album.total_tracks)
                    n = album.total_tracks
                if(n > 1)
                    s += n + " " + i18n.tr("tracks")
                else if(n === 1)
                    s += 1 + " " + i18n.tr("track")
                if(album.release_date && album.release_date.length > 0)
                    s += ", " + Util.getYearFromReleaseDate(album.release_date)
                if(album.genres && album.genres.length > 0)
                    s += ", " + Util.createItemsString(album.genres, "")
                return s
            }
            onFirstLabelClicked: secondLabelClicked()
            onSecondLabelClicked: app.loadArtist(album.artists)
            onThirdLabelClicked: secondLabelClicked()
            isFavorite: isAlbumSaved
            onToggleFavorite: app.toggleSavedAlbum(album, isAlbumSaved, function(saved) {
                isAlbumSaved = saved
            })
        }
    }
    }

    AlbumTrackContextMenu {
        id: contextMenu
        property var model: null
        property var context
        //property bool enableQueueItems: true
        property bool fromPlaying: false
    }


    ListView {
        id: listView
        model: searchModel

        width: parent.width
        height: parent.height // - app.dockedPanel.visibleSize
        //clip: app.dockedPanel.expanded

        header: headerComponent

        delegate: ListItem {
            id: listItem
            width: parent.width - 2 * app.paddingMedium
            x: app.paddingMedium
            //contentHeight: Theme.itemSizeExtraSmall

            AlbumTrackListItem {
                id: albumTrackListItem
                dataModel: model
                isFavorite: saved
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            onPressAndHold: {
                contextMenu.model = model
                contextMenu.context = album
                PopupUtils.open(contextMenu, listItem)
            }

            onClicked: app.controller.playTrackInContext(item, album, index)
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    onAlbumChanged: refresh()

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()

        append()

        var artists = []
        for(var i=0;i<album.artists.length;i++)
            artists.push(album.artists[i].id)
        Spotify.getArtists(artists, {}, function(error, data) {
            if(data)
                albumArtists = data.artists
        })

        isAlbumSaved = app.spotifyDataCache.isAlbumSaved(album.id)

        app.notifyHistoryUri(album.uri)
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

        var options = {offset: searchModel.count, limit: cursorHelper.limit}
        if(app.settings.queryForMarket)
            options.market = "from_token"
        Spotify.getAlbumTracks(album.id, options, function(error, data) {
            if(data) {
                try {
                    //console.log("number of AlbumTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    app.loadTracksInModel(data, data.items.length, searchModel, function(data, i) {return data.items[i]})
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
            _loading = false
        })
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
                if(album.id === event.id) {
                    isAlbumSaved = event.isFavorite
                }
                break
            case Util.SpotifyItemType.Track:
                // no way to check if this track is for this album
                // so just try to update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
    }

}
