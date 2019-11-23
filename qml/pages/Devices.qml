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

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: devicesPage

    property bool isBusy: waitForInSpotifyList.running

    property var _model

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: i18n.tr("Devices")
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageStack.pop()
            }
        ]
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Reload Devices")
                iconName: "reload"
                onTriggered: app.controller.reloadDevices()
            } //,
            /*Action {
                text: i18n.tr("Refresh Token")
                onTriggered: spotify.refreshToken()
            }*/
        ]
        flickable: listView
    }

    Component {
        id: contextMenu
        ActionSelectionPopover {
            id: actionSelectionPopover

            property var model

            actions: ActionList {
                Action {
                    text: i18n.tr("Set as Current")
                    onTriggered: {
                        console.log("set as current")
                        if(spotify) {
                        console.log("   IN")
                            app.setDevice(_model.deviceId, _model.name, function(error, data){
                                if(!error)
                                    devicesPage.refreshDevices()
                            })
                        } else
                          console.log("   NO")
                    }
                }
                /*menu: contextMenu

                        MenuItem {
                            enabled: sp === 0 && app.librespot.hasLibreSpotCredentials()
                            text: i18n.tr("Connect using Authorization Blob")
                            onClicked: {                            
                                var name = app.foundDevices[deviceIndex].remoteName
                                _toBeAddedName = name
                                app.librespot.addUser(app.foundDevices[deviceIndex], function(error, data) {
                                    if(data) {
                                        waitForInSpotifyList.count = 5
                                    } else {
                                        app.showErrorMessage(error, i18n.tr("Failed to connect to " + name))
                                    }
                                })
                            }
                        }
                    }
                }*/
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        spacing: units.dp(8)

        model: itemsModel

        delegate: ListItem {
            id: delegate
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            opacity: sp == 1 ? 1.0 : 0.4

            Column {
                id: column
                width: parent.width
                Text {
                    id: nameLabel
                    //color: is_active ? Theme.highlightColor : Theme.primaryColor
                    font.weight: is_active ? app.fontHighlightWeight : app.fontPrimaryWeight
                    textFormat: Text.StyledText
                    text: getNameLabelText(sp, deviceIndex, name)
                }
                Text {
                    id: meta1Label
                    width: parent.width
                    //color: is_active ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.weight: is_active ? app.fontHighlightWeight : app.fontPrimaryWeight
                    text: getMetaLabelText(sp, deviceIndex)
                }
            }

            onPressAndHold: {
                _model = model
                PopupUtils.open(contextMenu, delegate)
            }
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    function isDeviceInList(deviceName) {
        var i
        for(i=0;i<app.controller.devices.count;i++) {
            var device = app.controller.devices.get(i)
            if(device.name === deviceName)
                return true
        }
        return false
    }

    property string _toBeAddedName: ""
    Timer {
        id: waitForInSpotifyList
        interval: 2000
        running: count > 0
        repeat: true
        property int count: -1
        onTriggered: {
            if(isDeviceInList(_toBeAddedName))
                count = 0
            else
                app.controller.reloadDevices()
            count--
        }
    }

    function getNameLabelText(sp, deviceIndex, name) {
        var str = name ? name : i18n.tr("Unknown Name")
        if(sp) {
            str += ", " + app.controller.devices.get(deviceIndex).type
            //str += " [Spotify]"
        } else { //if(discovery) {
            str += ", " + app.foundDevices[deviceIndex].deviceType
            //str += " [Discovery]"
        }
        return str
    }

    function getMetaLabelText(sp, deviceIndex) {
        var str = ""
        if(sp) {
            var device = app.controller.devices.get(deviceIndex)
            str = device.volume_percent + "%"
            str += ", "
            str += device.is_active
                    ? i18n.tr("active") : i18n.tr("inactive")
            str += ", "
            str += device.is_restricted
                    ? i18n.tr("restricted") : i18n.tr("unrestricted")
            return str
        } else {
            str = app.foundDevices[deviceIndex].activeUser.length > 0
                    ? i18n.tr("inactive") : i18n.tr("inactive")
        }
        return str
    }

    Connections {
        target: app.controller
        onDevicesReloaded: refreshDevices()
    }

    Connections {
        target: app
        onDevicesChanged: refreshDevices()
        onHasValidTokenChanged: refreshDevices()
    }

    ListModel {
        id: itemsModel
    }

    Timer { // reload devices list so we see new ones
        id: reloadDevicesTimer
        running: !waitForInSpotifyList.running
        repeat: true
        interval: 3000
        onTriggered: app.controller.checkForNewDevices()
    }

    function refreshDevices() {
        var i
        var j

        itemsModel.clear()

        var devArr = []
        for(i=0;i<app.controller.devices.count;i++)
            devArr[i] = {device: app.controller.devices.get(i), deviceIndex: i}
        devArr.sort(function(a,b) {return a.device.name.localeCompare(b.device.name)})
        for(i=0;i<devArr.length;i++) {
            var item = devArr[i]
            itemsModel.append({deviceId: item.device.id,
                               name: item.device.name,
                               deviceIndex: item.deviceIndex,
                               is_active: item.device.is_active,
                               sp: 1,
                               discovery: 0})
        }

        devArr.length = 0
        for(i=0;i<app.foundDevices.length;i++)
            devArr[i] = {device: app.foundDevices[i], deviceIndex: i}
        devArr.sort(function(a,b) {return a.device.remoteName.localeCompare(b.device.remoteName)})
        for(i=0;i<devArr.length;i++) {
            var found = 0
            for(j=0;j<itemsModel.count;j++) {
                if(itemsModel.get(j).name === devArr[i].device.remoteName) {
                    itemsModel.get(j).discovery = 1
                    found = 1
                    break
                }
            }
            if(!found) {
                itemsModel.append({deviceId: devArr[i].device.deviceID,
                                   name: devArr[i].device.remoteName,
                                   deviceIndex: devArr[i].deviceIndex,
                                   is_active: devArr[i].device.activeUser.length > 0,
                                   sp: 0,
                                   discovery: 1})
            }
        }


    }

    Rectangle {
        id: controlPanel
        x: 0
        y: parent.height - height // - app.dockedPanel.visibleSize
        width: parent.width
        height: volumeSlider.height

        Image {
            id: speakerIcon
            x: app.paddingMedium
            source: volumeSlider.value <= 0 ? "image://theme/audio-speakers-muted-symbolic" : "image://theme/audio-speakers-symbolic"
            anchors.verticalCenter: parent.verticalCenter
            sourceSize {
                width: app.iconSizeMedium
                height: app.iconSizeMedium
            }
            height: app.iconSizeMedium
        }

        Slider {
            id: volumeSlider
            anchors {
                left: speakerIcon.right
                right: parent.right
            }
            minimumValue: 0
            maximumValue: 100
            enabled: app.controller.playbackState.device.id != -1
            //value: app.controller.playbackState.device.volume_percent
            onTouched: {
                Spotify.setVolume(Math.round(value), function(error, data) {
                    if(!error)
                        app.controller.refreshPlaybackState();
                })
            }
            Connections {
                target: app.controller.playbackState
                onDeviceChanged: volumeSlider.value = app.controller.playbackState.device.volume_percent
            }
        }
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refreshDevices()
    }

}

