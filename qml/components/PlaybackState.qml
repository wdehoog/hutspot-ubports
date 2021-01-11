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
    id: pbs

    property bool _hasItem: item && item.id != -1

    property bool canPause: is_playing && isAllowed('pausing')
    property bool canPlay: _hasItem && !is_playing && isAllowed('resuming')
    property bool canGoNext: _hasItem && isAllowed('skipping_next')
    property bool canGoPrevious: _hasItem && isAllowed('skipping_prev')
    property bool canSeek: _hasItem && isAllowed('seeking')
    property bool canShuffle: _hasItem && isAllowed('toggling_shuffle')
    property bool canRepeat: _hasItem && (isAllowed('toggling_repeat_track') || isAllowed('toggling_repeat_context'))

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

        canPause: pbs.canPause  // how about || canPlay
        canPlay: pbs.canPlay
        canGoNext: pbs.canGoNext
        canGoPrevious: pbs.canGoPrevious
        canSeek: pbs.canSeek

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
        //console.log("updateMetaData: " + JSON.stringify(item))
        var metadata = {}

        if(item == null) {
            coverArtUrl = ""
            artistsString = ""
            mprisPlayer.metadata = metadata
        } else {
            artistsString = Util.createItemsString(item.artists, qsTr("no artist known"))

            if (item.album && item.album.images && item.album.images.length > 0)
                coverArtUrl = item.album.images[0].url
            else if (item.images && item.images.length > 0)
                coverArtUrl = item.images[0].url
            else
                coverArtUrl = ""

            // Album, ArtUrl, Artist, AlbumArtist, Composer, Length, TrackNumber, Title
            metadata[Mpris.metadataToString(Mpris.Title)] = item.name
            metadata[Mpris.metadataToString(Mpris.Artist)] = artistsString
            metadata[Mpris.metadataToString(Mpris.ArtUrl)] = coverArtUrl
            metadata[Mpris.metadataToString(Mpris.Length)] = item.duration_ms * 1000
            if(item.album && item.album.name)
                metadata[Mpris.metadataToString(Mpris.Album)] = item.album.name
            //console.log("  new metadata: " + JSON.stringify(metadata))
        }

        mprisPlayer.metadata = metadata
    }

    property string artistsString: ""
    property string coverArtUrl: ""

    signal playbackDeviceChanged(string id, string name)

    property var device: no_device
    property var no_device: {
        "id": "-1",
        "is_active": false,
        "is_private_session": false,
        "is_restricted": false,
        "type": "Nothing",
        "name": "No Device",
        "volume_percent": 0
    }

    onRepeat_stateChanged: console.log("onRepeat_stateChanged: " + repeat_state)

    property string repeat_state: "off"
    property bool shuffle_state: false
    property var context: undefined
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
    property var disallows: {}

    function isAllowed(action) {
        /*
        'interrupting_playback'
        'pausing'
        'resuming'
        'seeking'
        'skipping_next'
        'skipping_prev'
        'toggling_repeat_context'
        'toggling_shuffle'
        'toggling_repeat_track'
        'transferring_playback'
        */
        // not allowed if: disallowed.action: true
        // allowed if: no action or false or undefined
        return !disallows
          ? true
          : (!disallows.hasOwnProperty(action)
             ? true
             : !disallows[action])
    }

    function importState(state) {
        //console.log("importState: " + JSON.stringify(state))

        var oldDeviceName = device.name
        if(state.device)
            device = state.device
        else
            device = no_device

        repeat_state = state.repeat_state
        shuffle_state = state.shuffle_state
        timestamp = state.timestamp
        progress_ms = state.progress_ms
        is_playing = state.is_playing

        //if(!is_playing || state.item !== null)
        if(state.item !== null) {
            if(!item || state.item.uri !== item.uri)
                item = state.item
        }

        //if(!is_playing || state.context !== null)
        if(state.context !== null) {
            if(!context || state.context.uri !== context.uri)
                context = state.context
        }

        if(state.actions && state.actions.disallows)
            disallows = state.actions.disallows
        else
            disallows = {}

        if(oldDeviceName != device.name)
          playbackDeviceChanged(device.id, deviceName)

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
