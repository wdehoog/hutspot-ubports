/**
 * Hutspot.
 * Copyright (C) 2021 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3

import "../Util.js" as Util

Rectangle {
    width: parent.width
    height: row.height
    color:  app.normalBackgroundColor

    property color textPrimaryColor: currentIndex === dataModel.index
                                     ? app.primaryHighlightColor : app.primaryColor
    property color textSecundaryColor: currentIndex === dataModel.index
                                     ? app.secondaryHighlightColor : app.secondaryColor
    property color textTertiaryColor: currentIndex === dataModel.index
                                     ? app.tertiaryHighlightColor : app.tertiaryColor

    property var dataModel
    property bool isCurrentItem: currentIndex === dataModel.index

    property string firstLine: _firstLine
    property string _firstLine: dataModel.name ? dataModel.name : qsTr("No Name")

    // these are not used but exist in AlbumTrackListItem so a Loader can be used
    property var isFavorite
    property bool saved
    property int contextType: -1

    signal toggleFavorite()

    Row {
        id: row


        width: parent.width
        spacing: app.paddingMedium

        opacity: (dataModel.type !== Util.SpotifyItemType.Track
                  || Util.isTrackPlayable(dataModel.item)) ? 1.0 : 0.4

        Image {
            id: image
            width: height
            height: column.height
            anchors {
                verticalCenter: parent.verticalCenter
            }
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: getImageURL(dataModel)
        }

        Column {
            id: column
            width: parent.width - image.width - app.paddingMedium

            Label {
                color: textPrimaryColor
                textFormat: Text.StyledText
                //font.weight: isCurrentItem ? app.fontHighlightWeight : app.fontPrimaryWeight
                //truncationMode: TruncationMode.Fade
                width: parent.width
                text: firstLine
            }

            Row {
                width: parent.width
                height: col2.height

                Column {
                    id: col2
                    width: parent.width - favorite.width
                    Label {
                        width: parent.width
                        color: textSecundaryColor
                        //font.weight: isCurrentItem ? app.fontHighlightWeight : app.fontPrimaryWeight
                        //font.pixelSize: fontSizeExtraSmall
                        elide: Text.ElideRight
                        text: getMeta1String()
                        enabled: text.length > 0
                        visible: enabled
                    }

                    Label {
                        width: parent.width
                        color: textTertiaryColor
                        //font.weight: isCurrentItem ? app.fontHighlightWeight : app.fontPrimaryWeight
                        //font.pixelSize: fontSizeExtraSmall
                        textFormat: Text.StyledText
                        elide: Text.ElideRight
                        text: getMeta2String()
                        enabled: text.length > 0
                        visible: enabled
                    }
                }
                Image {
                    id: favorite
                    anchors.verticalCenter: parent.verticalCenter
                    width: height
                    height: app.iconSizeSmall
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: (dataModel.following || dataModel.saved)
                            ? "image://theme/starred" : "image://theme/non-starred"
                    /*source: if(dataModel.following || dataModel.saved)
                                return currentIndex === dataModel.index
                                        ? "image://theme/icon-m-favorite-selected?" + Theme.highlightColor
                                        : "image://theme/icon-m-favorite-selected"
                            else
                                return currentIndex === dataModel.index
                                          ? "image://theme/icon-m-favorite?" + Theme.highlightColor
                                          : "image://theme/icon-m-favorite"*/
                    MouseArea {
                         anchors.fill: parent
                         onClicked: toggleFavorite()
                    }
                }
            }
        }
    }

    function getImageURL(dataModel) {
        var images
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
        case Util.SpotifyItemType.Artist:
        case Util.SpotifyItemType.Show:
        case Util.SpotifyItemType.Episode:
        case Util.SpotifyItemType.Playlist:
            if(dataModel.item.images)
                images = dataModel.item.images
            break;
        case Util.SpotifyItemType.Track:
            if(dataModel.item.images)
                images = dataModel.item.images
            else if(dataModel.item.album && dataModel.item.album.images)
                images = dataModel.item.album.images
            break;
        default:
            return ""
        }
        var url = ""
        if(images) {
            // ToDo look for the best image
            if(images.length >= 2)
                url = images[1].url
            else if(images.length > 0)
                url = images[0].url
            else
                 url = ""
        }
        return url
    }

    function getMeta1String() {
        var sb = new Util.Classes.StringBuilder()
        var items = []
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
            if(dataModel.item.artists)
                items = dataModel.item.artists
            sb.append(Util.createItemsString(items, qsTr("no artist known")))
            break
        case Util.SpotifyItemType.Artist:
            if(dataModel.item.genres)
                items = dataModel.item.genres
            sb.append(Util.createItemsString(items, qsTr("no genre known")))
            break
        case Util.SpotifyItemType.Playlist:
            if(dataModel.item.owner.display_name)
                sb.append(dataModel.item.owner.display_name)
            else {
                sb.append(qsTr("Id"))
                sb.append(": ")
                sb.append(dataModel.item.owner.id)
            }
            break
        case Util.SpotifyItemType.Track:
            if(dataModel.item.item)
                items = dataModel.item.artists
            else if(dataModel.item.album && dataModel.item.album.artists)
                items = dataModel.item.album.artists
            sb.append(Util.createItemsString(items, qsTr("no artist known")))
            if(dataModel.item.album) {
                if(dataModel.item.album.name.length === 0)
                    sb.append(qsTr("album not specified")) // should not happen but it does
                else
                    sb.append(dataModel.item.album.name)
            }
            break
        case Util.SpotifyItemType.Episode:
            if(dataModel.item.description)
                sb.append(dataModel.item.description)
            break
        case Util.SpotifyItemType.Show:
            if(dataModel.item.publisher)
                sb.append(dataModel.item.publisher)
            break
        }
        return sb.toString(", ")
    }

    function getMeta2String() {
        var sb = new Util.Classes.StringBuilder()
        switch(dataModel.type) {
        case Util.SpotifyItemType.Album:
            if(dataModel.item.tracks)
                sb.append(getNumTracksText(dataModel.item.tracks.total))
            else if(dataModel.item.total_tracks) // undocumented?
                sb.append(getNumTracksText(dataModel.item.total_tracks))
            sb.append(Util.getYearFromReleaseDate(dataModel.item.release_date))
            break
        case Util.SpotifyItemType.Artist:
            if(typeof(dataModel.item.followers) !== 'undefined')
                sb.append(Util.abbreviateNumber(dataModel.item.followers.total) + " " + i18n.tr("followers"))
            break
        case Util.SpotifyItemType.Playlist:
            sb.append(getNumTracksText(dataModel.item.tracks.total))
            break
        case Util.SpotifyItemType.Track:
            if(dataModel.item.duration_ms)
                sb.append(Util.getDurationString(dataModel.item.duration_ms))
            if(dataModel.played_at && dataModel.played_at.length>0)
                sb.append(qsTr("played at ") + Util.getPlayedAtText(dataModel.played_at))
            if(contextType === Util.SpotifyItemType.Playlist && dataModel.added_at)
                sb.append("@" + Util.getAddedAtText(dataModel.added_at)) // qsTr("added on ")
            break
        case Util.SpotifyItemType.Episode:
            if(dataModel.item.duration_ms)
                sb.append(Util.getDurationString(dataModel.item.duration_ms))
            if(dataModel.item.release_date)
                sb.append(Util.getReleaseDateText(dataModel.item.release_date))
            if(dataModel.item.languages)
                sb.append(Util.createItemsString(dataModel.item.languages, ""))
            break
        case Util.SpotifyItemType.Show:
            if(dataModel.item.languages)
                sb.append(Util.createItemsString(dataModel.item.languages, ""))
            if(dataModel.item.explicit)
                sb.append(i18n.tr("explicit"))
            if(dataModel.item.is_externally_hosted)
                sb.append(i18n.tr("externally hosted"))
            break
        }
        return sb.toString(", ")
    }

    function getNumTracksText(n) {
        return n + " " + (n === 1 ? qsTr("track") : qsTr("tracks"))
    }
}
