import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: myStuffPage

    property string authURL: ""

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: {
            switch(_itemClass) {
            case 0: return i18n.tr("My Saved Albums")
            case 1: return i18n.tr("My Playlists")
            case 2: return i18n.tr("My Saved Tracks")
            case 3: return i18n.tr("My Followed Artists")
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
        sortKey: _itemClass != 2 ? "name" : ""
    }

    SearchResultContextMenu {
        id: contextMenu
        property var model
        property var contextType: -1
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
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: item.album})
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

    // when the page is on the stack but not on top a refresh can wait
    //property bool _needsRefresh: false

    /*Connections {
        target: app

        onPlaylistEvent: {
            if(_itemClass !== 1)
                return
            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
            case Util.PlaylistEventType.ChangedDetails:
            case Util.PlaylistEventType.RemovedTrack:
            case Util.PlaylistEventType.ReplacedAllTracks:
                // check if the playlist is in the current list if so trigger a refresh
                var i = Util.doesListModelContain(searchModel, Spotify.ItemType.Playlist, event.playlistId)
                if(i >= 0) {
                    if(myStuffPage.status === PageStatus.Active)
                        refresh()
                    else
                        _needsRefresh = true
                }
                break
             case Util.PlaylistEventType.CreatedPlaylist:
                 if(myStuffPage.status === PageStatus.Active)
                     refresh()
                 else
                     _needsRefresh = true
                 break
            }
        }
    }*/

    property var savedAlbums
    property var userPlaylists
    property var savedTracks
    property var followedArtists
    // 0: Saved Albums, 1: User Playlists, 2: Saved Tracks, 3: Followed Artists
    property int _itemClass: (app.settings.currentItemClassMyStuff >= 0
                              && app.settings.currentItemClassMyStuff <= 3)
                             ? app.settings.currentItemClassMyStuff
                             : 0

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 3)
            i = 0
        _itemClass = i
        app.settings.currentItemClassMyStuff = i
        refreshDirection = 0
        refresh()
    }

    function prevItemClass() {
        var i = _itemClass
        i--
        if(i < 0)
            i = 3
        _itemClass = i
        app.settings.currentItemClassMyStuff = i
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
                searchModel.sortKey = _itemClass != 2 ? "name" : ""
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
            count += followedArtists.artists.items
        if(count < cursorHelper.total)
            append()

        // add data
        if(savedAlbums)
            for(i=0;i<savedAlbums.items.length;i++)
                addData({type: 0, stype: 0,
                         name: savedAlbums.items[i].album.name,
                         item: savedAlbums.items[i].album,
                         following: false, saved: true})
        if(userPlaylists)
            for(i=0;i<userPlaylists.items.length;i++) {
                addData({type: 2, stype: 2,
                         name: userPlaylists.items[i].name,
                         item: userPlaylists.items[i],
                         following: true, saved: false})
            }
        if(savedTracks)
            for(i=0;i<savedTracks.items.length;i++) {
                addData({type: 3, stype: 4,
                         name: savedTracks.items[i].track.name,
                         item: savedTracks.items[i].track,
                         following: true, saved: true})
            }
        if(followedArtists)
            for(i=0;i<followedArtists.artists.items.length;i++) {
                addData({type: 1, stype: 1,
                         name: followedArtists.artists.items[i].name,
                         item: followedArtists.artists.items[i],
                         following: true, saved: false})
            }
    }

    property int nextPrevious: 0


    function refresh() {
        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        followedArtists = undefined
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
        }
    }

    property int refreshDirection: 0
    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        useHas: true
    }

    Connections {
        target: app
        onHasValidTokenChanged: {
          console.log("MyStuff.onHasValidTokenChanged")
          refresh()
        }
    }

    Component.onCompleted: {
        console.log("MyStuff.onCompleted hasValidToken=" + app.hasValidToken)
        if(app.hasValidToken)
            refresh()
    }
}
