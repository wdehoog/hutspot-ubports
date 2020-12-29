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
    id: showPage
    objectName: "ShowPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property var show
    property var showArtists
    property bool isShowSaved: false

    property int currentIndex: -1

    property string currentTrackId: ""

    header: PageHeader {
        id: header
        title: i18n.tr("Show")
        flickable: listView
    }

    ListModel {
        id: searchModel
    }

    Component {
        id: headerComponent
        Column {
            id: lvColumn

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            anchors.bottomMargin: app.paddingLarge
            spacing: app.paddingLarge

            Image {
                id: imageItem
                source:  (show && show.images)
                         ? show.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                     anchors.fill: parent
                     //onClicked: app.controller.playContext(show)
                }
            }

            MetaInfoPanel {
                id: metaLabels
                width: parent.width
                firstLabelText: show.name
                secondLabelText: show.publisher
                thirdLabelText: {
                    var s = ""
                    if(app.controller.playbackState.context.total_episodes)
                        s += app.controller.playbackState.context.total_episodes + " " + i18n.tr("episodes")
                    s += ", " + i18n.tr("by") + " " + app.controller.playbackState.context.publisher
                    if(app.controller.playbackState.context.explicit)
                        s += ", " +  i18n.tr("explicit")
                    s += ", " + Util.createItemsString(app.controller.playbackState.context.languages, "")
                    return s
                }
                onFirstLabelClicked: secondLabelClicked()
                onSecondLabelClicked: showMessageDialog("Show Description", show.description)
                onThirdLabelClicked: secondLabelClicked()
                isFavorite: isShowSaved
                onToggleFavorite: app.toggleSavedShow(show, isShowSaved, function(saved) {
                    isShowSaved = saved
                })
            }

            /*Separator {
                width: parent.width
                color: Theme.primaryColor
            }*/

        }
    }

    SearchResultContextMenu {
        id: contextMenu
        contextType: Util.SpotifyItemType.Show
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height

        header: headerComponent

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }

            onPressAndHold: {
                contextMenu.open(model, listItem)
            }

            //onClicked: app.controller.playTrackInContext(item, show)
            onClicked: showMessageDialog("Episode Description", item.description)
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

    onShowChanged: refresh()

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        //onLoadNext: refresh()
        //onLoadPrevious: refresh()
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()

        append()

        /*var artists = []
        for(var i=0;i<album.artists.length;i++)
            artists.push(album.artists[i].id)
        Spotify.getArtists(artists, {}, function(error, data) {
            if(data)
                albumArtists = data.artists
        })

        isAlbumSaved = app.spotifyDataCache.isAlbumSaved(album.id)*/

        //app.notifyHistoryUri(album.uri)
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
        Spotify.getShow(show.id, options, function(error, data) {
            if(data) {
                try {
                    // name, release_date, duration
                    cursorHelper.offset = data.episodes.offset
                    cursorHelper.total = data.episodes.total
                    for(var i=0;i<data.episodes.items.length;i++) {
                        searchModel.append({type: Util.SpotifyItemType.Episode,
                                            name: data.episodes.items[i].name,
                                            item: data.episodes.items[i],
                                            following: false,
                                            saved: false})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getShow")
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
