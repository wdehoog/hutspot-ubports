/**
 * Copyright (C) 2021 Willem-Jan de Hoog
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

    property bool showBusy: false

    property string pageHeaderText: i18n.tr("Playing")
    property string pageHeaderDescription: ""

    property bool isContextFavorite: false

    property string currentId: ""
    property string currentSnapshotId: ""
    property string currentTrackId: ""

    property bool showTrackInfo: true
    property int contextType: -1

    property int currentIndex: -1

    property bool _debug: true

    property var playbackState: app.controller.playbackState

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        title: pageHeaderText
        subtitle: pageHeaderDescription
        leadingActionBar.actions: [
            Action { // copied from PageHeader
                iconName: Qt.application.layoutDirection == Qt.RightToLeft ? "next": "back"
                text: i18n.tr("Back")
                onTriggered: {
                    app._playingPageOnPageStack = false
                    pageStack.pop()
                }
            }
        ]
        flickable: listView
    }

    //
    // Context Menu
    //

    property bool _viewAlbumEnabled: false
    property bool _viewArtistEnabled: false
    property bool _viewPlaylistEnabled: false
    property bool _viewRefreshPlaylistEnabled: false
    property bool _viewShowEnabled: false
    //property bool viewTrackEnabled: false

    function updateContextMenu() {
        _viewAlbumEnabled = false
        _viewArtistEnabled = false
        _viewPlaylistEnabled = false
        _viewRefreshPlaylistEnabled = false
        _viewShowEnabled = false
        //viewTrackEnabled = false

        switch(getContextType()) {
        case Spotify.ItemType.Album:
            _viewAlbumEnabled= true
            _viewArtistEnabled = true
            break
        case Spotify.ItemType.Artist:
            _viewArtistEnabled = true
            break
        case Spotify.ItemType.Playlist:
            _viewPlaylistEnabled = true
            if(app.getRecommendationSetForPlaylist(currentId) >= 0)
                _viewRefreshPlaylistEnabled = true
            break
        case Spotify.ItemType.Show:
            _viewShowEnabled = true
            break
        case Spotify.ItemType.Track:
            _viewAlbumEnabled = true
            _viewArtistEnabled = false
            break
        }
    }

    Component {
        id: contextMenu

        ContextMenuPopover {

            actions: ActionList {
                Action {
                    id: a
                    property int idx: enabled ? 0 : -1
                    text: i18n.tr("View Album")
                    visible: enabled
                    enabled: _viewAlbumEnabled
                    onTriggered: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.loadAlbum(playbackState.context, true)
                            break
                        case Spotify.ItemType.Track:
                            app.loadAlbum(playbackState.item.album, true)
                            break
                        }
                    }
                }
                Action {
                    id: b
                    property int idx: enabled ? (a.idx + 1) : a.idx
                    text: i18n.tr("View Artist")
                    visible: enabled
                    enabled: _viewArtistEnabled
                    onTriggered: {
                        switch(getContextType()) {
                        case Spotify.ItemType.Album:
                            app.loadArtist(playbackState.context.artists, true)
                            break
                        case Spotify.ItemType.Artist:
                            app.pushPage(Util.HutspotPage.Artist, {currentArtist: playbackState.context}, true)
                            break
                        case Spotify.ItemType.Track:
                            app.loadArtist(playbackState.item.artists, true)
                            break
                        }
                    }
                }
                Action {
                    id: c
                    property int idx: enabled ? (b.idx + 1) : b.idx
                    text: i18n.tr("View Playlist")
                    visible: enabled
                    enabled: _viewPlaylistEnabled
                    onTriggered: {
                        app.pushPage(Util.HutspotPage.Playlist, {playlist: playbackState.context}, true)
                    }
                }
                Action {
                    id: d
                    property int idx: enabled ? (c.idx + 1) : c.idx
                    text: i18n.tr("Refresh Recommended Tracks")
                    visible: enabled
                    enabled: _viewRefreshPlaylistEnabled
                    onTriggered: refreshRecommendedTracks()
                }
                Action {
                    id: e
                    property int idx: enabled ? (d.idx + 1) : d.idx
                    text: i18n.tr("View Show")
                    visible: enabled
                    enabled: _viewShowEnabled
                    onTriggered: {
                        app.pushPage(Util.HutspotPage.Show, {show: playbackState.context}, true)
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

    SearchResultContextMenu {
        id: searchResultContextMenu
    }

    AlbumTrackContextMenu {
        id: albumTrackContextMenu
        property var model: null
        property var context
        //property bool enableQueueItems: true
        property bool fromPlaying: true
    }

    //
    // ListView
    //

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
                    source:  app.controller.getCoverArt(app.defaultCoverImageSource, showTrackInfo)
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

            Rectangle {
                width: parent.width
                height: app.paddingMedium
                opacity: 0
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

                    onContextMenuRequested: openMenu()

                    function openMenu() {
                        updateContextMenu()
                        PopupUtils.open(contextMenu, info)
                    }
                }
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

            onPressAndHold: {
                //console.log("contextType: " + contextType + " => " + JSON.stringify(playbackState.context))
                if(contextType > 0) {
                    searchResultContextMenu.open(model, listItem)
                } else {
                    albumTrackContextMenu.model = model
                    albumTrackContextMenu.context = playbackState.context
                    PopupUtils.open(albumTrackContextMenu, listItem)
                }
            }

            Connections {
                target: loader.item
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            // play track
            onClicked: app.controller.playTrackInContext(item, playbackState.context, index)
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0) {
                // album is already completely loaded
                if(playbackState.context
                   && playbackState.context.type === 'playlist')
                    appendPlaylistTracks(app.id, currentId, false)
            }
        }
    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    //
    // Control Panel
    //

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
                Label {
                    id: progressLabel
                    //font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Util.getDurationString(playbackState.progress_ms)
                }
                Slider {
                    id: progressSlider
                    //height: progressLabel.height * 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - durationLabel.width - progressLabel.width
                    minimumValue: 0
                    maximumValue: playbackState.item
                                  ? playbackState.item.duration_ms
                                  : ""
                    onPressedChanged: {
                        if(pressed) // only act on release
                            return
                        app.controller.seek(value)
                    }
                    Connections {
                        target: playbackState
                        onProgress_msChanged: progressSlider.value = playbackState.progress_ms
                    }
                }
                Label {
                    id: durationLabel
                    //font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: playbackState.item
                          ? Util.getDurationString(playbackState.item.duration_ms)
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
                    //color: playbackState.shuffle_state
                    //       ? theme.palette.normal.focus : theme.palette.normal.foregroundText
                    opacity: playbackState.shuffle_state ? 1 : .4
                    enabled: playbackState.canShuffle
                    color: app.bgColor
                    action: Action {
                        iconName: "media-playlist-shuffle"
                        onTriggered: app.controller.setShuffle(!playbackState.shuffle_state)
                    }
                }

                Button {
                    width: buttonRow.itemWidth
                    color: app.bgColor
                    enabled: playbackState.canGoPrevious
                    action: Action {
                        iconName: "media-skip-backward"
                        onTriggered: app.controller.previous()
                    }
                }
                Button {
                    width: buttonRow.itemWidth
                    color: app.bgColor
                    enabled: playbackState.canPlay
                             || playbackState.canPause
                    action: Action {
                        iconName: playbackState.is_playing
                                 ? "media-playback-pause"
                                 : "media-playback-start"
                        onTriggered: app.controller.playPause()
                    }
                }
                Button {
                    width: buttonRow.itemWidth
                    color: app.bgColor
                    enabled: playbackState.canGoNext
                    action: Action {
                        iconName: "media-skip-forward"
                        onTriggered: app.controller.next()
                    }
                }
                Button {
                    width: buttonRow.itemWidth
                    color: app.bgColor
                    enabled: playbackState.canRepeat
                    action: Action {
                        iconSource: playbackState.repeat_state == "context"
                                    ? Qt.resolvedUrl("../resources/media-playlist-repeat-all.svg")
                                    : (playbackState.repeat_state == "track"
                                       ? "image://theme/media-playlist-repeat-one"
                                       : "image://theme/media-playlist-repeat")
                        onTriggered: app.controller.setRepeat(app.controller.nextRepeatState())
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
                    onClicked: pageStack.push(Qt.resolvedUrl("Devices.qml"),
                                              {fromPlaying: true})
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

                    Label {
                        id: spotifyConnectLabel
                        text: app.controller.hasCurrentDevice ? "Listening on <b>" + playbackState.device.name + "</b>" : i18n.tr("no current device")
                    }
                }
            }
        }
    } // Control Panel

    function getFirstLabelText() {
        var s = ""
        if(playbackState === undefined)
             return s
        if(!playbackState.context || showTrackInfo)
            return playbackState.item ? playbackState.item.name : ""
        if(playbackState.context === null)
            return s
        return playbackState.context.name
    }

    function getSecondLabelText() {
        var s = ""
        if(playbackState === undefined)
             return s
        if(!playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(playbackState.item && playbackState.item.album) {
                s += playbackState.item.album.name
                if (playbackState.item.album.release_date)
                    s += ", " + Util.getYearFromReleaseDate(playbackState.item.album.release_date)
            } else if(playbackState.item && playbackState.item.show) {
                s += playbackState.item.show.name
                //if (playbackState.item.show.copyrights)
                //    s += ", " + playbackState.item.show.copyrights
            }
            return s
        }
        if(playbackState.context === null)
            return s
        var context = playbackState.context
        switch(context.type) {
        case 'album':
            s += Util.createItemsString(context.artists, i18n.tr("no artist known"))
            break
        case 'artist':
            s += Util.createItemsString(context.genres, i18n.tr("no genre known"))
            break
        case 'playlist':
        case 'show':
            s+= context.description
            break
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(playbackState === undefined)
             return s
        if(!playbackState.context || showTrackInfo) {
            // no context (a single track?)
            if(playbackState.item && playbackState.item.artists)
                s += Util.createItemsString(playbackState.item.artists, i18n.tr("no artist known"))
            else if(playbackState.item && playbackState.item.show)
                s += playbackState.item.show.publisher
            return s
        }
        if(!playbackState.context)
            return
        var context = playbackState.context
        switch(context.type) {
        case 'album':
            if(context.tracks)
                s += context.tracks.total + " " + i18n.tr("tracks")
            else if(context.album_type === "single")
                s += "1 " + i18n.tr("track")
            if (context.release_date)
                s += ", " + Util.getYearFromReleaseDate(context.release_date)
            if(context.genres && context.genres.lenght > 0)
                s += ", " + Util.createItemsString(context.genres, "")
            break
        case 'artist':
            if(context.followers && context.followers.total > 0)
                s += Util.abbreviateNumber(context.followers.total) + " " + i18n.tr("followers")
            break
        case 'playlist':
            s += context.tracks.total + " " + i18n.tr("tracks")
            s += ", " + i18n.tr("by") + " " + context.owner.display_name
            if(context.followers && context.followers.total > 0)
                s += ", " + Util.abbreviateNumber(context.followers.total) + " " + i18n.tr("followers")
            if(context["public"])
                s += ", " +  i18n.tr("public")
            if(context.collaborative)
                s += ", " +  i18n.tr("collaborative")
            break
        case 'show':
            if(context.total_episodes)
                s += context.total_episodes + " " + i18n.tr("episodes")
            s += ", " + i18n.tr("by") + " " + context.publisher
            if(context.explicit)
                s += ", " +  i18n.tr("explicit")
            s += ", " + Util.createItemsString(context.languages, "")
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
        if(!playbackState || !playbackState.item)
            return -1

        if (playbackState.context)
            switch(playbackState.context.type) {
            case 'album':
                return Spotify.ItemType.Album
            case 'artist':
                return Spotify.ItemType.Artist
            case 'playlist':
                return Spotify.ItemType.Playlist
            case 'show':
                return Spotify.ItemType.Show
            }
        return Spotify.ItemType.Track
    }

    function updateForCurrentAlbumTrack() {
        console.log("updateForCurrentTrack " + searchModel.count + ", " + currentTrackId)
        // to keep current track visible

        // if currentTrackId is not set take it from playback state
        if(!currentTrackId)
            currentTrackId = playbackState.item.id

        currentIndex = -1
        for(var i=0;i<searchModel.count;i++) {
            var track = searchModel.get(i).item
            //console.log(JSON.stringify(track))
            if(track.id === currentTrackId
               || (track.linked_from && track.linked_from.id === currentTrackId)) {
                currentIndex = i
                positionViewForCurrentIndex()
                break
            }
        }
    }

    function updateForCurrentTrack() {
        var context = playbackState.context
        if(context) {
            if(_debug)console.log("updateForCurrentTrack: context=" + context.type)
            switch(context.type) {
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
                console.log("updateForCurrentTrack() with unhandled context: " + context.type)
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

        // if currentTrackId is not set take it from playback state
        if(!currentTrackId)
            currentTrackId = playbackState.item.id

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
        if (playbackState.context) {
            switch (playbackState.context.type) {
                case 'album':
                    contextType = Util.SpotifyItemType.Album
                    loadAlbumTracks(currentId)
                    break
                case 'artist':
                    contextType = Util.SpotifyItemType.Artist
                    showTrackInfo = false
                    isContextFavorite = app.spotifyDataCache.isArtistFollowed(currentId)
                    break
                case 'playlist':
                    contextType = Util.SpotifyItemType.Playlist
                    //cursorHelper.offset = 0
                    loadPlaylistTracks(app.id, currentId)
                    loadPlaylistTrackInfo()
                    break
                case 'show':
                    contextType = Util.SpotifyItemType.Show
                    break;
                default:
                    contextType = -1
                    break
            }
        } else
          contextType = -1
    }

    // try to detect end of playlist play
    property bool _isPlaying: false
    Connections {
        target: playbackState

        onContextChanged: {
            if(_debug)console.log("Playing.onContextChanged: " + currentId)
            if(playbackState.context) {
                currentId = playbackState.context.id
                currentSnapshotId = playbackState.context.snapshot_id
            } else {
                currentId = ""
                currentSnapshotId = ""
            }
        }

        onItemChanged: {
            if(_debug)console.log("Playing.onItemChanged  currentId: " +currentId + ", currentTrackId: " + currentTrackId + ", currentIndex: " + currentIndex)

            // do we have an id?
            if(currentId == "" && playbackState.context)
                currentId = playbackState.context.id

            if(currentTrackId === playbackState.item.id) {
                if(currentIndex === -1) // we can still have missed it
                    updateForCurrentTrack()
                return
            }

            currentTrackId = playbackState.item.id
            updateForCurrentTrack()

            if(playbackState.context) {
                switch (playbackState.context.type) {
                    case 'album':
                        pageHeaderDescription = playbackState.item.album.name
                        break
                    case 'artist':
                        pageHeaderDescription = playbackState.artistsString
                        break
                    case 'playlist':
                    case 'show':
                        if(playbackState.context)
                            pageHeaderDescription = playbackState.context.name
                        break
                    default:
                        pageHeaderDescription = ""
                        console.log("onItemChanged unknown context: " + playbackState.context.type)
                        break
                }
            } else {
                // no context (a single track?)
                currentId = playbackState.item.id
                //console.log("  no context: " + currentId)
                pageHeaderDescription = ""
            }
        }

        onIs_playingChanged: {
            if(_debug)console.log("Playing.onIs_playingChanged currentIndex: " + currentIndex)
            if(!_isPlaying && playbackState.is_playing) {
                if(currentIndex === -1)
                    updateForCurrentTrack()
                //console.log("Started Playing")
            } else if(_isPlaying && !playbackState.is_playing) {
                //console.log("Stopped Playing")
                pluOnStopped()
            }

            _isPlaying = playbackState.is_playing
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
        if(_debug)console.log("appendPlaylistTracks id: %1, pid: %2, onInit: %3".arg(id).arg(pid).arg(onInit))
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
        isContextFavorite = app.spotifyDataCache.isPlaylistFollowed(pid)
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
        isContextFavorite = app.spotifyDataCache.isAlbumSaved(id)
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
        if(!playbackState.context
           || !playbackState.context)
            return
        switch(playbackState.context.type) {
        case 'album':
            app.toggleSavedAlbum(playbackState.context, isContextFavorite, function(saved) {
                isContextFavorite = saved
            })
            break
        case 'artist':
            app.toggleFollowArtist(playbackState.context, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        case 'playlist':
            app.toggleFollowPlaylist(playbackState.context, isContextFavorite, function(followed) {
                isContextFavorite = followed
            })
            break
        case 'show':
            app.toggleSavedShow(playbackState.context, isContextFavorite, function(saved) {
                isContextFavorite = saved
            })
            break
        default: // track?
            if (playbackState.item) { // Note uses globals
                if(isContextFavorite)
                    app.unSaveTrack(playbackState.item, function(error,data) {
                        if(!error)
                            isContextFavorite = false
                    })
                else
                    app.saveTrack(playbackState.item, function(error,data) {
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
                app.controller.playContext({type: 'playlist', uri: waitForEndSnapshotData.uri},
                            {offset: {uri: waitForEndSnapshotData.trackUri}})
            }
        }
    }

    Connections {
        target: app

        onPlaylistEvent: {
            if(_debug)console.log("onPlaylistEvent " + event.playlistId)
            if(getContextType() !== Spotify.ItemType.Playlist
               || playbackState.context.id !== event.playlistId)
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
                if(playbackState.is_playing) {
                    waitForEndOfSnapshot = true
                    waitForEndSnapshotData.uri = event.uri
                    waitForEndSnapshotData.href = event.uri
                    waitForEndSnapshotData.snapshotId = event.snapshotId
                    waitForEndSnapshotData.index = playbackState.context.tracks.total // not used
                    waitForEndSnapshotData.trackUri = event.trackUri
                } else {
                    //currentSnapshotId = event.snapshotId
                    loadPlaylistTracks(app.id, currentId)
                }
                break
            case Util.PlaylistEventType.RemovedTrack:
                //Util.removeFromListModel(searchModel, Spotify.ItemType.Track, event.trackId)
                //currentSnapshotId = event.snapshotId
                break
            case Util.PlaylistEventType.ReplacedAllTracks:
                if(playbackState.is_playing) {
                    var href = playbackState.context.href
                    app.controller.pause(function(error, data) {
                        app.controller.playContext({type: 'playlist', href: href})
                    })
                } else {
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

    RecommendationData {
        id: tempRD
    }

    function refreshRecommendedTracks() {
        var name = playbackState.context.name
        app.showConfirmDialog(
            i18n.tr("Do you want to refresh the tracks of %1?").arg(name), function(info) {
            var rsi = app.getRecommendationSetForPlaylist(currentId)
            tempRD.loadData(app.recommendationSets[rsi])
            app.updatePlaylistFromRecommendations(tempRD)
        })
    }

    Component.onCompleted: {
        // do we have an id?
        if(currentId == ""
           && playbackState
           && playbackState.context) {
            currentId = playbackState.context.id
            currentSnapshotId = playbackState.context.snapshot_id
                                ? playbackState.context.snapshot_id : ""
        }
    }
}
