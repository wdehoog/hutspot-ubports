/**
 * Hutspot. 
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0

import org.nemomobile.mpris 1.0
import "../Util.js" as Util

Item {   


    MprisPlayer {
        id: mprisPlayer

        // Used by apparmor to check dbus permissions. Use APP_ID_DBUS.      
        serviceName: app.app_id_dbus

        playbackStatus: is_playing ? Mpris.Playing : Mpris.Paused

        // label
        identity: "Hutspot"

        // See for actual desktop file name: /home/phablet/.local/share/applications/
        desktopEntry: app.app_id

        canControl: true

        // ToDo add more checks
        canPause: item && item.id != -1
        canPlay: item && item.id != -1
        canGoNext: true
        canGoPrevious: true
        canSeek: item && item.id != -1

        onPauseRequested: app.controller.playPause()
        onStopRequested: app.controller.pause()
        onPlayRequested: app.controller.play()
        onPlayPauseRequested: app.controller.playPause()
        onNextRequested: app.controller.next()
        onPreviousRequested: app.controller.previous()
        onSeekRequested: app.controller.seek(offset/1000)

        // a trick to wake up and update the mpris metadata.
        // let spotifyd on song change hook do: OpenUri file://wakeup.wav
        supportedUriSchemes: ["file"]
        supportedMimeTypes: ["audio/x-wav", "audio/x-vorbis+ogg"]
        onOpenUriRequested: {
            console.log("onOpenUriRequested: " + url)
            app.controller.refreshPlaybackState()
            // hopefully triggers updateMetaData()
        }
    }

    onItemChanged: updateMetaData()

    function updateMetaData() {
        //console.log("updateMetaData")
        var metadata = {}

        if(item == null) {
            coverArtUrl = "";
            mprisPlayer.metadata = metadata
        }

        //console.log("onItemChanged")
        artistsString = Util.createItemsString(item.artists, qsTr("no artist known"))
        if (item.album && item.album.images && item.album.images.length > 0)
            coverArtUrl = item.album.images[0].url;
        else coverArtUrl = "";

        // Album, ArtUrl, Artist, AlbumArtist, Composer, Length, TrackNumber, Title
        metadata[Mpris.metadataToString(Mpris.Title)] = item.name
        metadata[Mpris.metadataToString(Mpris.Artist)] = artistsString
        metadata[Mpris.metadataToString(Mpris.ArtUrl)] = coverArtUrl
        metadata[Mpris.metadataToString(Mpris.Length)] = item.duration_ms * 1000
        if(item.album && item.album.name)
            metadata[Mpris.metadataToString(Mpris.Album)] = item.album.name
        //console.log("  new metadata: " + JSON.stringify(metadata))
        mprisPlayer.metadata = metadata
    }

    property string artistsString: ""
    property string coverArtUrl: ""

    property var device: {
        "id": "-1",
        "is_active": false,
        "is_private_session": false,
        "is_restricted": false,
        "type": "Nothing",
        "name": "No device",
        "volume_percent": 100
    }
    property string repeat_state: "off"
    property bool shuffle_state: false
    property var context: undefined
    property var contextDetails: undefined
    property int timestamp: 0
    property int progress_ms: 0
    property bool is_playing: false
    property var item: {
        "id": -1,
        "duration_ms": 0,
        "artists": [],
        "name": "",
        "album": {"name": "", "id": -1, "images": []}
    }

    function importState(state) {
        //console.log("importState: " + JSON.stringify(state))
        device = state.device
        repeat_state = state.repeat_state
        shuffle_state = state.shuffle_state
        context = state.context
        timestamp = state.timestamp
        progress_ms = state.progress_ms
        is_playing = state.is_playing
        item = state.item
    }

    function notifyNoState(status) {
        // not playing anymore
        // ToDo: keep the rest of the state or clean all?
        device.is_playing = false
        is_playing = false
        if(status == 200)
            device.id = "-1"
    }
}
