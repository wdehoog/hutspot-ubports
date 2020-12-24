/**
 * Hutspot. Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Themes 1.3

import Qt.labs.platform 1.0 as Platform

//import Nemo.DBus 2.0
import org.hildon.components 1.0
import SystemUtil 1.0

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
        xhr.open("GET", Platform.StandardPaths.AppConfigLocation + "/credentials.json");
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

    //
    // Register credentials with librespot.
    //

    function delayedExec(callback, delay) {
        delayTimer.callback = callback
        delayTimer.interval = delay
        delayTimer.running = true
    }

    Timer {
        id: delayTimer
        running: false
        repeat: false
        property var callback
        onTriggered: callback()
    }

    function addCredentials(username, password, callback) {
        var command = Platform.StandardPaths.HomeLocation + "/bin/librespot"
        var args = []
        args.push("--cache")
        args.push(Platform.StandardPaths.AppConfigLocation)
        args.push("--name")
        args.push("librespot")
        args.push("--username")
        args.push(username)
        process.callback = callback
        process.start(command, args)
        process.write(password + "\n")
        process.closeWriteChannel()
        delayedExec(function() {
            // ToDo: don't know if this delay is needed, not if it is enough
            //process.terminate() // SIGTERM
            //process.kill() // SIGKILL
            if(process.state === Processes.Running)
                sysUtil.pkill(process.pid, SystemUtils.SIGINT)
        }, 2000)
    }

    // example output of Librespot on successfull login
    //  INFO:librespot: librespot UNKNOWN (UNKNOWN). Built on 2019-01-03. Build ID: YKCM15nl
    //  Password for xxxxxx: INFO:librespot_core::session: Connecting to AP "gew1-accesspoint-b-437f.ap.spotify.com:4070"
    //  INFO:librespot_core::session: Authenticated as "xxxxxxxxxxxxxx" !
    //  INFO:librespot_core::session: Country: "NL"
    function isSuccess(data) {
        if(!data)
            return false
        return data.indexOf("Authenticated as") > -1
    }

    function registerCredentials() {
        /*var wasRunning = false
        if(!serviceEnabled) {
            app.showErrorMessage(error, qsTr("Librespot seems not available"))
            return
        }
        if(serviceRunning) {
            wasRunning = true
            stop()
        }*/

        _confirmAcceptedCallback = function(dialog) {
            if(dialog.usernameField.text.length > 0
               && dialog.passwordField.text.length > 0) {
                addCredentials(dialog.usernameField.text, dialog.passwordField.text, function(error, exitCode, data){
                    console.log("callback error: " + error + ", exitCode: " + exitCode +", data: " + data)
                    if(exitCode !== 0 || !isSuccess(data)) {
                        app.showErrorMessage(error, i18n.tr("Failed to register credentials for Librespot"))
                    } else {
                        app.showErrorMessage(null, i18n.tr("Registered credentials for Librespot"))
                    }
                    /*if(wasRunning) {
                        start()
                    }*/
                })
            }
            /*dialog.rejected.connect(function() {
                if(wasRunning) {
                    start()
                }
            })*/
        }
        PopupUtils.open(credentialsDialog)
    }

    signal confirmAccepted()
    property var _confirmAcceptedCallback: null
    onConfirmAccepted: {
        if(_confirmAcceptedCallback != null) {
            _confirmAcceptedCallback()
            _confirmAcceptedCallback = null
        }
    }

    Component {
        id: credentialsDialog
        Dialog {
            id: dialog

            title: qsTr("Register Spotify credentials with Librespot")

            property alias usernameField: usernameField
            property alias passwordField: passwordField

            Column {
                width: parent.width

                TextField {
                    id: usernameField
                    width: parent.width
                    placeholderText: i18n.tr("User Name")

                }
                TextField {
                    id: passwordField
                    width: parent.width
                    placeholderText: i18n.tr("Password")
                    echoMode: TextInput.Password
                }
                Rectangle {
                    width: parent.width
                    height: app.paddingLarge
                    color: "transparent"
                }
                Button { 
                    text: i18n.tr("Ok")
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - units.gu(4)
                    color: theme.palette.normal.positive
                    onClicked: {
                      PopupUtils.close(dialog)
                      confirmAccepted(dialog)  
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - units.gu(4)
                    color: theme.palette.normal.negative
                    onClicked: PopupUtils.close(dialog)
                }
            }
        }
    }

    Process {
        id: process

        property var callback: undefined

        workingDirectory: Platform.StandardPaths.HomeLocation

        onExitCodeChanged: {
            console.log("onExitCodeChanged: " + process.exitCode)
        }

        onStateChanged: {
            console.log("onStateChanged: " + process.state)
        }

        onProcessFinished: {
            console.log("onProcessFinished: " + process.error)
        }

        onError: {
            if(callback !== undefined)
                callback(process.error, process.exitCode, undefined)
            console.log("Librespot Process.Error: " + process.error)
            callback = undefined
        }

        onFinished: {
            var stdout = process.readAllStandardOutput()
            var stderr = process.readAllStandardError()
            console.log("Librespot Process.Finished: " + process.exitStatus + ", code: " + process.exitCode)
            console.log("[stdout]:" + stdout)
            console.log("[stderr]:" + stderr)

            if(callback !== undefined)
                callback(null, process.exitCode, stderr)
            callback = undefined
        }
    }
}
