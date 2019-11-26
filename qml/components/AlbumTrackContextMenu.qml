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

import "../Util.js" as Util

Component {
    id: contextMenu

    ActionSelectionPopover {

        actions: ActionList {
            Action {
                text: i18n.tr("Play")
                visible: enabled
                enabled: Util.isTrackPlayable(model.item)
                onTriggered: app.controller.playTrackInContext(model.item, context, model.index)
            }

            Action {
                text: i18n.tr("View Album")
                visible: enabled
                enabled: fromPlaying && model.type === Util.SpotifyItemType.Track
                onTriggered: app.pushPage(Util.HutspotPage.Album, {album: model.item.album}, fromPlaying)
            }

            Action {
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
                text: i18n.tr("Add to Playlist")
                onTriggered: app.addToPlaylist(model.item)
            }
        }

    }
}
