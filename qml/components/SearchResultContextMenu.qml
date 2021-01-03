import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2

import "../Util.js" as Util

Item {
    id: contextMenu

    property int index: -1
    property var model
    property int contextType: -1

    function open(theModel, item) {
        model = theModel
        PopupUtils.open(popup, item)
    }

    Component {
        id: popup

        ContextMenuPopover {
            id: contextMenu

            actions: ActionList {
                Action {
                    id: a
                    property int idx: enabled ? 0 : -1
                    text: i18n.tr("Play")
                    enabled: model && (model.type !== Util.SpotifyItemType.Track || Util.isTrackPlayable(model.item))
                    visible: enabled
                    onTriggered: handlePlayClicked()
                }
                Action {
                    id: b
                    property int idx: enabled ? (a.idx + 1) : a.idx
                    text: i18n.tr("View")
                    enabled: model
                             && (model.type !== Util.SpotifyItemType.Track)
                             && (model.type !== Util.SpotifyItemType.Episode)
                    visible: enabled
                    onTriggered: handleViewClicked()
                }
                Action {
                    id: c
                    property int idx: enabled ? (b.idx + 1) : b.idx
                    text: i18n.tr("View Album")
                    enabled: model && (model.type === Util.SpotifyItemType.Track)
                    visible: enabled
                    onTriggered: app.loadAlbum(model.item.album, false)
                }
                Action {
                    id: d
                    property int idx: enabled ? (c.idx + 1) : c.idx
                    text: i18n.tr("View Show")
                    enabled: model
                             && (model.type === Util.SpotifyItemType.Episode)
                             && contextType !== Util.SpotifyItemType.Show
                    visible: enabled
                    onTriggered: app.loadShowForEpisode(model.item, false)
                }
                Action {
                    id: e
                    property int idx: enabled ? (d.idx + 1) : d.idx
                    text: i18n.tr("Add to Playlist")
                    enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                             && contextType !== Util.SpotifyItemType.Playlist
                    visible: enabled
                    onTriggered: app.addToPlaylist(model.item)
                }
                Action {
                    id: f
                    property int idx: enabled ? (e.idx + 1) : e.idx
                    text: i18n.tr("Remove from Playlist")
                    enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                             && contextType === Util.SpotifyItemType.Playlist
                    visible: enabled
                    onTriggered: {
                        app.removeFromPlaylist(playlist, model.item, index+cursorHelper.offset)
                    }
                }
                Action {
                    id: g
                    property int idx: enabled ? (f.idx + 1) : f.idx
                    text: i18n.tr("Add to another Playlist")
                    enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                             && contextType === Util.SpotifyItemType.Playlist
                    visible: enabled
                    onTriggered: app.addToPlaylist(model.item)
                }
                Action {
                    id: h
                    property int idx: enabled ? (g.idx + 1) : g.idx
                    text: i18n.tr("Add to Recommendation Seeds")
                    enabled: model && (model.type === Util.SpotifyItemType.Artist
                                       || model.type === Util.SpotifyItemType.Track )
                    visible: enabled
                    onTriggered: {
                        switch(model.type) {
                        case Util.SpotifyItemType.Artist:
                            app.addArtistToRecommendationSet(model.item)
                            break
                        case Util.SpotifyItemType.Track:
                            app.addTrackToRecommendationSet.addTrack(model.item)
                            break
                        }
                    }
                }
                /*Action {
                    text: i18n.tr("Use as Seeds for Recommendations")
                    enabled: model && (model.type === Util.SpotifyItemType.Playlist)
                    visible: enabled
                    onTriggered: app.useAsSeeds(model.item)
                }*/
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
                        app.controller.playTrackInContext(model.item, model.item.album)
                        break
                    case Util.SpotifyItemType.Playlist:
                        app.controller.playTrackInContext(model.item, model.item.playlist)
                        break
                    default:
                        app.controller.playTrackInContext(model.item)
                        break
                    }
                    break;
                case Util.SpotifyItemType.Episode:
                    app.controller.playEpisodeInContext(model.item)
                    break
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
                case Util.SpotifyItemType.Show:
                    app.pushPage(Util.HutspotPage.Show, {show: model.item})
                    break
                }
            }

        }
    }
}
