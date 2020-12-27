/**
 * Hutspot. 
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import "../Spotify.js" as Spotify
import "../Util.js" as Util


Item {
    PlaybackState {
        id: playbackState
    }

    function getCoverArt(defaultValue, ignoreContext) {
        if (ignoreContext) {
            if (playbackState.coverArtUrl)
                return playbackState.coverArtUrl
            return defaultValue
        }

        if (playbackState.contextDetails)
            if (playbackState.contextDetails.images)
                return playbackState.contextDetails.images[0].url
        return defaultValue;
    }

    property bool _hasActiveDevice: false
    property bool hasCurrentDevice: playbackState.is_playing || _hasActiveDevice
    onHasCurrentDeviceChanged: console.log("hasCurrentDevice: " + hasCurrentDevice)

    property alias playbackState: playbackState
    property alias devices: devicesModel

    ListModel {
        id: devicesModel
    }

    Timer {
        id: handleRendererInfo
        interval: 1000
        onRunningChanged: if (running) refreshCount = 0
        //running: playbackState.is_playing || Qt.application.active 
        running: Qt.application.active 
        property int refreshCount: 0
        repeat: true
        onTriggered: {
            // pretend progress (ms), refresh() will set the actual value
            if (playbackState.is_playing) {
                if (playbackState.progress_ms < playbackState.item.duration_ms) {
                    playbackState.progress_ms += 1000
                } else
                    playbackState.progress_ms = playbackState.item.duration_ms
            }

            // close to switching tracks so refresh every time
            // also reload playbackState if we haven't done it in a long time
            if(playbackState.is_playing
               && (playbackState.item.duration_ms - playbackState.progress_ms) < 3000) {
                refreshPlaybackState()
                refreshCount = 0
            } else if (++refreshCount >= 5) {
                refreshPlaybackState()
                refreshCount = 0
            }
        }
    }

    Connections {
        target: app
        onHasValidTokenChanged: {
            if(app.hasValidToken) {
                refreshPlaybackState()
                checkForNewDevices()
            }
        }
    }

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            interval = delayTime;
            repeat = false;
            triggered.connect(cb);
            triggered.connect(function() {
                triggered.disconnect(cb); // This is important
            });
            start();
        }
    }

    function seek(position, callback) {
        var value = Math.round(position);
        Spotify.seek(Math.round(value), function(error, data) {
            console.log("seek.callback: v=" + value + ", e=" + error + ", d=" + data)
            if (!error) {
                playbackState.progress_ms = value;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if(callback)
                callback(error, data)
        })
    }

    function setVolume(volume, callback) {
        var value = Math.round(volume);
        Spotify.setVolume(value, {device_id: getDeviceId()}, function(error, data) {
            console.log("setVolume.callback: v=" + value + ", e=" + error + ", d=" + data)
            if (!error) {
                playbackState.device.volume_percent = value;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if(callback)
                callback(error, data)
        })
    }

    ListModel {
        id: tmpDevicesModel
    }

    function checkForNewDevices() {
        Spotify.getMyDevices(function(error, data) {
            if (data) {
                //console.log("getMyDevices:" + JSON.stringify(data))
                //try {
                    var i, j, added, removed, changed, found, device

                    // a new one has been added?
                    added = false
                    for(i=0; i < data.devices.length; i++) {
                        found = false
                        for(j=0; j < devicesModel.count; j++) {
                            device = devicesModel.get(j)
                            if(data.devices[i].id === device.id) {
                                found = true
                                break
                            }
                        }
                        if(!found) {
                            added = true
                            break
                        }
                    }
                    // an old one has been removed?
                    removed = false
                    for(i=0; i < devicesModel.count; i++) {
                        found = false
                        device = devicesModel.get(i)
                        for(j=0; j < data.devices.length; j++) {
                            if(data.devices[j].id === device.id) {
                                found = true
                                break
                            }
                        }
                        if(!found) {
                            removed = true
                            break
                        }
                    }
                    // changed
                    changed = false
                    for(i=0; i < data.devices.length; i++) {
                        for(j=0; j < devicesModel.count; j++) {
                            device = devicesModel.get(j)
                            if(data.devices[i].id === device.id) {
                                if(Util.hasDeviceChanged(data.devices[i], device))
                                    changed = true
                                break
                            }
                        }
                        if(changed)
                            break
                    }
                    if(added || removed || changed) {
                        devicesModel.clear();
                        for(i=0; i < data.devices.length; i++) {
                            devicesModel.append(data.devices[i])
                        }
                        devicesReloaded()
                    }

                    // look for active device
                    found = false
                    for(i=0; i < devicesModel.count; i++) {
                        if(devicesModel.get(i).is_active) {
                            found = true
                            break
                        }
                    }
                    _hasActiveDevice = found
                //} catch (err) {
                //    console.log("controller.checkForNewDevices: error: " + err)
                //}
            }
        })
    }

    signal devicesReloaded()

    function delayedRefreshPlaybackState() {
        // for some reason we need to wait
        // thx spotify
        handleRendererInfo.refreshCount = 0
        timer.setTimeout(function () {
            refreshPlaybackState();
        }, 300)
    }

    function next(callback) {
        // TODO: use playback queue to find out what happens next!
        // exciting!
        Spotify.skipToNext({}, function(error, data) {
            if (callback)
                callback(error, data)
            refreshPlaybackState()
        })
    }

    function previous(callback) {
        Spotify.skipToPrevious({}, function(error, data) {
            if (callback)
                callback(error, data)
            refreshPlaybackState()
        })
    }

    function play(callback) {
        Spotify.play({'device_id': getDeviceId()}, function(error, data) {
            if(!error) {
                playbackState.is_playing = true;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if (callback)
                callback(error, data)
            else if(error)
                app.showErrorMessage(error, data)
        })
    }

    function pause(callback) {
        Spotify.pause({'device_id': getDeviceId()}, function(error, data) {
            if(!error) {
                playbackState.is_playing = false;
                if(_waitForPlaybackState)
                    _ignorePlaybackState = true
            }
            if (callback)
                callback(error, data)
            else if(error)
                app.showErrorMessage(error, data)
        })
    }

    function playPause(callback) {
        if (playbackState.is_playing)
            pause(callback);
        else
            play(callback);
    }

    function setRepeat(value, callback) {
        Spotify.setRepeat(value, {}, function(error, data) {
            if (!error) {
                playbackState.repeat_state = value;
                delayedRefreshPlaybackState();
            }

            if (callback) callback(error, data)
        })
    }

    function nextRepeatState() {
        if (playbackState.repeat_state === "off")
            return "context"
        else if (playbackState.repeat_state === "context")
            return "track";
        return "off";
    }

    function setShuffle(value, callback) {
        Spotify.setShuffle(value, {}, function(error, data) {
            if (!error) {
                playbackState.shuffle_state = value;
                delayedRefreshPlaybackState();
            }

            if (callback) callback(error, data)
        })
    }

    // this allows to check if a response is underway (with possibly outdated info)
    property bool _waitForPlaybackState: false
    property bool _ignorePlaybackState: false

    function refreshPlaybackState() {
        _waitForPlaybackState = true
        var oldContextId = playbackState.context ? playbackState.context.uri : undefined;

        Spotify.getMyCurrentPlaybackState({}, function (error, data, status) {
            _waitForPlaybackState = false
            if(_ignorePlaybackState) {
                _ignorePlaybackState = false
                return
            }

            if(!error && !data) {
                // status: 200 for no device, 204 for not playing or private session
                playbackState.notifyNoState(status)
                checkForNewDevices()
            } else if (data) {
                playbackState.importState(data)
                if (data.context && data.context.uri !== oldContextId) {
                    var cid = Util.getIdFromURI(playbackState.context.uri)
                    switch (data.context.type) {
                        case 'album':
                            Spotify.getAlbum(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                        case 'artist':
                            Spotify.getArtist(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                        case 'playlist':
                            Spotify.getPlaylist(cid, {}, function(error, data) {
                                playbackState.contextDetails = data
                            })
                            break
                        default:
                            playbackState.contextDetails = null
                    }
                } else {
                    // ToDo why is this?
                    // Disabled since we lose ifo on what is being played
                    //playbackState.contextDetails = undefined
                }
            }
        })
        //reloadDevices() Why is this here? The info is not used.
    }

    function playTrack(track) {
        Spotify.play({
            'device_id': getDeviceId(),
            'uris': [track.uri]
        }, function(error, data) {
            if(!error) {
                playbackState.item = track
                refreshPlaybackState()
            } else
                app.showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    function playContext(context) {
        var options = {
            'device_id': getDeviceId(),
            'context_uri': context.uri
        }
        var uri = context.uri
        Spotify.play(options, function(error, data) {
            if (!error) {
              refreshPlaybackState()
              app.notifyHistoryUri(uri)
            } else
                app.showErrorMessage(error, qsTr("Play Failed"))
        })
    }

    // ToDo: remove position?
    function playTrackInContext(track, context, position) {
        // does not work for some tracks.
        if (playbackState.device) {
            Spotify.play({
                "device_id": getDeviceId(),
                "context_uri": context.uri,
                //"offset": {"position": position}
                "offset": {"uri": track.linked_from
                                  ? track.linked_from.uri : track.uri}
            }, function (error, data) {
                if (!error) {
                    playbackState.item = track
                    refreshPlaybackState();
                } else {
                    app.showErrorMessage(error, qsTr("Play failed"))
                }
            })
        } else {
            // TODO: handle that
            app.showErrorMessage(error, qsTr("No device selected"))
        }
    }

    function playEpisodeInContext(episode) {
        if(!playbackState.device) {
            app.showErrorMessage(error, qsTr("No device selected"))
            return
        }
        // get the full Episode object  
        Spotify.getEpisode(episode.id, {}, function(error, data) {
            if(data) {
                //console.log(JSON.stringify(data))
                Spotify.play({
                    "device_id": getDeviceId(),
                    "context_uri": data.show.uri,
                    "offset": {"uri": data.uri}
                }, function (error, data) {
                    if (!error) {
                        playbackState.item = data
                        refreshPlaybackState();
                    } else {
                        app.showErrorMessage(error, qsTr("Play Failed"))
                    }
                })
            } else {
                app.showErrorMessage(error, qsTr("Failed to fetch Episode"))
            }
        })
    }

    function getDeviceId() {
        return (playbackState.device && playbackState.device.id !== "-1")
               ? playbackState.device.id
               : app.deviceId.value
    }

}
