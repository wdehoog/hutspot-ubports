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

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: libraryPage

    property string authURL: ""

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: {
            switch(_itemClass) {
            case 0: return i18n.tr("Saved Albums")
            case 1: return i18n.tr("Playlists")
            case 2: return i18n.tr("Saved Tracks")
            case 3: return i18n.tr("Followed Artists")
            case 4: return i18n.tr("Saved Shows")
            }
        }
        trailingActionBar.actions: [
            Action {
                iconName: "go-next"
                text: i18n.tr("next")
                onTriggered: nextItemClass()
            },
            Action {
                iconName: "go-previous"
                text: i18n.tr("previous")
                onTriggered: prevItemClass()
            }
        ]
        flickable: listView
    }

    property int currentIndex: -1

    SortedListModel {
        id: searchModel
        sortKey: "name"
    }

    SearchResultContextMenu {
        id: contextMenu
    }

    ListView {
        id: listView
        anchors.fill: parent
        //spacing: 
        model: searchModel
        //interactive: contentHeight > height

        delegate: ListItem {
            id: listItem
            width: parent.width - 2 * app.paddingMedium
            x: app.paddingMedium
            //contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }

            onPressAndHold: {
                contextMenu.open(model, listItem)
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
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: item.album})
                    break;
                case 5:
                    app.pushPage(Util.HutspotPage.Show, {show: item})
                    break;
                }
            }
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

    property var savedAlbums
    property var userPlaylists
    property var savedTracks
    property var followedArtists
    property var savedShows

    property int _itemClass: (app.settings.currentItemClassLibrary >= 0
                              && app.settings.currentItemClassLibrary <= 4)
                             ? app.settings.currentItemClassLibrary
                             : 0

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 4)
            i = 0
        _itemClass = i
        app.settings.currentItemClassLibrary = i
        refreshDirection = 0
        refresh()
    }

    function prevItemClass() {
        var i = _itemClass
        i--
        if(i < 0)
            i = 4
        _itemClass = i
        app.settings.currentItemClassLibrary = i
        refreshDirection = 0
        refresh()
    }

    function addData(obj) {
        obj.nameFirstChar = Util.getFirstCharForSection(obj.name)
        if(!obj.hasOwnProperty('played_at'))
            obj.played_at = ""
        if(!obj.hasOwnProperty('following'))
            obj.following = false
        searchModel.add(obj)
    }

    function loadData() {
        var i

        // if total too high disable sorting
        if(searchModel.count == 0) {
            if(cursorHelper.total <= app.settings.sorted_list_limit) {
                searchModel.sortKey = "name"
                //listView.section.delegate = listView.sectionDelegate
            } else {
                searchModel.sortKey = ""
                //listView.section.delegate = null
            }
        }

        // more to load?
        var count = searchModel.count
        if(savedAlbums)
            count += savedAlbums.items.length
        else if(userPlaylists)
            count += userPlaylists.items.length
        else if(savedTracks)
            count += savedTracks.items.length
        else if(followedArtists)
            count += followedArtists.artists.items.length
        else if(savedShows)
            count += savedShows.items.length
        if(count < cursorHelper.total)
            append()

        // add data
        if(savedAlbums)
            for(i=0;i<savedAlbums.items.length;i++)
                addData({type: 0,
                         name: savedAlbums.items[i].album.name,
                         item: savedAlbums.items[i].album,
                         following: false, saved: true})
        if(userPlaylists)
            for(i=0;i<userPlaylists.items.length;i++) {
                addData({type: 2,
                         name: userPlaylists.items[i].name,
                         item: userPlaylists.items[i],
                         following: true, saved: false})
            }
        if(savedTracks)
            for(i=0;i<savedTracks.items.length;i++) {
                addData({type: 3,
                         name: savedTracks.items[i].track.name,
                         item: savedTracks.items[i].track,
                         following: true, saved: true})
            }
        if(followedArtists)
            for(i=0;i<followedArtists.artists.items.length;i++) {
                addData({type: 1,
                         name: followedArtists.artists.items[i].name,
                         item: followedArtists.artists.items[i],
                         following: true, saved: false})
            }
        if(savedShows)
            for(i=0;i<savedShows.items.length;i++) {
                addData({type: 5,
                         name: savedShows.items[i].show.name,
                         item: savedShows.items[i].show,
                         following: false, saved: true})
            }
    }

    property int nextPrevious: 0


    function refresh() {
        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        followedArtists = undefined
        savedShows = undefined
        append()
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

        var i, options;
        switch(_itemClass) {
        case 0:
            Spotify.getMySavedAlbums({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedAlbums: " + data.items.length)
                    savedAlbums = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedAlbums")
                loadData()
                _loading = false
            })
            break
        case 1:
            Spotify.getUserPlaylists({offset: searchModel.count, limit: cursorHelper.limit},function(error, data) {
                if(data) {
                    console.log("number of playlists: " + data.items.length)
                    userPlaylists = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getUserPlaylists")
                loadData()
                _loading = false
            })
            break
        case 2:
            Spotify.getMySavedTracks({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedTracks: " + data.items.length)
                    savedTracks = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedTracks")
                loadData()
                _loading = false
            })
            break
        case 3:
            // 'Followed Artists' only has an 'after' field
            options = {limit: cursorHelper.limit}
            if(refreshDirection > 0)
                options.after = cursorHelper.after
            Spotify.getFollowedArtists(options, function(error, data) {
                if(data) {
                    console.log("number of FollowedArtists: " + data.artists.items.length)
                    followedArtists = data
                    cursorHelper.update(Util.loadCursor(data.artists, Util.CursorType.FollowedArtists))
                } else
                    console.log("No Data for getFollowedArtists")
                loadData()
                _loading = false
            })
            break
        case 4:
            Spotify.getMySavedShows({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedShows: " + data.items.length)
                    savedShows = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedShows")
                loadData()
                _loading = false
            })
            break
        }
    }

    property int refreshDirection: 0
    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        useHas: true
    }

    function isCurrentClass(type) {
        switch(type) {
        case Util.SpotifyItemType.Album:
            return _itemClass === 0
        case Util.SpotifyItemType.Playlist:
            return _itemClass === 1
        case Util.SpotifyItemType.Track:
            return _itemClass === 2
        case Util.SpotifyItemType.Artist:
            return _itemClass === 3
        case Util.SpotifyItemType.Show:
            return _itemClass === 4
        }
        return false
    }

    Connections {
        target: app
        onHasValidTokenChanged: {
          console.log("Library.onHasValidTokenChanged")
          refresh()
        }

        onFavoriteEvent: {
            if(!isCurrentClass(event.type))
                return
            if(!event.isFavorite)
                Util.removeFromListModel(searchModel, event.type, event.id)
            else
                refresh()
        }
    }

    Component.onCompleted: {
        console.log("Library.onCompleted hasValidToken=" + app.hasValidToken)
        if(app.hasValidToken)
            refresh()
    }
}
