import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import "../Util.js" as Util

Item {
    id: playerArea

    property string defaultImageSource : "image://theme/stock_music"

    property bool allowGoPlayingPage: true 
    property bool showHomeButton: true 

    width: parent.width
    height: app.itemSizeLarge

    Column {
        width: parent.width
        height: parent.height

        Rectangle { 
            width: parent.width
            height: 1
            color: "grey"
        }

        Rectangle {
            color: "darkgrey"
            width: app.controller.playbackState ? (parent.width * (app.controller.playbackState.progress_ms / app.controller.playbackState.item.duration_ms)) : 0
            height: app.paddingSmall
        }

        Item {
            id: row
            width: parent.width
            height: parent.height - app.paddingSmall
            property real itemWidth : width / 5

            // album art
            Item {
                id: imageItem
                width: height //row.itemWidth
                height: parent.height
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: app.controller.getCoverArt(defaultImageSource, true)
                    width: height
                    height: parent.height //* 0.9
                    fillMode: Image.PreserveAspectFit
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      if(allowGoPlayingPage)
                          app.doSelectedMenuItem(Util.HutspotMenuItem.ShowPlayingPage)
                    }
                }
            }

            Item {
                height: parent.height
                width: row.itemWidth * 3
                anchors {
                    left: imageItem.right
                    verticalCenter: parent.verticalCenter
                }

                Row {
                    id: playerButtons
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    // player controls
                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.itemWidth * 0.8
                        height: width
                        color: "white"
                        // enabled: app.mprisPlayer.canGoPrevious
                        action: Action {
                            iconName: "media-skip-backward"
                            onTriggered: app.controller.previous()
                        }
                    }
                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.itemWidth * 0.9
                        height: width
                        color: "white"
                        action: Action {
                            iconName: app.controller.playbackState.is_playing
                                         ? "media-playback-pause"
                                         : "media-playback-start"
                            onTriggered: app.controller.playPause()
                        }
                    }
                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.itemWidth * 0.8
                        height: width
                        color: "white"
                        action: Action {
                            iconName: "media-skip-forward"
                            onTriggered: app.controller.next()
                        }
                    }
                }
            }

            Button {
                id: playingButton
                width: row.itemWidth * 0.8
                height: width
                visible: showHomeButton
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                action: Action {
                    //iconName: "go-next"
                    iconName: "home"
                    onTriggered: app.goHome()
                }
            }

        }
    }

}

