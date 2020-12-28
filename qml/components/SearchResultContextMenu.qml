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
                    enabled: model 
                             && (model.type !== Util.SpotifyItemType.Track)
                             && (model.type !== Util.SpotifyItemType.Episode)
                    visible: enabled
                    onTriggered: handleViewClicked()
                }
                Action {
                    text: i18n.tr("View Album")
                    enabled: model && (model.type === Util.SpotifyItemType.Track)
                    visible: enabled
                    onTriggered: app.loadAlbum(model.item.album, false)
                }
                Action {
                    text: i18n.tr("View Show")
                    enabled: model && (model.type === Util.SpotifyItemType.Episode)
                    visible: enabled
                    onTriggered: app.loadShowForEpisode(model.item, false)
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
                        app.removeFromPlaylist(playlist, model.item, index+cursorHelper.offset)
                    }
                }
                Action {
                    text: i18n.tr("Add to another Playlist")
                    enabled: model && (model.type === Util.SpotifyItemType.Track && Util.isTrackPlayable(model.item))
                             && contextType === Util.SpotifyItemType.Playlist
                    visible: enabled
                    onTriggered: app.addToPlaylist(model.item)
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
                        app.controller.playTrackInContext(model.item, model.item.album, -1)
                        break
                    case Util.SpotifyItemType.Playlist:
                        app.controller.playTrackInContext(model.item, model.item.playlist, -1)
                        break
                    default:
                        app.controller.playTrack(model.item)
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

            Rectangle {
                anchors.fill: parent
                color: app.popupBackgroundColor
                opacity: app.popupBackgroundOpacity
                radius: app.popupRadius
                z: -1
            }
        }  
    }
}
