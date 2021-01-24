import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import "../Util.js" as Util

import "../components" as Hutspot

Item {
    id: playerArea

    property string defaultImageSource : "image://theme/stock_music"

    property var playbackState: app.controller.playbackState

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
            width: app.controller.playbackState.item
              ? (parent.width * (app.controller.playbackState.progress_ms / app.controller.playbackState.item.duration_ms))
              : 0
            height: app.paddingSmall
        }

        Row {
            id: playerUI

            width: parent.width
            height: parent.height

            // album art
            Item {
                id: imageItem
                width: height 
                height: parent.height
                anchors {
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

            Hutspot.SwipeArea {
                id: meta
                width: parent.width - imageItem.width - playerButton.width
                height: parent.height
                clip: true

                property int swipeX: 0
                property bool backAnimationEnabled: false
                property var flashButton

                Column {
                    id: info
                    x: meta.swipeX 
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        x: app.paddingSmall
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        color: app.primaryHighlightColor
                        text: getFirstLabelText()
                    }
                    Label {
                        x: app.paddingSmall
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        color: app.secondaryHighlightColor
                        text: getSecondLabelText()
                    }
                    Label {
                        x: app.paddingSmall
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        color: app.tertiaryHighlightColor
                        text: getThirdLabelText()
                    }

                }
                onSwipe: {
                    switch(direction) {
                        case "left":
                            if(!app.controller.playbackState.canGoNext)
                                return
                            meta.flashButton = nextButton
                            meta.swipeX = meta.width
                            app.controller.next()
                            break
                        case "right":
                            if(!app.controller.playbackState.canGoPrevious)
                                return
                            meta.flashButton = previousButton
                            meta.swipeX = -meta.width
                            app.controller.previous()
                            break
                    }
                    meta.backAnimationEnabled = true
                }
                onMove: {
                    meta.backAnimationEnabled = false
                    var newX = x
                    if(x < 0 && app.controller.playbackState.canGoNext)
                        meta.swipeX = x
                    if(x > 0 && app.controller.playbackState.canGoPrevious)
                        meta.swipeX = x
                }
                NumberAnimation on swipeX {
                    id: backToZero
                    running: meta.backAnimationEnabled
                    to: 0
                }
            }

            Item {
                width: app.iconSizeLarge
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Icon {
                    id: playerButton
                    width: parent.width
                    height: width
                    enabled: app.controller.playbackState.canPause
                             || app.controller.playbackState.canPlay
                    name: playbackState.is_playing
                                ? "media-preview-pause"
                                : "media-preview-start"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: app.controller.playPause()
                    }
                    opacity: 1
                }
                Icon {
                    id: nextButton
                    width: playerButton.width
                    height: width
                    x: playerButton.x
                    y: playerButton.y
                    name: "media-skip-forward"
                    opacity: 0
                }
                Icon {
                    id: previousButton
                    width: playerButton.width
                    height: width
                    x: playerButton.x
                    y: playerButton.y
                    name: "media-skip-backward"
                    opacity: 0
                }
            }

        }
    }

    function getFirstLabelText() {
        if(playbackState === undefined)
            return ""
        return playbackState.item ? playbackState.item.name : ""
    }

    function getSecondLabelText() {
        if(playbackState === undefined)
            return ""
        var s = ""
        if(playbackState.item && playbackState.item.album) {
            s += playbackState.item.album.name
            if (playbackState.item.album.release_date)
                s += ", " + Util.getYearFromReleaseDate(playbackState.item.album.release_date)
        } else if(playbackState.item && playbackState.item.show) {
            s += playbackState.item.show.name
            //if (playbackState.item.show.copyrights)
            //    s += ", " + playbackState.item.show.copyrights
        }
        return s
    }

    function getThirdLabelText() {
        var s = ""
        if(playbackState === undefined)
            return s
        // no context (a single track?)
        if(playbackState.item && playbackState.item.artists)
            s += Util.createItemsString(playbackState.item.artists, i18n.tr("no artist known"))
        else if(playbackState.item && playbackState.item.show)
            s += playbackState.item.show.publisher
        return s
    }

    /*function getLabelText(l0, l1) {
      var l = ""
      if(l0)
        l += l0
      if(l1) {
        if(l)
          l += " - "
        l += l1    
      }
      return l
    }*/
}

