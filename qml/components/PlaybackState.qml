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
        canPause: item.id != -1
        canPlay: item.id != -1
        canGoNext: true
        canGoPrevious: true
        canSeek: item.id != -1

        onPauseRequested: app.controller.playPause()
        onPlayRequested: app.controller.play()
        onPlayPauseRequested: app.controller.playPause()
        onNextRequested: app.controller.next()
        onPreviousRequested: app.controller.previous()
        onSeekRequested: app.controller.seek(offset/1000)
    }

    onItemChanged: {
        artistsString = Util.createItemsString(item.artists, qsTr("no artist known"))
        if (item.album && item.album.images && item.album.images.length > 0)
            coverArtUrl = item.album.images[0].url;
        else coverArtUrl = "";

        // Album, ArtUrl, Artist, AlbumArtist, Composer, Length, TrackNumber, Title
        var metadata = {}
        metadata[Mpris.metadataToString(Mpris.Title)] = item.name
        metadata[Mpris.metadataToString(Mpris.Artist)] = artistsString
        metadata[Mpris.metadataToString(Mpris.ArtUrl)] = coverArtUrl
        metadata[Mpris.metadataToString(Mpris.Length)] = item.duration_ms * 1000
        metadata[Mpris.metadataToString(Mpris.Album)] = item.album.name
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

    function nextRepeatState() {
        if (repeat_state === "off")
            return "context"
        else if (repeat_state === "context")
            return "track";
        return "off";
    }

    function importState(state) {
        //console.log("importState: " + JSON.stringify(state.device))
        device = state.device;
        repeat_state = state.repeat_state;
        shuffle_state = state.shuffle_state;
        context = state.context;
        timestamp = state.timestamp;
        progress_ms = state.progress_ms;
        is_playing = state.is_playing;
        item = state.item;
    }
}
