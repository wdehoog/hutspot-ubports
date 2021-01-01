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

import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: itemPicker

    signal accepted()

    property string label: ""
    property var selectedItem

    property int currentIndex: -1

    header: PageHeader {
        id: header
        contents: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Select Genre")
        }
        leadingActionBar.actions: [
            Action {
                iconName: "cancel"
                text: i18n.tr("Cancel")
                onTriggered: pageStack.pop()
            }
        ]
        trailingActionBar.actions: [
            Action {
                iconName: "ok"
                text: i18n.tr("Select")
                enabled: currentIndex != -1
                onTriggered: {
                    accepted()
                    pageStack.pop()
                }
            }
        ]
        flickable: listView
    }

    ListModel { id: items }

    ListView {
        id: listView

        anchors.fill: parent
        model: items

        delegate: ListItem {
            id: delegateItem

            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium

            Label {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                //color: Theme.primaryColor
                font.weight: currentIndex === index ? app.fontHighlightWeight : app.fontPrimaryWeight
                elide: Text.ElideRight
                text: name
            }

            onClicked: {
                selectedItem = items.get(index)
                currentIndex = index
            }
        }
 
        onAtYEndChanged: {
            if(listView.atYEnd && model.count > 0)
                append()
        }
    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    CursorHelper {
        id: cursorHelper
    }

    onLabelChanged: refresh() // ToDo come up with a better trigger

    function refresh() {
        items.clear()
        append()
    }

    property bool _loading: false

    function append() {
        // if already at the end -> bail out
        if(items.count > 0 && items.count >= cursorHelper.total)
            return

        // guard
        if(_loading)
            return
        _loading = true

        // load possible choices
        Spotify.getAvailableGenreSeeds(function(error, data) {
            if(data) {
                var i
                for(i=0;i<data.genres.length;i++)
                    items.append({id: i, name: data.genres[i]})
            } else
                console.log("getAvailableGenreSeeds returned no Genres")
            _loading = false
        })

    }
}

