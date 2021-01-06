/**
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Ubuntu.Content 1.3

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: recommendedPage
    objectName: "RecommendedPage"

    property bool showBusy: false
    property int currentIndex: -1
    property bool expandAttributes: false

    property alias recommendationData: recommendationData 
    RecommendationData {
        id: recommendationData
        onAttributesChanged: refresh()
        onSeedsChanged: refresh()
        onReset: {
            // seeds model is already updated so we only need to update the sliders
            // too bad itemAtIndex is not in Qt 5.12
            /*var i
            for(i=0;i<recommendationData.attributesModel.count;i++) {
                var attribute = recommendationData.attributesModel.get(i)
                var item = listView.itemAtIndex(i)
                item.slider.value = attribute.value
            }*/
        }
    }

    ListModel {
        id: searchModel
    }

    signal closed()

    header: PageHeader {
        id: header
        title: i18n.tr("Recommended")
        subtitle: recommendationData.name
        flickable: listView
        leadingActionBar.actions: [
            Action { // copied from PageHeader
                iconName: Qt.application.layoutDirection == Qt.RightToLeft ? "next": "back"
                text: i18n.tr("Back")
                onTriggered: {
                    closed()
                    pageStack.pop()
                }
            }
        ]
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add Genre")
                iconName: "tag"
                onTriggered: selectGenreSeed()
            },
            Action {
                text: i18n.tr("Reload")
                iconName: "reload"
                enabled: searchModel.count > 0
                onTriggered: refresh()
            },
            Action {
                text: i18n.tr("Import into Playlist")
                iconName: "import"
                enabled: searchModel.count > 0
                onTriggered: importIntoPlaylist()
            },
            Action {
                text: i18n.tr("Save")
                iconName: "document-save"
                onTriggered: saveSeedsAndAttributes()
            },
            Action {
                text: i18n.tr("Load")
                iconName: "document-open"
                onTriggered: loadSeedsAndAttributes()
            },
            Action {
                text: i18n.tr("Reset")
                iconName: "reset"
                onTriggered: resetSeedsAndAttributes()
            }
        ]
    }

    Component {
        id: headerComponent
        Column {

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            anchors.bottomMargin: app.paddingLarge
            spacing: app.paddingLarge

            Label {
                text: i18n.tr("Seeds")
                font.weight: app.fontHighlightWeight
                anchors.right: parent.right
            }

            ListView {
                id: seedListView
                width: parent.width
                implicitHeight: contentItem.childrenRect.height

                model: recommendationData.seedModel

                delegate: ListItem {
                    height: app.itemSizeMedium
                    Row {
                        id: row
                        width: parent.width
                        spacing: app.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter

                        /*Image {
                            id: image
                            width: height
                            height: column.height
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            source: image
                        }*/

                        Text {
                            width: parent.width - parent.spacing - clearButton.width
                            anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.StyledText
                            font.weight: app.fontPrimaryWeight
                            //truncationMode: TruncationMode.Fade
                            horizontalAlignment: type >= 0 ? Text.AlignLeft : Text.AlignHCenter
                            text: type >= 0
                                  ? recommendationData.getSeedTypeString(type) + ": " + name
                                  : i18n.tr("Empty Seed Slot")
                        }
                        Icon {
                            id: clearButton
                            width: app.iconSizeMedium
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            //color: app.normalBackgroundColor
                            name: "edit-clear"
                            visible: type >= 0
                            MouseArea {
                                anchors.fill: parent
                                onClicked: deleteSlot(model)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: app.dividerHeight
                color: app.dividerColor
            }

            Item {
                width:  parent.width // childrenRect.width
                height: childrenRect.height

                Row {
                    anchors.left: parent.left
                    height: childrenRect.height
                    spacing: app.paddingSmall

                    CheckBox {
                        checked: recommendationData.useAttributes
                        onClicked: recommendationData.useAttributes = checked
                    }
                    Label {
                        id: useAttrLabel
                        text: i18n.tr("Use")
                    }
                }

                MouseArea {
                    width:  childrenRect.width
                    height: childrenRect.height
                    anchors.right: parent.right
                    Row {
                        anchors.right: parent.right
                        height: hl.height
                        spacing: app.paddingMedium
                        Label {
                            id: hl
                            font.weight: app.fontHighlightWeight
                            anchors.verticalCenter: parent.verticalCenter
                            text: i18n.tr("Attributes")
                        }
                        Icon {
                            id: hi
                            width: app.iconSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                            name: expandAttributes ? "up" : "down"
                        }
                    }
                    onClicked: {
                        expandAttributes = !expandAttributes
                    }
                }
            }

            ListView {
                id: listView
                width: parent.width
                implicitHeight: expandAttributes ? contentItem.childrenRect.height : 0
                visible: expandAttributes

                model: recommendationData.attributesModel

                delegate: ListItem {
                    width: parent.width

                    Column {
                      id: lab
                      width: parent.width * 0.25
                      anchors.verticalCenter: parent.verticalCenter
                      Label {
                          anchors.left: parent.left
                          text: recommendationData.getLabelText(attribute)
                      }
                      Label {
                          anchors.left: parent.left
                          text: {
                            if(dtype === "int")
                                Math.round(slider.value)
                            else  
                                slider.value.toPrecision(2)
                          }
                      }
                    }

                    Slider {
                        id: slider
                        width: parent.width - lab.width - app.paddingMedium
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        minimumValue: min
                        maximumValue: max
                        live: true
                        onPressedChanged: {
                            if(pressed)
                              return
                            model.value = slider.value
                            recommendationData.setAttributeValue(attribute, model.value)
                        }
                        Component.onCompleted: slider.value = model.value
                        Connections {
                            target: recommendationData
                            onReset: slider.value = model.value
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: app.dividerHeight
                color: app.dividerColor
            }

            Label {
                text: i18n.tr("Recommendations")
                font.weight: app.fontHighlightWeight
                anchors.right: parent.right
            }
        }
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        height: parent.height

        header: headerComponent

        delegate: ListItem {
            id: listItem
            width: parent.width - 2 * app.paddingMedium
            x: app.paddingMedium

            SearchResultListItem {
                id:trackListItem
                dataModel: model
                isFavorite: saved
                //onToggleFavorite: app.toggleSavedTrack(model)
            }

            /*onPressAndHold: {
                contextMenu.model = model
                contextMenu.context = album
                PopupUtils.open(contextMenu, listItem)
            }*/

            //onClicked: controller.playTrackInContext(item, album, index)
        }

        onAtYEndChanged: {
            if(listView.atYEnd && searchModel.count > 0)
                append()
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    Connections {
        target: app
        onHasValidTokenChanged: if(app.hasValidToken) refresh()
    }

    /*Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }*/

    function refresh() {
        console.log("Recommended.refresh")
        //showBusy = true
        searchModel.clear()
        append()
    }

    property bool _loading: false

    function append() {
        var i

        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        recommendedPage._loading = true

        var options = {offset: searchModel.count, limit: cursorHelper.limit}
        options = recommendationData.addQueryOptions(options)
        if(app.settings.queryForMarket)
            options.market = "from_token"

        console.log(JSON.stringify(options))

        Spotify.getRecommendations(options, function(error, data) {
            if(data) {
                try {
                    //console.log("number of Recommendations: " + data.tracks.length)
                    app.loadTracksInModel(data, data.tracks.length, searchModel, function(data, i) {return data.tracks[i]})
                } catch (err) {
                    console.log(err)
                }
            } else
                console.log("No Data for getRecommendations")
            recommendedPage._loading = false
        })

    }

    function setRecommendationData(data) {
        recommendationData.loadData(data)
        refresh()
    }

    function selectGenreSeed() {
        var ms = pageStack.push(Qt.resolvedUrl("../components/GenrePicker.qml"),
                                { label: i18n.tr("Select a Genre") } );
        ms.accepted.connect(function() {
            if(ms.selectedItem && ms.selectedItem.name) {
                recommendationData.addGenre(ms.selectedItem.name)
            }
        })
    }

    function deleteSlot(model) {
        app.showConfirmDialog(i18n.tr("Do you want to remove %1?").arg(model.name), function() {
               recommendationData.clearSlot(model.index) 
        })
    }

    function importIntoPlaylist() {
        if(searchModel.count <= 0)
            return
        app.showConfirmDialog(i18n.tr("Do you want to replace the tracks in the Hutspot Recommendations playlist with these results?"),
            function() {
                var uris = [searchModel.count]
                for(var i=0;i<searchModel.count;i++)
                    uris[i] = searchModel.get(i).item.uri
                var info = {}
                info.name = "Recommendations [hutspot]"
                info.description = i18n.tr("Playlist for Hutspot to store recommended tracks")
                info.usage = i18n.tr("store recommended tracks")
                app.replaceTracksInHutspotPlaylist(info, uris, function() {
                    app.showConfirmDialog(
                        i18n.tr("Replacing tracks succeeded. Do you want to start playing %1?").arg(playlistInfo.name),
                        function(info) { app.ensurePlaylistIsPlaying(info) }
                    )
                })
            }
        )
    }

    function resetSeedsAndAttributes() {
        app.showConfirmDialog(i18n.tr("Do you want to reset all Recommendations Seeds and Attributes?"),
            function() { recommendationData.resetValues() }
        )
    }

    function saveSeedsAndAttributes() {
        var saveData = JSON.stringify(recommendationData.getSaveData())
        var page = app.pageStack.push(Qt.resolvedUrl("../components/ExportRecommendationsDataPage.qml"), {saveData: saveData})
    }

    function loadSeedsAndAttributes() {
        var page = app.pageStack.push(Qt.resolvedUrl("../components/ImportRecommendationsDataPage.qml"))
        page.imported.connect(function(data) {
            //console.log("imported: " + data)
            var saveData = JSON.parse(data)
            pageStack.pop()
            recommendationData.loadSaveData(data)
        })
    }

}
