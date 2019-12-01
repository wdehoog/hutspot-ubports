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

import QtQuick 2.2

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: playingPage
    objectName: "PlayingPage"

    property string defaultImageSource : "image://theme/stock_music"
    property bool showBusy: false
    property string pageHeaderText: i18n.tr("Playing")
    property string pageHeaderDescription: ""

    property bool isContextFavorite: false

    property string currentId: ""
    property string currentSnapshotId: ""
    property string currentTrackId: ""

    property string viewMenuText: ""
    property bool showTrackInfo: true
    property int contextType: 0

    property int currentIndex: -1

    property int mutedVolume: -1
    property bool muted: false

    property bool _debug: false

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        title: i18n.tr("Playing") 
        flickable: listView
    }

    Component {
        id: contextMenu

        ActionSelectionPopover {

            actions: ActionList {
                Action {
                    id: viewAlbum
                    text: i18n.tr("View Album")
                    visible: enabled
                    onTriggered: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.context}, true)
                            break
                        case Spotify.ItemType.Track:
                            app.pushPage(Util.HutspotPage.Album, {album: app.controller.playbackState.item.album}, true)
                            break
                        }
                    }
                }
                Action {
                    id: viewArtist
                    text: i18n.tr("View Artist")
                    visible: enabled
                    onTriggered: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.loadArtist(app.controller.playbackState.contextDetails.artists, true)
                            break
                        case Spotify.ItemType.Artist:
                            app.pushPage(Util.HutspotPage.Artist, {currentArtist: app.controller.playbackState.contextDetails}, true)
                            break
                        case Spotify.ItemType.Track:
                            app.loadArtist(app.controller.playbackState.item.artists, true)
                            break
                        }
                    }
                }
                Action {
                    id: viewPlaylist
                    text: i18n.tr("View Playlist")
                    visible: enabled
                    onTriggered: {
                        app.pushPage(Util.HutspotPage.Playlist, {playlist: app.controller.playbackState.context}, true)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: app.popupBackgroundColor
                opacity: app.popupBackgroundOpacity
                radius: app.popupRadius
                z: -1
            }
        }
    }


    ListView {
        id: listView
        model: searchModel
        //anchors.fill: parent
        width: parent.width
        height: parent.height - controlPanel.height
        clip: true

        header: Component { Column {
            id: lvColumn

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            anchors.bottomMargin: app.paddingLarge

            Item {
                width: parent.width
                height: imageItem.height

                Image {
                    id: imageItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.75
                    height: sourceSize.height*(width/sourceSize.width)
                    source:  app.controller.getCoverArt(defaultImageSource, showTrackInfo)
                    fillMode: Image.PreserveAspectFit
                    onPaintedHeightChanged: parent.height = Math.min(parent.parent.width, paintedHeight)
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            showTrackInfo = !showTrackInfo
                            //app.glassyBackground.showTrackInfo = showTrackInfo
                        }
                    }
                }
                /*DropShadow {
                    anchors.fill: imageItem
                    radius: 3.0
                    samples: 10
                    color: "#000"
                    source: imageItem
                }*/
            }

            Item {
                id: infoContainer

                // put MetaInfoPanel in Item to be able to make room for context menu
                width: parent.width
                height: info.height //+ (cmenu ? cmenu.height : 0)

                MetaInfoPanel {
                    id: info
                    anchors.top: parent.top
                    firstLabelText: getFirstLabelText()
                    secondLabelText: getSecondLabelText()
                    thirdLabelText: getThirdLabelText()

                    isFavorite: isContextFavorite
                    onToggleFavorite: toggleSavedFollowed()
                    onFirstLabelClicked: openMenu()
                    onSecondLabelClicked: openMenu()
                    onThirdLabelClicked: openMenu()

                    function openMenu() {
                        cmenu.update()
                        cmenu.open(infoContainer)
                    }
                }
            }

            /*ContextMenu {
                id: cmenu

                function update() {
                    viewAlbum.enabled = false
                    viewArtist.enabled = false
                    viewPlaylist.enabled = false
                    switch(getContextType()) {
                    case Spotify.ItemType.Album:
                        viewAlbum.enabled = true
                        viewArtist.enabled = true
                        break
                    case Spotify.ItemType.Artist:
                        viewArtist.enabled = true
                        break
                    case Spotify.ItemType.Playlist:
                        viewPlaylist.enabled = true
                        break
                    case Spotify.ItemType.Track:
                        viewAlbum.enabled = true
                        viewArtist.enabled = false
                        break
                    }
                }

            }*/

            /*Text {
                truncationMode: TruncationMode.Fade
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                text:  (app.controller.playbackState && app.controller.playbackState.device)
                        ? i18n.tr("on: ") + app.controller.playbackState.device.name + " (" + app.controller.playbackState.device.type + ")"
                        : i18n.tr("none")
            }*/

            Rectangle {
                width: parent.width
                height: app.paddingMedium
                opacity: 0
            }

            /*Separator {
                width: parent.width
                color: Theme.primaryColor
            }*/

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

            Loader {
                id: loader

                width: parent.width
                height: childrenRect.height
                anchors.verticalCenter: parent.verticalCenter

                source: contextType > 0
                        ? "../components/SearchResultListItem.qml"
                        : "../components/AlbumTrackListItem.qml"

                Binding {
                  target: loader.item
                  property: "dataModel"
                  value: model
                  when: loader.status == Loader.Ready
                }
                Binding {
                    target: loader.item
                    property: "isFavorite"
                    value: saved
                    when: contextType === 0
                }
                Binding {
                  target: loader.item
                  property: "contextType"
                  value: contextType
                  when: loader.status == Loader.Ready
                }
                //onStatusChanged: console.log("Loader: " + loader.status)
            }

            /*menu: AlbumTrackContextMenu {
                context: app.controller.playbackState.context
                enableQueueItems: false
                fromPlaying: true
            }*/

            onPressAndHold: {
                PopupUtils.open(contextMenu, listItem)
            }

            Connections {
                target: loader.item
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            // play track
            onClicked: app.controller.playTrackInContext(item, app.controller.playbackState.context, index)
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0) {
                // album is already completely loaded
                if(app.controller.playbackState.context
                   && app.controller.playbackState.context.type === 'playlist')
                    appendPlaylistTracks(app.id, currentId, false)
            }
        }
    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    //PanelBackground { //
    Item { //for transparant controlpanel
        id: controlPanel
        anchors.bottom: parent.bottom
        width: parent.width
        height: col.height

        Column {
            id: col
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            Row {
                width: parent.width
                Text {
                    id: progressLabel
                    //font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(app.controller.playbackState.progress_ms)
                }
                Slider {
                    id: progressSlider
                    //height: progressLabel.height * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - durationLabel.width - progressLabel.width
                    minimumValue: 0
                    maximumValue: app.controller.playbackState.item
                                  ? app.controller.playbackState.item.duration_ms
                                  : ""
                    onPressedChanged: {
                        if(pressed) // only act on release
                            return
                        app.controller.seek(value)
                    }
                    Connections {
                        target: app.controller.playbackState
                        onProgress_msChanged: progressSlider.value = app.controller.playbackState.progress_ms
                    }
                }
                Text {
                    id: durationLabel
                    //font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: app.controller.playbackState.item
                          ? Util.getDurationString(app.controller.playbackState.item.duration_ms)
                          : ""
                }
            }

            Rectangle {
                width: parent.width
                height: app.paddingSmall
                color: "transparent"
            }

            Row {
                id: buttonRow
                width: parent.width
                property real itemWidth : width / 5

                Button {
                    width: buttonRow.itemWidth
                    color: app.controller.playbackState.shuffle_state ? "#E5E4E2" : "white" 
                    action: Action {
                        iconName: "media-playlist-shuffle"
                        onTriggered: app.controller.setShuffle(!app.controller.playbackState.shuffle_state)
                    }
                }

                Button {
                    width: buttonRow.itemWidth
                    color: "white"
                    //enabled: app.mprisPlayer.canGoPrevious
                    action: Action {
                        iconName: "media-skip-backward"
                        onTriggered: app.controller.previous()
                    }
                }
                Button {
                    width: buttonRow.itemWidth
                    color: "white"
                    action: Action {
                        iconName: app.controller.playbackState.is_playing
                                 ? "media-playback-pause"
                                 : "media-playback-start"
                        onTriggered: app.controller.playPause()
                    }
                }
                Button {
                    width: buttonRow.itemWidth
                    color: "white"
                    //enabled: app.mprisPlayer.canGoNext
                    action: Action {
                        iconName: "media-skip-forward"
                        onTriggered: app.controller.next()
                    }
                }
                Button {
                    /*Rectangle {
                        visible: app.controller.playbackState.repeat_state === "track"
                        color: Theme.highlightColor
                        anchors {
                            rightMargin: (buttonRow.itemWidth - Theme.iconSizeMedium)/2
                            right: parent.right
                            top: parent.top
                        }
                        width: Theme.iconSizeSmall
                        height: width
                        radius: width/2

                        Text {
                            text: "1"
                            anchors.centerIn: parent
                            color: "#000"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                        }
                    }*/

                    width: buttonRow.itemWidth
                    color: app.controller.playbackState.repeat_state == "off" 
                           ? "white" 
                           : (app.controller.playbackState.repeat_state == "track" 
                              ? "#E5E4E2"  
                              : "#BCC6CC") // white/platinum/metallic silver
                    action: Action {
                        iconName: "media-playlist-repeat"
                        onTriggered: app.controller.setRepeat(app.controller.playbackState.nextRepeatState())
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: app.paddingSmall
                color: "transparent"
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: spotifyConnectRow.childrenRect.height + app.paddingSmall*2
                MouseArea {
                    anchors.fill: spotifyConnectRow
                    onClicked: pageStack.push(Qt.resolvedUrl("Devices.qml"))
                }

                Row {
                    id: spotifyConnectRow
                    y: app.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: app.paddingMedium
                    Image {
                        anchors.verticalCenter: spotifyConnectLabel.verticalCenter
                        width: units.gu(2)
                        height: width
                        source: "image://theme/toolkit_arrow-right"
                    }

                    Text {
                        id: spotifyConnectLabel
                        text: app.controller.playbackState.device !== undefined ? "Listening on <b>" + app.controller.playbackState.device.name + "</b>" : ""
                    }
                    visible: app.controller.playbackState.device !== undefined
                }
            }
        }
    } // Control Panel

    function getFirstLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo)
            return app.controller.playbackState.item ? app.controller.playbackState.item.name : ""
        if(app.controller.playbackState.context === null)
            return s
        return app.controller.playbackState.contextDetails.name
    }

    function getSecondLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.album) {
                s += app.controller.playbackState.item.album.name
                if (app.controller.playbackState.item.album.release_date)
                    s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.item.album.release_date)
            }
            return s
        }
        if(app.controller.playbackState.context === null)
            return s
        switch(app.controller.playbackState.context.type) {
        case 'album':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.artists, i18n.tr("no artist known"))
            break
        case 'artist':
            s += Util.createItemsString(app.controller.playbackState.contextDetails.genres, i18n.tr("no genre known"))
            break
        case 'playlist':
            s+= app.controller.playbackState.contextDetails.description
            break
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(app.controller.playbackState === undefined)
             return s
        if(!app.controller.playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(app.controller.playbackState.item && app.controller.playbackState.item.artists)
                s += Util.createItemsString(app.controller.playbackState.item.artists, i18n.tr("no artist known"))
            return s
        }
        if(!app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            if(app.controller.playbackState.contextDetails.tracks)
                s += app.controller.playbackState.contextDetails.tracks.total + " " + i18n.tr("tracks")
            else if(app.controller.playbackState.contextDetails.album_type === "single")
                s += "1 " + i18n.tr("track")
            if (app.controller.playbackState.contextDetails.release_date)
                s += ", " + Util.getYearFromReleaseDate(app.controller.playbackState.contextDetails.release_date)
            if(app.controller.playbackState.contextDetails.genres && app.controller.playbackState.contextDetails.genres.lenght > 0)
                s += ", " + Util.createItemsString(app.controller.playbackState.contextDetails.genres, "")
            break
        case 'artist':
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + i18n.tr("followers")
            break
        case 'playlist':
            s += app.controller.playbackState.contextDetails.tracks.total + " " + i18n.tr("tracks")
            s += ", " + i18n.tr("by") + " " + app.controller.playbackState.contextDetails.owner.display_name
            if(app.controller.playbackState.contextDetails.followers && app.controller.playbackState.contextDetails.followers.total > 0)
                s += ", " + Util.abbreviateNumber(app.controller.playbackState.contextDetails.followers.total) + " " + i18n.tr("followers")
            if(app.controller.playbackState.context["public"])
                s += ", " +  i18n.tr("public")
            if(app.controller.playbackState.contextDetails.collaborative)
                s += ", " +  i18n.tr("collaborative")
            break
        }
        return s
    }

    NumberAnimation { id: scrollAnim; target: listView; property: "contentY"; duration: 500 }

    function positionViewForCurrentIndex() {
        // ListView.Visible: when the current item
        //   is hidden under the control panel it remains hidden.
        scrollAnim.running = false
        var pos = listView.contentY
        var destPos
        listView.positionViewAtIndex(currentIndex, ListView.Center)
        destPos = listView.contentY
        scrollAnim.from = pos
        scrollAnim.to = destPos
        scrollAnim.running = true
    }

    function getContextType() {
        if(!app.controller.playbackState || !app.controller.playbackState.item)
            return -1

        if (app.controller.playbackState.context)
            switch(app.controller.playbackState.context.type) {
            case 'album':
                return Spotify.ItemType.Album
            case 'artist':
                return Spotify.ItemType.Artist
            case 'playlist':
                return Spotify.ItemType.Playlist
            }
        return Spotify.ItemType.Track
    }

    function updateForCurrentAlbumTrack() {
        // keep current track visible
        currentIndex = -1
        for(var i=0;i<searchModel.count;i++) {
            var track = searchModel.get(i).item
            if(track.id === currentTrackId
               || (track.linked_from && track.linked_from.id === currentTrackId)) {
                currentIndex = i
                positionViewForCurrentIndex()
                break
            }
        }
    }

    function updateForCurrentTrack() {
        if (app.controller.playbackState.context) {
            if(_debug)console.log("updateForCurrentTrack: context=" + app.controller.playbackState.context.type)
            switch(app.controller.playbackState.context.type) {
            case 'album':
                updateForCurrentAlbumTrack()
                break
            case 'artist':
                loadCurrentTrack(currentTrackId)
                break
            case 'playlist':
                updateForCurrentPlaylistTrack(true)
                break
            default:
                console.log("updateForCurrentTrack() with unhandled context: " + app.controller.playbackState.context.type)
                break
            }
        } else
            loadCurrentTrack(currentTrackId)
    }

    // to be able to find the current track and load the correct set of tracks
    // we keep a list of all playlist tracks (Id,Uri)
    // (for albums we just load them all)
    property var tracksInfo: []
    property int firstItemOffset: 0
    property int lastItemOffset: 0

    function updateForCurrentPlaylistTrack(onInit) {
        currentIndex = -1
        for(var i=0;i<tracksInfo.length;i++) {
            if(tracksInfo[i].id === currentTrackId
               || tracksInfo[i].linked_from === currentTrackId) {
                // in currently loaded set?
                if(i >= firstItemOffset && i <= lastItemOffset) {
                    currentIndex = i - firstItemOffset
                    if(onInit)
                        positionViewForCurrentIndex()
                } else {
                    // load next set
                    appendPlaylistTracks(app.id, currentId, onInit)
                    currentIndex = -1
                }
                break
            }
        }
    }

    function loadPlaylistTrackInfo() {
        if(tracksInfo.length > 0)
            tracksInfo = []
        _loadPlaylistTrackInfo(0)
    }

    function _loadPlaylistTrackInfo(offset) {
        app.getPlaylistTracks(currentId, {fields: "items(track(id,uri)),offset,total", offset: offset, limit: 100},
            function(error, data) {
                if(data) {
                    for(var i=0;i<data.items.length;i++)
                        tracksInfo[i+offset] =
                            {id: data.items[i].track.id,
                             linked_from: data.items[i].track.linked_from,
                             uri: data.items[i].track.uri}
                    var nextOffset = data.offset+data.items.length
                    if(nextOffset < data.total)
                        _loadPlaylistTrackInfo(nextOffset)
                }
            })
    }

    onCurrentIdChanged: {
        if(_debug)console.log("Playing.onCurrentIdChanged: " + currentId)
        if (app.controller.playbackState.context) {
            switch (app.controller.playbackState.context.type) {
                case 'album':
                    contextType = Util.SpotifyItemType.Album
                    loadAlbumTracks(currentId)
                    break
                case 'artist':
                    contextType = Util.SpotifyItemType.Artist
                    showTrackInfo = false
                    Spotify.isFollowingArtists([currentId], function(error, data) {
                        if(data)
                            isContextFavorite = data[0]
                    })
                    break
                case 'playlist':
                    contextType = Util.SpotifyItemType.Playlist
                    //cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, currentId)
                    loadPlaylistTrackInfo()
                    break
            }
        }
    }

    // try to detect end of playlist play
    property bool _isPlaying: false
    Connections {
        target: app.controller.playbackState

        onContextDetailsChanged: {
            if(_debug)console.log("Playing.onContextDetailsChanged: " + currentId)
            if(app.controller.playbackState.contextDetails)
                currentId = app.controller.playbackState.contextDetails.id
            else
                currentId = ""
        }

        onItemChanged: {
            if(_debug)console.log("Playing.onItemChanged  currentId: " +currentId + ", currentTrackId: " + currentTrackId + ", currentIndex: " + currentIndex)

            // do we have an id?
            if(currentId == "" && app.controller.playbackState.contextDetails)
                currentId = app.controller.playbackState.contextDetails.id
                
            if(currentTrackId === app.controller.playbackState.item.id) {
                if(currentIndex === -1) // we can still miss it
                    updateForCurrentTrack()
                return
            }

            currentTrackId = app.controller.playbackState.item.id
            updateForCurrentTrack()

            if(app.controller.playbackState.context) {
                switch (app.controller.playbackState.context.type) {
                    case 'album':
                        pageHeaderDescription = app.controller.playbackState.item.album.name
                        break
                    case 'artist':
                        pageHeaderDescription = app.controller.playbackState.artistsString
                        break
                    case 'playlist':
                        if(app.controller.playbackState.contextDetails)
                            pageHeaderDescription = app.controller.playbackState.contextDetails.name
                        break
                    default:
                        pageHeaderDescription = ""
                        console.log("onItemChanged unknown context: " + app.controller.playbackState.context.type)
                        break
                }
            } else {
                // no context (a single track?)
                currentId = app.controller.playbackState.item.id
                //console.log("  no context: " + currentId)
                pageHeaderDescription = ""
            }
        }

        onIs_playingChanged: {
            if(_debug)console.log("Playing.onIs_playingChanged ")
            if(!_isPlaying && app.controller.playbackState.is_playing) {
                if(currentIndex === -1)
                    updateForCurrentTrack()
                //console.log("Started Playing")
            } else if(_isPlaying && !app.controller.playbackState.is_playing) {
                //console.log("Stopped Playing")
                pluOnStopped()
            }

            _isPlaying = app.controller.playbackState.is_playing
        }
    }

    function loadPlaylistTracks(id, pid) {
        searchModel.clear()
        firstItemOffset = 0
        lastItemOffset = 0
        appendPlaylistTracks(id, pid, true)
    }

    property bool _loading: false

    function appendPlaylistTracks(id, pid, onInit) {
      if(_debug)console.log("appendPlaylistTracks ")
        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        app.getPlaylistTracks(pid, {offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    app.loadTracksInModel(data, data.items.length, searchModel,
                                          function(data, i) {return data.items[i].track},
                                          function(data, i) {return {"added_at" : data.items[i].added_at}})
                    lastItemOffset = firstItemOffset + searchModel.count - 1
                    //console.log("Appended #PlaylistTracks: " + data.items.length + ", count: " + searchModel.count)
                    updateForCurrentPlaylistTrack(onInit)
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
            _loading = false
        })
        app.isFollowingPlaylist(pid, function(error, data) {
            if(data)
                isContextFavorite = data[0]
        })
    }

    property bool _loadingTrack: false
    function loadCurrentTrack(id) {
        if(_debug)console.log("loadCurrentTrack: [" + id +"] _loadingTrack: " + _loadingTrack)
        if(!id)
            return
        if(_loadingTrack)
            return
        _loadingTrack = true
        searchModel.clear()
        var options = {}
        if(app.queryForMarket)
            options.market = "from_token"
        Spotify.getTrack(id, options, function(error, data) {
            if(data) {
                try {
                    app.loadTracksInModel([data], 1, searchModel,
                                          function(data, i) {return data[i]},
                                          function(data, i) {return {"added_at" : ""}})
                    currentIndex = 0
                    positionViewForCurrentIndex()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getTrack")
            }
            _loadingTrack = false
        })
    }

    function loadAlbumTracks(id) {
        searchModel.clear()
        cursorHelper.offset = 0
        cursorHelper.limit = 50 // for now load as much as possible and hope it is enough
        _loadAlbumTracks(id)
        Spotify.containsMySavedAlbums([id], {}, function(error, data) {
            if(data)
                isContextFavorite = data[0]
        })
    }

    function _loadAlbumTracks(id) {
        // 'market' enables 'track linking'
        var options = {offset: cursorHelper.offset, limit: cursorHelper.limit}
        if(app.queryForMarket)
            options.market = "from_token"
        Spotify.getAlbumTracks(id, options, function(error, data) {
            if(data) {
                try {
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    app.loadTracksInModel(data, data.items.length, searchModel,
                                          function(data, i) {return data.items[i]},
                                          function(data, i) {return {"added_at" : ""}})
                    // if the album has more tracks get more
                    if(cursorHelper.total > searchModel.count) {
                        cursorHelper.offset = searchModel.count
                        _loadAlbumTracks(id)
                    } else
                        updateForCurrentTrack()
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })
    }

    function toggleSavedFollowed() {
        if(!app.controller.playbackState.context
           || !app.controller.playbackState.contextDetails)
            return
        switch(app.controller.playbackState.context.type) {
        case 'album':
            app.toggleSavedAlbum(app.controller.playbackState.contextDetails, isContextFavorite, function(saved) {
                isContextFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(app.controller.playbackState.contextDetails, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(app.controller.playbackState.contextDetails, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        default: // track?
            if (app.controller.playbackState.item) { // Note uses globals
                if(isContextFavorite)
                    app.unSaveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isContextFavorite = false
                    })
                else
                    app.saveTrack(app.controller.playbackState.item, function(error,data) {
                        if(!error)
                            isContextFavorite = true
                    })
            }
            break
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    //
    // Playlist Utilities
    //

    property var waitForEndSnapshotData: ({})
    property bool waitForEndOfSnapshot : false
    function pluOnStopped() {
        if(waitForEndOfSnapshot) {
            waitForEndOfSnapshot = false
            if(waitForEndSnapshotData.snapshotId !== currentSnapshotId) { // only if still needed
                currentId = "" // trigger reload
                app.controller.playContext({uri: waitForEndSnapshotData.uri},
                            {offset: {uri: waitForEndSnapshotData.trackUri}})
            }
        }
    }

    Connections {
        target: app

        onPlaylistEvent: {
            if(getContextType() !== Spotify.ItemType.Playlist
               || app.controller.playbackState.contextDetails.id !== event.playlistId)
                return

            // When a playlist is modified while being played the modifications
            // are ignored, it keeps on playing the snapshot that was started.
            // To try to fix this we:
            //   AddedTrack:
            //      wait for playing to end (last track of original snapshot) and then restart playing
            //   RemovedTrack:
            //      for now nothing
            //   ReplacedAllTracks:
            //      restart playing

            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
                // in theory it has been added at the end of the list
                // so we could load the info and add it to the model but ...                
                if(app.controller.playbackState.is_playing) {
                    waitForEndOfSnapshot = true
                    waitForEndSnapshotData.uri = event.uri
                    waitForEndSnapshotData.snapshotId = event.snapshotId
                    waitForEndSnapshotData.index = app.controller.playbackState.contextDetails.tracks.total // not used
                    waitForEndSnapshotData.trackUri = event.trackUri
                } else {
                    currentSnapshotId = event.snapshotId
                    loadPlaylistTracks(app.id, currentId)
                }
                break
            case Util.PlaylistEventType.RemovedTrack:
                //Util.removeFromListModel(searchModel, Spotify.ItemType.Track, event.trackId)
                //currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.ReplacedAllTracks:
                if(app.controller.playbackState.is_playing)
                    app.controller.pause(function(error, data) {
                        currentId = "" // trigger reload)
                        app.controller.playContext({uri: app.controller.playbackState.contextDetails.uri})
                    })
                else {
                    loadPlaylistTracks(app.id, currentId)
                }
                break
            }
        }
        onFavoriteEvent: {
            if(currentId === event.id) {
                isContextFavorite = event.isFavorite
            } else if(event.type === Util.SpotifyItemType.Track) {
                // no easy way to check if the track is in the model so just update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], searchModel)
            }
        }
    }

    Component.onCompleted: {
        // do we have an id?
        if(currentId == "" 
           && app.controller.playbackState 
           && app.controller.playbackState.contextDetails)
            currentId = app.controller.playbackState.contextDetails.id
    }
}
