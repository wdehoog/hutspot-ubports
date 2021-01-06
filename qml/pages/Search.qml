/**
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.Controls 2.2 as QtQc
import QtQuick.Layouts 1.3

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: searchPage
    objectName: "SearchPage"

    property int searchInType: 0
    property bool showBusy: false
    property string searchString: ""

    property int currentIndex: -1

    property var searchTargets: [qsTr("Albums"), qsTr("Artists"), qsTr("Playlists"), qsTr("Tracks")]
    property var scMap: []


    ListModel {
        id: searchModel
    }

    function reloadSearchHistoryModel() {
        searchHistoryModel.clear()
        //console.log("reloadSearchHistoryModel: " + app.settings.searchHistory)
        var data = JSON.parse(app.settings.searchHistory)
        for(var i=0;i<data.length;i++) 
            searchHistoryModel.append({query: data[i]})
    }

    ListModel {
        id: searchHistoryModel
        Component.onCompleted: reloadSearchHistoryModel()
    }

    header: PageHeader {
        id: pHeader
        title: i18n.tr("Search") + " (" + searchModel.count + "/" + cursorHelper.total + ")"
        flickable: listView
        trailingActionBar.actions: [
            Action {
                iconName: "view-list-symbolic"
                text: i18n.tr("Queries Maintenance")
                onTriggered: {
                    pageStack.push(Qt.resolvedUrl("../components/SearchQueryMaintenance.qml"),
                                      { label: i18n.tr("Queries Maintenance")} )

                    reloadSearchHistoryModel()
                }
            }
        ]
    }

    SearchResultContextMenu {
        id: contextMenu
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height 

        header: Component {
            Column {
                width: parent.width - 2*app.paddingMedium
                x: app.paddingMedium
                spacing: app.paddingMedium 
                Row {
                    width: parent.width
                    spacing: app.paddingMedium
                    height: childrenRect.height 
                    /*Label { 
                        id: tlabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.tr("Search") 
                    }*/
                    QtQc.ComboBox {
                        id: searchCombo
                        width: parent.width //- parent.spacing - tlabel.width 
                        height: pHeader.height * 0.9
                        indicator.width: height
                        background: Rectangle {
                            color: app.normalBackgroundColor
                            border.width: 1
                            border.color: "grey"
                            radius: 7
                        }
                        delegate: QtQc.ItemDelegate {
                            width: searchCombo.width
                            height: searchCombo.height
                            text: modelData
                        }
                        editable: true
                        model: searchHistoryModel
                        onAccepted: {
                            searchString = editText.toLowerCase().trim()
                            refresh()
                            app.settings.searchHistory = 
                                updateSearchHistory(
                                    editText,
                                    app.settings.searchHistory,
                                    app.settings.searchHistoryMaxSize)                         
                            reloadSearchHistoryModel()
                        }
                        onActivated: {
                            var selectedText = model.get(index).query
                            editText = selectedText
                            accepted()
                            editText = selectedText // why is this needed?
                        }
                        function insert(txt) {
                            /*var newContent
                            var newIndex
                            if(cursorIndex == -1) {
                                newContent = editText + " " + txt
                                newIndex = newContent.length
                            } else {
                                newContent = editText.substr(0, cursorIndex)
                                newContent += " " + txt
                                newIndex = newContent.length
                                var rest = editText.substr(cursorIndex)
                                if(rest.length > 0)
                                    newContent += " " + rest
                            }
                            editText = newContent
                            cursorIndex = newIndex
                            */
                            editText = editText + " " + txt
                            focus = true
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: app.paddingMedium
                    height: childrenRect.height
                    QtQc.ComboBox {
                        id: filterCombo
                        width: parent.width - 2*parent.spacing - notButton.width - orButton.width
                        height: pHeader.height * 0.9
                        indicator.width: height
                        displayText: i18n.tr("Add Filter")
                        background: Rectangle {
                            color: app.normalBackgroundColor
                            border.width: 1
                            border.color: "grey"
                            radius: 7
                        }
                        delegate: QtQc.ItemDelegate {
                            width: filterCombo.width
                            height: filterCombo.height
                            text: modelData
                        }
                        model: [ 
                            i18n.tr("album:"), 
                            i18n.tr("artist:"), 
                            i18n.tr("genre:"), 
                            i18n.tr("track:"), 
                            i18n.tr("year:") 
                        ]
                        onActivated: {
                          searchCombo.insert(model[index])
                        }
                        Component.onCompleted: currentIndex = app.settings.currentItemClassSearch
                    }
                    Button {
                        id: notButton
                        height: pHeader.height * 0.9
                        width: units.gu(7)
                        color: app.normalBackgroundColor
                        text: "NOT"
                        onClicked: {
                          searchCombo.insert("NOT")
                        }
                    }
                    Button {
                        id: orButton
                        height: pHeader.height * 0.9
                        width: units.gu(7)
                        color: app.normalBackgroundColor
                        text: "OR"
                        onClicked: {
                          searchCombo.insert("OR")
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: app.paddingMedium
                    height: childrenRect.height 
                    Label { 
                        id: label
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n.tr("In") 
                    }
                    QtQc.ComboBox {
                        id: itemClassCombo
                        width: parent.width - label.width - parent.spacing
                        height: pHeader.height * 0.9
                        indicator.width: height
                        background: Rectangle {
                            color: app.normalBackgroundColor
                            border.width: 1
                            border.color: "grey"
                            radius: 7
                        }
                        delegate: QtQc.ItemDelegate {
                            width: itemClassCombo.width
                            height: itemClassCombo.height
                            text: modelData
                        }
                        model: [ 
                            i18n.tr("Albums"), 
                            i18n.tr("Artists"), 
                            i18n.tr("Playlists"), 
                            i18n.tr("Tracks"), 
                            i18n.tr("Episodes"), 
                            i18n.tr("Shows"), 
                        ]
                        onActivated: {
                          setItemClass(index)
                          refresh()
                        }
                        Component.onCompleted: currentIndex = app.settings.currentItemClassSearch
                    }
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
            //height: searchResultListItem.height

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
                onToggleFavorite: app.handleToggleFavorite(model)
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
            if(listView.atYEnd && searchModel.count > 0) {
                if(searchString === "")
                    return
                if(_itemClass === -1)
                    nextItemClass()
                append()
            }
        }
    }

    Scrollbar {
      id: scrollBar
      flickableItem: listView
      anchors.right: parent.right
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    // 0: Albums, 1: Artists, 2: Playlists, 3: Tracks
    property int _itemClass: app.settings.currentItemClassSearch

    function setItemClass(newIC) {
        _itemClass = newIC
        app.settings.currentItemClassSearch = newIC
    }

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 3)
            i = 0
        _itemClass = i
        app.settings.currentItemClassSearch = i
    }

    function refresh() {
        if(searchString === "")
            return
        if(_itemClass === -1)
            nextItemClass()
        showBusy = true
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
        var types = []
        if(_itemClass === 0)
            types.push('album')
        else if(_itemClass === 1)
            types.push('artist')
        else if(_itemClass === 2)
            types.push('playlist')
        else if(_itemClass === 3)
            types.push('track')
        else if(_itemClass === 4)
            types.push('episode')
        else if(_itemClass === 5)
            types.push('show')

        var options = {offset: searchModel.count, limit: cursorHelper.limit}
        if(app.settings.queryForMarket)
            options.market = "from_token"
        Spotify.search(processSearchString(searchString), types, options, function(error, data) {
            if(data) {
                var artistIds = []
                try {
                    // albums
                    if(data.hasOwnProperty('albums')) {
                        for(i=0;i<data.albums.items.length;i++) {
                            searchModel.append({type: 0,
                                                name: data.albums.items[i].name,
                                                item: data.albums.items[i],
                                                following: false,
                                                saved: app.spotifyDataCache.isAlbumSaved(data.albums.items[i].id)})
                        }
                        cursorHelper.offset = data.albums.offset
                        cursorHelper.total = data.albums.total
                    }

                    // artists
                    if(data.hasOwnProperty('artists')) {
                        for(i=0;i<data.artists.items.length;i++) {
                            searchModel.append({type: 1,
                                                name: data.artists.items[i].name,
                                                item: data.artists.items[i],
                                                following: app.spotifyDataCache.isArtistFollowed(data.artists.items[i].id),
                                                saved: false})
                            artistIds.push(data.artists.items[i].id)
                        }
                        cursorHelper.offset = data.artists.offset
                        cursorHelper.total = data.artists.total
                    }

                    // playlists
                    if(data.hasOwnProperty('playlists')) {
                        for(i=0;i<data.playlists.items.length;i++) {
                            searchModel.append({type: 2,
                                                name: data.playlists.items[i].name,
                                                item: data.playlists.items[i],
                                                following: app.spotifyDataCache.isPlaylistFollowed(data.playlists.items[i].id),
                                                saved: false})
                        }
                        cursorHelper.offset = data.playlists.offset
                        cursorHelper.total = data.playlists.total
                    }

                    // tracks
                    if(data.hasOwnProperty('tracks')) {
                        cursorHelper.offset = data.tracks.offset
                        cursorHelper.total = data.tracks.total
                        app.loadTracksInModel(data, data.tracks.items.length, searchModel, function(data, i) {return data.tracks.items[i]})
                    }

                    // episodes
                    if(data.hasOwnProperty('episodes')) {
                        cursorHelper.offset = data.episodes.offset
                        cursorHelper.total = data.episodes.total
                        for(i=0;i<data.episodes.items.length;i++) {
                            searchModel.append({type: 4,
                                                name: data.episodes.items[i].name,
                                                item: data.episodes.items[i],
                                                following: false,
                                                saved: false})
                        }
                    }

                    // shows
                    if(data.hasOwnProperty('shows')) {
                        cursorHelper.offset = data.shows.offset
                        cursorHelper.total = data.shows.total
                        for(i=0;i<data.shows.items.length;i++) {
                            searchModel.append({type: 5,
                                                name: data.shows.items[i].name,
                                                item: data.shows.items[i],
                                                following: false,
                                                saved: false})
                        }
                    }

                } catch (err) {
                    console.log("Search.refresh exception: " + err)
                }
            } else {
                console.log("Search for: " + searchString + " returned no results.")
            }
            // unfortunately Spotify does not return an error when it has an invalid query
            if(error)
                app.showErrorMessage(error, qsTr("Search Failed"))
            showBusy = false
            _loading = false
        })
    }

    function processSearchString(searchString) {
        // if no wildcard present and no dash and no quote
        // and no field filter
        // we add a wildcard at the end
        var canAdd = true
        var symbols = "*-'\""
        for(var i=0;i<symbols.length;i++) {
            var pos = searchString.indexOf(symbols[i])
            if(pos >= 0) {
                canAdd = false
                break
            }
        }
        if(searchString.indexOf("album:") > -1)
            canAdd = false
        if(searchString.indexOf("artist:") > -1)
            canAdd = false
        if(searchString.indexOf("genre:") > -1)
            canAdd = false
        if(searchString.indexOf("track:") > -1)
            canAdd = false
        if(searchString.indexOf("year:") > -1)
            canAdd = false

        if(canAdd)
            searchString = searchString + '*'
        return searchString
    }

    function updateSearchHistory(searchString, search_history, maxSize) {
        if(!searchString || searchString.length === 0)
            return

        var sh = JSON.parse(search_history)
        var pos = sh.indexOf(searchString)
        console.log("updateSearchHistory " + searchString + ": maxSize=" + maxSize + ", pos=" + pos)
        if(pos > -1) {
            // already in the list so reorder
            for(var i=pos;i>0;i--)
                sh[i] = sh[i-1]
            sh[0] = searchString
        } else
            // a new item so insert at first position
            sh.unshift(searchString)

        while(sh.length > maxSize)
            sh.pop()

        return JSON.stringify(sh)
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Artist:
            case Util.SpotifyItemType.Playlist:
                Util.setSavedInfo(event.type, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
    }

}
