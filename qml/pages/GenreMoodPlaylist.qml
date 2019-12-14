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
    id: genreMoodPlaylistPage
    objectName: "GenreMoodPlaylistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property int currentIndex: -1

    property var category

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        id: header
        title: category.name
        flickable: listView
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
            //contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                dataModel: model
                onToggleFavorite: app.toggleFollowPlaylist(model.item, model.following, function(followed) {
                                      model.following = followed
                                  })
            }

            onPressAndHold: {
                contextMenu.model = model
                PopupUtils.open(contextMenu, listItem)
            }

            onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: item})
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

    function refresh() {
        //showBusy = true
        searchModel.clear()
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

        var i;
        Spotify.getCategoryPlaylists(category.id,
                                     {offset: searchModel.count, limit: cursorHelper.limit},
                                     function(error, data) {
            if(data) {
                try {
                    //console.log("number of Playlists: " + data.playlists.items.length)
                    cursorHelper.offset = data.playlists.offset
                    cursorHelper.total = data.playlists.total
                    for(i=0;i<data.playlists.items.length;i++) {
                        searchModel.append({type: 2,
                                            name: data.playlists.items[i].name,
                                            item: data.playlists.items[i],
                                            following: app.spotifyDataCache.isPlaylistFollowed(data.playlists.items[i].id)})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getCategoryPlaylists")
            }
            _loading = false
        })

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
        onHasValidTokenChanged: refresh()
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
