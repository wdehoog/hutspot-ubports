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
    id: artistPicker

    signal accepted()

    property string label: ""
    property var selectedItem
    property var artists
    property int currentIndex: -1

    header: PageHeader {
        id: header
        contents: Label {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Select Artist")
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
                    pageStack.pop()
                    accepted()
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

            onClicked: {
                selectedItem = items.get(index)
                currentIndex = index
            }

            SearchResultListItem {
                id: searchResultListItem
                anchors.verticalCenter: parent.verticalCenter
                dataModel: model
            }
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: listView
        anchors.right: parent.right
    }

    onLabelChanged: refresh() // ToDo come up with a better trigger

    function refresh() {
        items.clear()
        for (var i=0;i<artists.length;i++) {
            items.append({type: 1,
                          stype: 0,
                          name: artists[i].name,
                          item: artists[i]});
        }
    }

}

