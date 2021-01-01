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

    property bool _signal: true

    signal seedsChanged()

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
        if(_signal) seedsChanged()
    }

    function addSeed(seed) {
        seedModel.insert(0, seed)
        seedModel.remove(5, seedModel.count - 5)
        if(_signal) seedsChanged()
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

    function getSeedsSaveData() {
        var i
        var savedSeeds = []
        for(i=0;i<seedModel.count;i++) {
            var seed = seedModel.get(i)
            if(seed.type >= 0)
                savedSeeds.push({stype: seed.type, sid: seed.sid, sname: seed.name})
        }
        var saveData = []
        saveData.push({name: "saved_seeds", seeds: savedSeeds})
        return saveData
    }

    function loadSeedsSaveData(saveData) {
        console.log("loadSeedsSaveData: " + JSON.stringify(saveData))
        _signal = false
        var i
        var savedSeeds = saveData[0].seeds
        for(i=savedSeeds.length;i>0;i--) { // reverse order
            var seed = savedSeeds[i-1]
            addSeed({type: seed.stype, sid: seed.sid, name: seed.sname, image: ""})
        }
        _signal = true
    }
}
