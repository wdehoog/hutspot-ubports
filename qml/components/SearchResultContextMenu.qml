import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2

import "../Util.js" as Util

Component {
    id: contextMenu

    ActionSelectionPopover {
        id: actionSelectionPopover

        //property var model: null

        actions: ActionList {
            Action {
                text: i18n.tr("Play")
                enabled: model && (model.type !== Util.SpotifyItemType.Track || Util.isTrackPlayable(model.item))
                visible: enabled
                onTriggered: handlePlayClicked()
            }
            Action {
                text: i18n.tr("View")
                enabled: model && (model.type !== Util.SpotifyItemType.Track)
                visible: enabled
                onTriggered: handleViewClicked()
            }
            Action {
                text: i18n.tr("View Album")
                enabled: model && (model.type === Util.SpotifyItemType.Track)
                visible: enabled
                onTriggered: app.pushPage(Util.HutspotPage.Album, {album: model.item.album})
            }
            Action {
                text: i18n.tr("Add to Playlist")
                enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                         && contextType !== Util.SpotifyItemType.Playlist
                visible: enabled
                onTriggered: app.addToPlaylist(model.item)
            }
            Action {
                text: i18n.tr("Remove from Playlist")
                enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                         && contextType === Util.SpotifyItemType.Playlist
                visible: enabled
                onTriggered: {
                    var idx = index
                    var smodel = model
                    app.removeFromPlaylist(playlist, model.item, index+cursorHelper.offset)
                    /*app.removeFromPlaylist(playlist, model.item, index+cursorHelper.offset, function(error, data) {
                        if(!error)
                            smodel.remove(idx, 1)
                    })*/
                }
            }
            Action {
                text: i18n.tr("Add to another Playlist")
                enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                         && contextType === Util.SpotifyItemType.Playlist
                visible: enabled
                onTriggered: app.addToPlaylist(model.item)
            }
            Action {
                text: i18n.tr("Use as Seeds for Recommendations")
                enabled: model && (model.type === Util.SpotifyItemType.Playlist)
                visible: enabled
                onTriggered: app.useAsSeeds(model.item)
            }
        }

        function handlePlayClicked() {
            switch(model.type) {
            case Util.SpotifyItemType.Album:
            case Util.SpotifyItemType.Artist:
            case Util.SpotifyItemType.Playlist:
                app.controller.playContext(model.item)
                break;
            case Util.SpotifyItemType.Track:
                switch(contextType) {
                case Util.SpotifyItemType.Album:
                    app.controller.playTrackInContext(model.item, model.album, index)
                    break
                case Util.SpotifyItemType.Playlist:
                    app.controller.playTrackInContext(model.item, model.playlist, index)
                    break
                default:
                    app.controller.playTrack(model.item)
                    break
                }
                break;
            }
        }

        function handleViewClicked() {
            switch(model.type) {
            case Util.SpotifyItemType.Album:
                app.pushPage(Util.HutspotPage.Album, {album: model.item})
                break
            case Util.SpotifyItemType.Artist:
                app.pushPage(Util.HutspotPage.Artist, {currentArtist: model.item})
                break
            case Util.SpotifyItemType.Playlist:
                app.pushPage(Util.HutspotPage.Playlist, {playlist: model.item})
                break
            }
        }
    }  
}  
