/**
 * Hutspot. Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7

import "../Util.js" as Util

Item {


    //
    // Spotify Connect
    //

    property var _libreSpotCredentials: null

    function hasLibrespotCredentials() {
        return _libreSpotCredentials != null
    }

    Component.onCompleted: loadLibrespotCredentials()

    function loadLibrespotCredentials() {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", StandardPaths.AppConfigLocation + "/credentials.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var response = xhr.responseText;
                console.log(response)
                _libreSpotCredentials = JSON.parse(response)
                spConnect.setCredentials(_libreSpotCredentials.username,
                                         _libreSpotCredentials.auth_type,
                                         _libreSpotCredentials.auth_data)
            }
        }
        xhr.send()
    }

    function addUser(device, callback) {
        var addUserData = {}

        addUserData.action = "addUser"
        addUserData.userName = _libreSpotCredentials.username
        addUserData.blob = spConnect.createBlobToSend(device.remoteName, device.publicKey)
        addUserData.clientKey = spConnect.getPublicKey()
        addUserData.deviceName = playerName
        addUserData.deviceId = spConnect.getDeviceId(app.playerName)
        addUserData.version = "0.1"

        // unfortunately we have nothing better to report.
        // (sometimes it is the same as _libreSpotCredentials.username)
        // Librespot does not use it
        addUserData.loginId = app.id

        Util.deviceAddUserRequest(device.deviceInfo, addUserData, function(error, data) {
            if(callback)
                callback(error, data)
            if(data)
                console.log("deviceAddUserRequest: " + JSON.stringify(data))
            else
                console.log("deviceAddUserRequest error: " + error)
        })
    }

}
