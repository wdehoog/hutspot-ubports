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
    id: artistPage
    objectName: "ArtistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var currentArtist
    property var _fullArtist
    property bool isFollowed: false

    property int currentIndex: -1


    ListModel {
        id: searchModel
    }

    header: PageHeader {
        id: pHeader
        width: parent.width
        title: {
            switch(_itemClass) {
            case 0: return i18n.tr("Artist's Albums")
            case 1: return i18n.tr("Artist's Related Artists")
            }
        }
        /*title: {
            switch(_itemClass) {
            case 0: return Util.createPageHeaderLabel(qsTr("Artist "), qsTr("Albums"), Theme)
            case 1: return Util.createPageHeaderLabel(qsTr("Artist "), qsTr("Related Artists"), Theme)
            }
        }*/
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageStack.pop()
            }
        ]
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
            },
            Action {
                iconName: "external-link"
                text: qsTr("Load Artist About Page in Browser")
                visible: currentArtist && currentArtist.external_urls["spotify"]
                onTriggered: Qt.openUrlExternally(currentArtist.external_urls["spotify"] + "/about")
            }
        ]
        flickable: listView
    }

    SearchResultContextMenu {
        id: contextMenu
        property var model
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
                source: (_fullArtist && _fullArtist.images)
                        ? _fullArtist.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                       anchors.fill: parent
                       onClicked: app.controller.playContext(currentArtist)
                }
            }

            MetaInfoPanel {
                firstLabelText: currentArtist ? currentArtist.name : qsTr("No Name")
                secondLabelText: {
                    if(!_fullArtist)
                        return ""
                    var s = ""
                    if(_fullArtist && _fullArtist.genres && _fullArtist.genres.length > 0)
                        s += Util.createItemsString(_fullArtist.genres, "")
                    return s
                }
                thirdLabelText: {
                    if(!_fullArtist)
                        return ""
                    return _fullArtist.followers && _fullArtist.followers.total > 0
                                ? Util.abbreviateNumber(_fullArtist.followers.total) + " " + qsTr("followers")
                                : ""
                }

                isFavorite: isFollowed
                onToggleFavorite: app.toggleFollowArtist(currentArtist, isFollowed, function(followed) {
                    isFollowed = followed
                })
            }

            /*Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }*/
        }}

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
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
                }
            }
        }


    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    onCurrentArtistChanged: {
        if(currentArtist && !currentArtist.hasOwnProperty("genres")) {
            _fullArtist = null
            Spotify.getArtist(currentArtist.id, {}, function(error, data) {
                if(data)
                    _fullArtist = data
                else
                    console.log("Failed to load full Artist: " + currentArtist.id)
            })
        }
        _fullArtist = currentArtist
        refresh()
    }

    property var artistAlbums
    property var relatedArtists
    property int _itemClass: app.settings.currentItemClassArtist

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 1)
            i = 0
        _itemClass = i
        app.current_item_classes.artist = i
        refresh()
    }

    function loadData() {
        var i;

        isFollowed = app.spotifyDataCache.isArtistFollowed(currentArtist.id)

        if(artistAlbums) {
            for(i=0;i<artistAlbums.items.length;i++) {
                searchModel.append({type: 0,
                                    name: artistAlbums.items[i].name,
                                    item: artistAlbums.items[i],
                                    following: app.spotifyDataCache.isArtistFollowed(artistAlbums.items[i].id)})
            }
        }

        if(relatedArtists) {
            for(i=0;i<relatedArtists.artists.length;i++) {
                searchModel.append({type: 1,
                                    name: relatedArtists.artists[i].name,
                                    item: relatedArtists.artists[i],
                                    following: app.spotifyDataCache.isArtistFollowed(relatedArtists.artists[i].id)})
            }
        }

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()        
        artistAlbums = undefined
        relatedArtists = undefined
        append()
        app.notifyHistoryUri(currentArtist.uri)
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
        switch(_itemClass) {
        case 0:
            Spotify.getArtistAlbums(currentArtist.id,
                                    {offset: searchModel.count, limit: cursorHelper.limit},
                                    function(error, data) {
                if(data) {
                    console.log("number of ArtistAlbums: " + data.items.length)
                    artistAlbums = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else {
                    console.log("No Data for getArtistAlbums")
                }
                loadData()
                _loading = false
            })
            break
        case 1:
            Spotify.getArtistRelatedArtists(currentArtist.id,
                                            {offset: searchModel.count, limit: cursorHelper.limit},
                                            function(error, data) {
                if(data) {
                    console.log("number of ArtistRelatedArtists: " + data.artists.length)
                    relatedArtists = data
                    cursorHelper.offset = 0 // no cursor, always 20
                    cursorHelper.total = data.artists.length
                } else {
                    console.log("No Data for getArtistRelatedArtists")
                }
                loadData()
                _loading = false
            })
            break
        }
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Artist:
                if(currentArtist.id === event.id)
                    isFollowed = event.isFavorite
                else
                    Util.setFollowedInfo(event.id, event.isFavorite, searchModel)
                break
            }
        }
    }

}
