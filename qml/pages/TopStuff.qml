/**
 * Copyright (C) 2021 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as UCListItem
import QtQuick.Controls 2.2 as QtQc
import QtQuick.Layouts 1.3


import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: topStuffPage
    objectName: "TopStuffPage"


    property int searchInType: 0
    property int rangeClass: 0
    property bool showBusy: false
    property int currentIndex: -1

    header: PageHeader {
        id: pHeader
        flickable: listView
        title: {
            switch(_itemClass) {
            case 0: return i18n.tr("Top Tracks")
            case 1: return i18n.tr("Top Artists")
            case 2: return i18n.tr("My Recently Played")
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
    }


    ListModel {
        id: searchModel
    }

    SearchResultContextMenu {
        id: contextMenu
    }

    // When the ComboButton in the ListView header expands the list scolls up.
    // Unbelievable.
    // Could not prevent this so now we have a timer that triggers a scroll to the top
    // (hopefully, since there is no real api for it).
    // The timer itsef is triggered by the height of the listview of the button.
    // It's hack on hack on hack. Sorry.
    Timer {
      id: scrollToTop
      interval: 1
      running: false
      repeat: false
      onTriggered: {
          //console.log("scrollToTop.onTriggered contentY: " + listView.contentY + ", originY: " + listView.originY)
          listView.contentY = listView.originY - listView.topMargin
          listView.returnToBounds()
      }
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height

        //headerPositioning: ListView.OverlayHeader // does not work
        //headerPositioning: ListView.PullBackHeader // does not work
        //onContentYChanged: console.log(originY + ":" + contentY + ":" + headerItem.height)

        header: Column {
            id: lvColumn

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            Row {
                width: parent.width
                spacing: app.paddingMedium
                height: childrenRect.height
                Label {
                    id: tlabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Range")
                }
                ComboButton {
                    id: cbSelector
                    //anchors.right: parent.right
                    width: parent.width - tlabel.width - app.paddingLarge
                    //expandedHeight: collapsedHeight + units.gu(1) + cbChoices.length * units.gu(6)
                    text: cbChoices[currentIndex]
                    property int currentIndex: -1
                    property var cbChoices: [
                        i18n.tr("Short (weeks)"),
                        i18n.tr("Medium (months)"),
                        i18n.tr("Long (years)"),
                    ]
                    comboList:  UbuntuListView {
                        delegate: UCListItem.Standard {
                            text: modelData
                            selected: model.index == cbSelector.currentIndex
                            onClicked: {
                                cbSelector.currentIndex = model.index
                                rangeClass = index
                                refresh()
                                //listView.interactive = true
                                cbSelector.expanded = false
                            }
                        }
                        model: cbSelector.cbChoices
                    }
                    Connections {
                        target: cbSelector.__styleInstance.comboListPanel
                        onHeightChanged: {
                            //console.log("onHeightChanged: " + height + " (" + cbSelector.expandedHeight + ")")
                            if(height >= (cbSelector.expandedHeight*0.9))
                                scrollToTop.running = true
                        }
                    }
                    Component.onCompleted: currentIndex = rangeClass
                }

            }
            Rectangle {
                width: parent.width
                height: app.paddingMedium
                opacity: 0
            }
        }

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

            onClicked: {
                switch(type) {
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: item})
                    break;
                case 3:
                    app.pushPage(Util.HutspotPage.Album, {album: item.album})
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

    property int _itemClass: app.settings.currentItemClassTopStuff

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 2)
            i = 0
        _itemClass = i
        app.settings.currentItemClassTopStuff = i
        refresh()
    }

    function prevItemClass() {
        var i = _itemClass
        i--
        if(i < 0)
            i = 2
        _itemClass = i
        app.settings.currentItemClassTopStuff = i
        refreshDirection = 0
        refresh()
    }

    function refresh() {
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

        var range = rangeClass == 0
                    ? "short_term"
                    : (rangeClass == 1 ? "medium_term" : "long_term")
        var options = {offset: searchModel.count, limit: cursorHelper.limit, time_range: range}
        var i, options;
        switch(_itemClass) {
        case 0:
            Spotify.getMyTopTracks(options, function(error, data) {
                try {
                    if(data) {
                        //console.log("number of TopTracks: " + data.items.length)
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                        app.loadTracksInModel(data, data.items.length, searchModel, function(data, i) {return data.items[i]})
                    } else
                        console.log("No Data for getMyTopTracks")
                } catch(err) {
                    console.log("getMyTopTracks exception: " + err)
                } finally {
                    _loading = false
                }
            })
            break

        case 1:
            Spotify.getMyTopArtists(options, function(error, data) {
                try {
                    if(data) {
                        //console.log("number of MyTopArtists: " + data.items.length)
                        cursorHelper.offset = data.offset
                        cursorHelper.total = data.total
                        for(i=0;i<data.items.length;i++) {
                            var artist = data.items[i]
                            searchModel.append({type: 1,
                                                name: artist.name,
                                                item: artist,
                                                following: app.spotifyDataCache.isArtistFollowed(artist.id),
                                                saved: false})
                        }
                    } else
                        console.log("No Data for getMyTopArtists")
                } catch(err) {
                    console.log("getMyTopArtists exception: " + err)
                } finally {
                    _loading = false
                }
            })
            break

        case 2:
            // unfortunately:
            //   Any tracks listened to while the user had “Private Session” enabled in
            //   their client will not be returned in the list of recently played tracks.
            // and it seems Librespot just does that when using credentials
            options = {limit: cursorHelper.limit}
            // 'RecentlyPlayedTracks' has 'before' and 'after' fields
            if(refreshDirection < 0) // previous set is looking forward in time
                options.after = cursorHelper.after
            else if(refreshDirection > 0) // next set is looking back in time
                options.before = cursorHelper.before
            Spotify.getMyRecentlyPlayedTracks(options, function(error, data) {
                try {
                    if(data) {
                        //console.log("number of RecentlyPlayedTracks: " + data.items.length)
                        cursorHelper.update(Util.loadCursor(data, Util.CursorType.RecentlyPlayed))
                        app.loadTracksInModel(data, data.items.length, searchModel, function(data, i) {return data.items[i].track})
                    } else
                        console.log("No Data for getMyRecentlyPlayedTracks")
                } catch(err) {
                    console.log("getMyRecentlyPlayedTracks exception: " + err)
                } finally {
                    _loading = false
                }
            })
            break
        }
    }

    property int refreshDirection: 0
    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    function isCurrentClass(type) {
        switch(type) {
        //case Util.SpotifyItemType.Album:
        //case Util.SpotifyItemType.Playlist:
        case Util.SpotifyItemType.Track:
            return _itemClass === 0 || _itemClass === 2
        case Util.SpotifyItemType.Artist:
            return _itemClass === 1
        //case Util.SpotifyItemType.Show:
        }
        return false
    }

    Connections {
        target: app

        onHasValidTokenChanged: refresh()

        onFavoriteEvent: {
            if(!isCurrentClass(event.type))
                return
            Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
        }
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
