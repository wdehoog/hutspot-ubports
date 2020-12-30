/**
 * Hutspot. 
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../Spotify.js" as Spotify
import "../Util.js" as Util

Component {
    id: contextMenu

    ContextMenuPopover {

        actions: ActionList {
            Action {
                id: a
                property int idx: enabled ? 0 : -1
                text: i18n.tr("Play")
                visible: enabled
                enabled: Util.isTrackPlayable(model.item)
                onTriggered: app.controller.playTrackInContext(model.item, context, model.index)
            }

            Action {
                id: b
                property int idx: enabled ? (a.idx + 1) : a.idx
                text: i18n.tr("View Album")
                visible: enabled
                enabled: fromPlaying && model.type === Util.SpotifyItemType.Track
                onTriggered: {
                  app.loadAlbum(model.item.album ? model.item.album : context, fromPlaying)
                }
            }

            Action {
                id: c
                property int idx: enabled ? (b.idx + 1) : b.idx
                text: i18n.tr("View Artist")
                visible: enabled
                enabled: fromPlaying && model.type === Util.SpotifyItemType.Track
                onTriggered: app.loadArtist(model.item.artists, fromPlaying)
            }

            /*Action {
                visible: enableQueueItems
                text: i18n.tr("Add to Queue")
                onTriggered: app.queue.addToQueue(item)
            }

            Action {
                visible: enableQueueItems
                text: i18n.tr("Replace Queue")
                onTriggered: app.queue.replaceQueueWith([item.uri])
            }*/

            Action {
                id: d
                property int idx: enabled ? (c.idx + 1) : c.idx
                text: i18n.tr("Add to Playlist")
                onTriggered: app.addToPlaylist(model.item)
            }
        }

    }
}
