/**
 * Copyright (C) 2018 Willem-Jan de Hoog
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
    id: historyPage
    objectName: "HistoryPage"

    property bool showBusy: false

    property int currentIndex: -1

    header: PageHeader {
        id: header
        title: i18n.tr("History")
        flickable: listView
        trailingActionBar.actions: [
            Action {
                iconName: "edit-clear"
                text: i18n.tr("Clear")
                onTriggered: {
                    app.showConfirmDialog(i18n.tr("Clear History?"), function() {
                        app.clearHistory()
                    })
                }
            }
        ]
    }

    ListModel {
        id: searchModel
    }

    SearchResultContextMenu {
        id: contextMenu
        property var model
        property var contextType: -1
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height 

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
                onToggleFavorite: app.handleToggleFavorite(model)
            }

            onPressAndHold: {
                contextMenu.model = model
                PopupUtils.open(contextMenu, listItem)
            }

            onClicked: {
                switch(type) {
                case 0:
                    app.pushPage(Util.HutspotPage.Album, {album: item})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: item})
                    break;
                case 2:
                    app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
                    break;
                }
            }
        }

    }

    Scrollbar {
      id: scrollBar
      flickableItem: listView
      anchors.right: parent.right
    }

    Connections {
        target: app
        onHistoryModified: {
          console.log("onHistoryModified: " + added + ";" + removed)
            if(added >= 0 && removed === -1)          // a new one
                loadFirstOne()
            else if(added >= 0)                       // a moved one
                searchModel.move(removed, added, 1)
            else if(added === -1 && removed >= 0)     // a removed one
                searchModel.remove(removed)
            else if(added === -1 && removed === -1) { // new history
                searchModel.clear()
                refresh()
            }
        }
    }

    function reload() {
        console.log("reload")
        searchModel.clear()

        for(var p=0;p<parsed.length;p++) {
            for(var i=0;i<retrieved.length;i++) {
                if(parsed[p].id === retrieved[i].data.id) {
                    switch(retrieved[i].type) {
                    case Util.SpotifyItemType.Album:
                        searchModel.append({type: 0,
                                            name: retrieved[i].data.name,
                                            item: retrieved[i].data,
                                            following: false,
                                            saved: app.spotifyDataCache.isAlbumSaved(retrieved[i].data.id)})
                        break
                    case Util.SpotifyItemType.Artist:
                        searchModel.append({type: 1,
                                            name: retrieved[i].data.name,
                                            item: retrieved[i].data,
                                            following: app.spotifyDataCache.isArtistFollowed(retrieved[i].data.id),
                                            saved: false})
                        break
                    case Util.SpotifyItemType.Playlist:
                        searchModel.append({type: 2,
                                            name: retrieved[i].data.name,
                                            item: retrieved[i].data,
                                            following: app.spotifyDataCache.isPlaylistFollowed(retrieved[i].data.id),
                                            saved: false})
                        break
                    }
                    break
                }
            }
        }
        retrieved = []
        parsed = []
        console.log("history reloaded")
    }

    function checkReload(count) {
        retrievedCount += count
        if(retrievedCount === numberToRetrieve)
            reload()
    }

    property var retrieved: []
    property var parsed: []
    property int retrievedCount: 0
    property int numberToRetrieve: 0

    function refresh() {
        var i;
        showBusy = true
        retrieved = []
        retrievedCount = 0
        parsed = []
        _refresh(app.history.length)
    }

    function loadFirstOne() {
        retrieved.unshift({})
        parsed.unshift({})
        retrievedCount = 0
        _refresh(1)
    }

    function _refresh(count) {
        if(count > app.history.length)
            count = app.history.length
        numberToRetrieve = count

        // group the requests
        var qalbums = []
        var qartists = []
        for(var i=0;i<count;i++) {
            var p = Util.parseSpotifyUri(app.history[i])
            parsed[i] = p
            if(p.type === undefined)
                continue

            switch(p.type) {
            case Util.SpotifyItemType.Album:
                qalbums.push(p.id)
                if(qalbums.length == 20) { // Spotify allows 20 max
                    getAlbums(qalbums)
                    qalbums = []
                }
                break
            case Util.SpotifyItemType.Artist:
                qartists.push(p.id)
                // Spotify allows 50 max. our max as well
                break
            case Util.SpotifyItemType.Playlist:
                // unfortunately getting playlists cannot be grouped
                Spotify.getPlaylist(p.id, function(error, data) {
                    if(data) {
                        retrieved.push({type: 2, data: data})
                    } else
                        console.log("No Data for getPlaylist" + p.id)
                    checkReload(1)
                })
                break
            }
        }
        if(qalbums.length > 0)
            getAlbums(qalbums)
        if(qartists.length > 0)
            getArtists(qartists)
    }

    function getAlbums(albumIds) {
        // 'market' enables 'track linking'
        var options = {} // {offset: cursorHelper.offset, limit: cursorHelper.limit}
        if(app.settings.queryForMarket)
            options.market = "from_token"
        Spotify.getAlbums(albumIds, options, function(error, data) {
            if(data) {
                for(var i=0;i<albumIds.length;i++)
                    retrieved.push({type: 0, data: data.albums[i]})
            } else
                console.log("No Data for getAlbums")
            checkReload(albumIds.length)
        })
    }

    function getArtists(artistIds) {
        Spotify.getArtists(artistIds, function(error, data) {
            if(data) {
                for(var i=0;i<artistIds.length;i++)
                    retrieved.push({type: 1, data: data.artists[i]})
            } else
                console.log("No Data for getArtists")
            checkReload(artistIds.length)
        })
    }

    Connections {
        target: app
        onHasValidTokenChanged: refresh()
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Artist:
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
        // if this is the first page data might already be loaded before the data cache is ready
        //onSpotifyDataCacheReady: Util.updateFollowingSaved(app.spotifyDataCache, searchModel)
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
