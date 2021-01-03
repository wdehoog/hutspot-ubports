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

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: genreMoodPage
    objectName: "RecommendationsPage"

    property bool showBusy: false

    property int currentIndex: -1

    ListModel {
        id: recommendationsModel
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Recommendations")
        flickable: listView
        trailingActionBar.actions: [
            Action {
                text: i18n.tr("Add New")
                iconName: "add"
                onTriggered: addNewSet()
            }
        ]
    }

    property alias contextMenu: contextMenu

    Item {
        id: contextMenu
        property var model

        function open(theModel, item) {
            model = theModel
            PopupUtils.open(popup, item)
        }

        Component {
            id: popup
            ContextMenuPopover {

                actions: ActionList {
                    Action {
                        property int idx: 0
                        text: i18n.tr("Play")
                        onTriggered: playSet(contextMenu.model)
                    }
                    Action {
                        property int idx: 1
                        text: i18n.tr("Rename")
                        onTriggered: renameSet(contextMenu.model)
                    }
                    Action {
                        property int idx: 2
                        text: i18n.tr("Edit")
                        onTriggered: editSet(contextMenu.model)
                    }
                    Action {
                        property int idx: 3
                        text: i18n.tr("Delete")
                        onTriggered: deleteSet(contextMenu.model)
                    }
                }
            }
        }
    }

    ListView {
        id: listView
        model: recommendationsModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height


        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            /*Image {
                id: categoryIcon
                height: parent.height - app.paddingSmall
                width: height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: category.icons[0].url
            }*/

            Column {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    elide: Text.ElideRight
                    text: recommendationSet.name
                }
                Label {
                    text: i18n.tr("#seeds: %1, use attributes: %2".arg(recommendationSet.seeds.length).arg(recommendationSet.use_attributes? i18n.tr("yes") : i18n.tr("no") ))
                }
            }

            onClicked: editSet(model)
            onPressAndHold: contextMenu.open(model, listItem)
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    function refresh() {
        recommendationsModel.clear()
        loadRecommendationsData(app.settings.recommendationsData)
    }

    function loadRecommendationsData(recommendationsData) {
        //console.log("load: " + recommendationsData)
        var rs = JSON.parse(recommendationsData)
        if(!Util.isArray(rs)) {
            app.showErrorMessage(undefined, "Invalid Recommendations Data")
            return
        }

        var i
        for(i=0;i<rs.length;i++) {
            recommendationsModel.append({recommendationSet: rs[i]})
        }
    }

    function loadFromsettings() {
        var rs = JSON.parse(app.settings.recommendationsData)
        for(var i=0;i<rs.length;i++)
            recommendationsModel.append({recommendationSet: rs[i]})
    }

    function saveTosettings() {
        var rs = [recommendationsModel.count]
        for(var i=0;i<recommendationsModel.count;i++)
            rs[i] = recommendationsModel.get(i).recommendationSet
        //console.log("save: " + JSON.stringify(rs))
        app.settings.recommendationsData = JSON.stringify(rs)
    }

    function addNewSet() {
        var rs = {
            name: "New Recommendations",
            seeds: [],
            attributes: [],
            use_attributes: false
        }
        recommendationsModel.append({recommendationSet: rs})
        saveTosettings()
    }

    function deleteSet(model) {
        app.showConfirmDialog(i18n.tr("Do you want to delete<br>%1?".arg(model.recommendationSet.name)),
            function() {
                recommendationsModel.remove(model.index)
                saveTosettings()
            }
        )
    }

    function editSet(model) {
        var index = model.index
        var page = app.pageStack.push(Qt.resolvedUrl("Recommended.qml"))
        page.setRecommendationData(model.recommendationSet)
        page.closed.connect(function() {
            var rs = page.recommendationData.getSaveData()
            recommendationsModel.remove(index, 1)
            recommendationsModel.insert(index, {recommendationSet: rs})
            saveTosettings()
        })
    }

    function renameSet(model) {
        var dialog = PopupUtils.open(renameDialog)
        dialog.oldName = model.recommendationSet.name
        dialog.recommendationSet = model.recommendationSet
        dialog.index = model.index
    }

    Component {
        id: renameDialog

        Dialog {
            id: dialogRename
            title: i18n.tr("Rename")

            property string oldName: ""
            property var recommendationSet
            property var index

            TextField {
                id: newName
                inputMethodHints: Qt.ImhNoPredictiveText
                text: oldName
            }

            Button {
                text: i18n.tr("Change")
                enabled: newName.text.length > 0
                onClicked: {
                    recommendationSet.name = newName.text

                    // these do not work
                    //recommendationsModel.set(index, recommendationSet)
                    //recommendationsModel.get(index).recommendationSet.name = newName.text

                    // this gives an error but does work
                    //recommendationsModel.setProperty(index, "recommendationSet", recommendationSet)
                    // this works
                    recommendationsModel.remove(index, 1)
                    recommendationsModel.insert(index, {recommendationSet: recommendationSet})

                    saveTosettings()
                    PopupUtils.close(dialogRename)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogRename)
            }
            Component.onCompleted: newName.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        loadFromsettings()
    }
}
