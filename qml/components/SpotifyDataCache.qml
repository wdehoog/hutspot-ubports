/**
 * Hutspot.
 * Copyright (C) 2021 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.0

import "../Spotify.js" as Spotify
import "../Util.js" as Util

Item {

    signal spotifyDataCacheReady()

    signal playlistDetailsUpdated(var id, var details)

    property bool ready: false

    readonly property int followedPlaylistsMask: 0x01
    readonly property int followedArtistsMask: 0x02
    readonly property int savedAlbumsMask: 0x04
    readonly property int savedShowsMask: 0x08
    //readonly property int savedTracksMask: 0x10

    readonly property int allDoneMask: 0x0F
    property int happendMask: 0

    function notifyHappend(mask) {
        happendMask |= mask
        if((happendMask & allDoneMask) === allDoneMask) {
            console.log("will signal 'spotifyDataCacheReady'")
            ready = true
            spotifyDataCacheReady()
        }
    }

    property var _followedPlaylists: {}
    property var _followedArtistsId: {}
    property var _savedAlbumsId: {}
    property var _savedTracksId: {}
    property var _savedShowsId: {}

    function isPlaylistFollowed(id) {
        return _followedPlaylists[id] !== null
    }

    function getPlaylistProperty(id, property) {
        //console.log("getPlaylistProperty("+id+","+property+")")
        var data = _followedPlaylists[id]
        //console.log("found: "+JSON.stringify(data))
        return data ? data[property] : null
    }

    function isArtistFollowed(id) {
        return _followedArtistsId[id] !== null
    }

    function isAlbumSaved(id) {
        return _savedAlbumsId[id] !== null
    }

    function isShowSaved(id) {
        return _savedShowsId[id] !== null
    }

    // Followed Playlists
    function loadFollowedPlaylists() {
        _followedPlaylists = {}
        _loadFollowedPlaylistsSet(0)
    }

    function _loadFollowedPlaylistsSet(offset) {
        Spotify.getUserPlaylists({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.items) {
                for(i=0;i<data.items.length;i++)
                    updateFollowedPlaylist(data.items[i])
                var nextOffset = data.offset+data.items.length
                if(nextOffset < data.total)
                    _loadFollowedPlaylistsSet(nextOffset)
                else {
                    console.log("Loaded info of " + Object.keys(_followedPlaylists).length + " followed playlists")
                    notifyHappend(followedPlaylistsMask)
                }
            } else {
                console.log("no data for getUserPlaylists")
                notifyHappend(followedPlaylistsMask)
            }
        })
    }

    function updateFollowedPlaylist(playlist) {
        var plData = {
            href: playlist.href,
            uri: playlist.uri,
            name: playlist.name,
            image: playlist.images && playlist.images.length > 0
                ? playlist.images[0].url : ""
        }
        //console.log("adding " + JSON.stringify(plData) + " for " +  playlist.id)
        return _followedPlaylists[playlist.id] = plData
    }

    function triggerUpdatePlaylistDetails(playlistId) {
        Spotify.getPlaylist(playlistId, {}, function(error, data) {
            if(data) {
                var d = updateFollowedPlaylist(data)
                playlistDetailsUpdated(data.id, d)
            } else
                console.log("no data for getPlaylist " + playlistId)
        })
    }

    // Followed Artists
    function loadFollowedArtists() {
        _followedArtistsId = {}
        _loadFollowedArtists(0)
    }

    function _loadFollowedArtists(offset) {
        Spotify.getFollowedArtists({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.artists) {
                for(i=0;i<data.artists.items.length;i++) {
                    _followedArtistsId[data.artists.items[i].id] = data.artists.items[i].uri
                }
                var nextOffset = data.offset+data.artists.items.length
                if(nextOffset < data.artists.total)
                    _loadFollowedPlaylistsSet(nextOffset)
                else {
                    console.log("Loaded info of " + Object.keys(_followedArtistsId).length + " followed artists")
                    notifyHappend(followedArtistsMask)
                }
            } else {
                notifyHappend(followedArtistsMask)
                console.log("no data for getFollowedArtists")
            }
        })
    }

    // Saved Albums
    function loadSavedAlbums() {
        _savedAlbumsId = {}
        _loadSavedAlbums(0)
    }

    function _loadSavedAlbums(offset) {
        Spotify.getMySavedAlbums({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.items) {
                for(i=0;i<data.items.length;i++) {
                    _savedAlbumsId[data.items[i].album.id] = data.items[i].album.uri
                }
                var nextOffset = data.offset+data.items.length
                if(nextOffset < data.total)
                    _loadSavedAlbums(nextOffset)
                else {
                    console.log("Loaded info of " + Object.keys(_savedAlbumsId).length + " saved albums")
                    notifyHappend(savedAlbumsMask)
                }
            } else {
                console.log("no data for getMySavedAlbums")
                notifyHappend(savedAlbumsMask)
            }
        })
    }

    // Saved Shows
    function loadSavedShows() {
        _savedShowsId = {}
        _loadSavedShows(0)
    }

    function _loadSavedShows(offset) {
        Spotify.getMySavedShows({offset: offset, limit: 50}, function(error, data) {
            var i
            if(data && data.items) {
                for(i=0;i<data.items.length;i++) {
                    _savedShowsId[data.items[i].show.id] = data.items[i].show.uri
                }
                var nextOffset = data.offset+data.items.length
                if(nextOffset < data.total)
                    _loadSavedShows(nextOffset)
                else {
                    console.log("Loaded info of " + Object.keys(_savedShowsId).length + " saved shows")
                    notifyHappend(savedShowsMask)
                }
            } else {
                console.log("no data for getMySavedShows")
                notifyHappend(savedShowsMask)
            }
        })
    }

    Connections {
        target: app

        onHasValidTokenChanged: {
            if(app.hasValidToken) {
                loadFollowedPlaylists()
                loadFollowedArtists()
                loadSavedAlbums()
                loadSavedShows()
            }
        }

        onPlaylistEvent: {
            switch(event.type) {
            case Util.PlaylistEventType.ChangedDetails:
            case Util.PlaylistEventType.ReplacedAllTracks:
                triggerUpdatePlaylistDetails(event.playlistId)
                break
            }
        }

        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
                if(event.isFavorite)
                    _savedAlbumsId[event.id] = event.uri
                else
                    delete _savedAlbumsId[event.id]
                break
            case Util.SpotifyItemType.Artist:
                if(event.isFavorite)
                    _followedArtistsId[event.id] = event.uri
                else
                    delete _followedArtistsId[event.id]
                break
            case Util.SpotifyItemType.Playlist:
                if(event.isFavorite)
                    triggerUpdatePlaylistDetails(event.id)
                else
                    delete _followedPlaylists[event.id]
                break
            case Util.SpotifyItemType.Show:
                if(event.isFavorite)
                    _savedShowsId[event.id] = event.uri
                else
                    delete _savedShowsId[event.id]
                break
            }
        }
    }

}
