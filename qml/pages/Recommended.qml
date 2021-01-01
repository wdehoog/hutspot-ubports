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

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: recommendedPage
    objectName: "RecommendedPage"

    property bool showBusy: false
    property int currentIndex: -1

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Recommended")
        flickable: listView
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add Genre")
                iconName: "stock_music"
                onTriggered: selectGenreSeed()
            },
            Action {
                text: i18n.tr("Import into Playlist")
                iconName: "import"
                enabled: searchModel.count > 0
                onTriggered: importIntoPlaylist()
            }
        ]
    }

    Component {
        id: headerComponent
        Column {

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            anchors.bottomMargin: app.paddingLarge
            spacing: app.paddingLarge

            Label {
                text: i18n.tr("Seeds")
                font.weight: app.fontHighlightWeight
                anchors.right: parent.right
            }

            ListView {
                id: seedListView
                width: parent.width
                implicitHeight: contentItem.childrenRect.height

                model: app.recommendationSeeds.seedModel

                delegate: ListItem {
                    height: app.itemSizeMedium
                    Row {
                        id: row
                        width: parent.width
                        spacing: app.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter

                        /*Image {
                            id: image
                            width: height
                            height: column.height
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            source: image
                        }*/

                        Text {
                            width: parent.width - parent.spacing - clearButton.width
                            anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.StyledText
                            font.weight: app.fontPrimaryWeight
                            //truncationMode: TruncationMode.Fade
                            horizontalAlignment: type >= 0 ? Text.AlignLeft : Text.AlignHCenter
                            text: type >= 0 
                                  ? app.recommendationSeeds.getSeedTypeString(type) + ": " + name
                                  : i18n.tr("Empty Seed Slot")
                        }
                        Icon {
                            id: clearButton
                            //height: parent.height
                            width: app.iconSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                            //color: app.normalBackgroundColor
                            name: "edit-clear"
                            visible: type >= 0
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    app.recommendationSeeds.clearSlot(index)
                                }
                            }
                        }
                    }
                }
            }

            /*Rectangle {
                width: parent.width
                height: app.paddingMedium
                opacity: 0
            }*/

            Label {
                text: i18n.tr("Recommendations")
                font.weight: app.fontHighlightWeight
                anchors.right: parent.right
            }
        }
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        height: parent.height

        header: headerComponent

        delegate: ListItem {
            id: listItem
            width: parent.width - 2 * app.paddingMedium
            x: app.paddingMedium

            SearchResultListItem {
                id:trackListItem
                dataModel: model
                isFavorite: saved
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            onPressAndHold: {
                //contextMenu.model = model
                //contextMenu.context = album
                //PopupUtils.open(contextMenu, listItem)
            }

            //onClicked: app.controller.playTrackInContext(item, album, index)
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    //onAlbumChanged: refresh()

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()
        append()
    }

    property bool _loading: false

    function append() {
        var i

        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        var artists = []
        var tracks = []
        var genres = []

        for(i=0;i<app.recommendationSeeds.seedModel.count;i++) {
            var seed = app.recommendationSeeds.seedModel.get(i)
            switch(seed.type) {
                case 0:
                    artists.push(seed.sid)
                    break
                case 1:
                    tracks.push(seed.sid)
                    break
                case 2:
                    genres.push(seed.name)
                    break
            }
        }

        var options = {offset: searchModel.count, limit: cursorHelper.limit}
        options.seed_artists = artists.join(',')
        options.seed_tracks = tracks.join(',')
        options.seed_genres = genres.join(',')
        if(app.settings.queryForMarket)
            options.market = "from_token"
        //console.log(JSON.stringify(options))

        Spotify.getRecommendations(options, function(error, data) {
            if(data) {
                try {
                    //console.log("number of Recommendations: " + data.tracks.length)
                    app.loadTracksInModel(data, data.tracks.length, searchModel, function(data, i) {return data.tracks[i]})
                } catch (err) {
                    console.log(err)
                }
            } else
                console.log("No Data for getRecommendations")
            _loading = false
        })

    }

    function selectGenreSeed() {
        var ms = pageStack.push(Qt.resolvedUrl("../components/GenrePicker.qml"),
                                { label: i18n.tr("Select a Genre") } );
        ms.accepted.connect(function() {
            if(ms.selectedItem && ms.selectedItem.name) {
                app.recommendationSeeds.addGenre(ms.selectedItem.name)
                refresh()
            }
        })
    }

    function importIntoPlaylist() {
        if(searchModel.count <= 0)
            return
        app.showConfirmDialog(i18n.tr("Do you want to replace the tracks in the Hutspot Recommendations playlist with these results?"),
            function() {
                var uris = [searchModel.count]
                for(var i=0;i<searchModel.count;i++)
                    uris[i] = searchModel.get(i).item.uri
                var info = {}
                info.name = "Recommendations [hutspot]"
                info.description = "Playlist for Hutspot to store recommended tracks"
                info.usage = "store recommended tracks"
                app.replaceTracksInHutspotPlaylist(info, uris)
            }
        )
    }

    /*Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
                if(album.id === event.id) {
                    isAlbumSaved = event.isFavorite
                }
                break
            case Util.SpotifyItemType.Track:
                // no way to check if this track is for this album
                // so just try to update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
    }*/

}
