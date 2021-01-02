/**
 * Copyright (C) 2018 Willem-Jan de Hoog
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
    objectName: "GenreMoodPage"

    property bool showBusy: false

    property int currentIndex: -1

    ListModel {
        id: searchModel
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Genres & Moods")
        flickable: listView
    }

    ListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        height: parent.height


        delegate: ListItem {
            id: listItem
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            //contentHeight: Theme.itemSizeLarge

            Image {
                id: categoryIcon
                height: parent.height - app.paddingSmall
                width: height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: category.icons[0].url
            }

            Label {
                id: categoryName
                anchors.left: categoryIcon.right
                anchors.right: parent.right
                anchors.leftMargin: app.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                //color: Theme.primaryColor
                elide: Text.ElideRight
                text: category.name
            }
            onClicked: app.pushPage(Util.HutspotPage.GenreMoodPlaylist, {category: category})
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

    function refresh() {
        //showBusy = true
        searchModel.clear()
        append()
    }

    property bool _loading: false

    function append() {
        // if already at the end -> bail out
        if(searchModel.count > 0 && searchModel.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        Spotify.getCategories({offset: searchModel.count, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    var i
                    //console.log("number of Categories: " + data.categories.items.length)
                    cursorHelper.offset = data.categories.offset
                    cursorHelper.total = data.categories.total
                    for(i=0;i<data.categories.items.length;i++) {
                        searchModel.append({category: data.categories.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getCategories")
            }
            _loading = false
        })

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper
    }

    Connections {
        target: app
        onHasValidTokenChanged: if(app.hasValidToken) refresh()
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }

}
