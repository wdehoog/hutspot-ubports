/**
 * Hutspot.
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0
import "../Spotify.js" as Spotify
import "../Util.js" as Util


Item {

    property alias seedModel: seedModel

    // type 0: Artist, 1: Track, 2: Genre
    ListModel {
        id: seedModel
        ListElement {type: -1; sid: ""; name: ""; image: "";}
        ListElement {type: -1; sid: ""; name: ""; image: "";}
        ListElement {type: -1; sid: ""; name: ""; image: "";}
        ListElement {type: -1; sid: ""; name: ""; image: "";}
        ListElement {type: -1; sid: ""; name: ""; image: "";}
    }

    function clearSlot(index) {
        var emptySeed = {type: -1, sid: "", name: "", image: "",}
        seedModel.set(index, emptySeed)
    }

    function addSeed(seed) {
        seedModel.insert(0, seed)
        seedModel.remove(5, seedModel.count - 5)
    }

    function getSeedTypeString(type) {
        switch(type) {
            case 0: return i18n.tr("artist")
            case 1: return i18n.tr("track")
            case 2: return i18n.tr("genre")
        }
    }

    function addArtist(artist) {
        var seed = {
            type: 0,
            sid: artist.id,
            name: artist.name, 
            image: ""
        }
        addSeed(seed)
    }

    function addTrack(track) {
        var seed = {
            type: 1,
            sid: track.id,
            name: track.name, 
            image: ""
        }
        addSeed(seed)
    }

    function addGenre(genre) {
        var seed = {
            type: 2,
            sid: "",
            name: genre, 
            image: ""
        }
        addSeed(seed)
    }
}
