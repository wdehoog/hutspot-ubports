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
    id: searchQueries

    property string label: ""
    property var selectedItem
    property int currentIndex: -1

    header: PageHeader {
        id: header
        contents: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Search Query History")
        }
        trailingActionBar.actions: [
            Action {
                iconName: "delete"
                text: i18n.tr("Clear")
                onTriggered: {
                    app.showConfirmDialog(
                        i18n.tr("Do you really want to delete all Search Queries?"),
                        function() {
                            app.settings.searchHistory = []
                            refresh()
                        })
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


            leadingActions: ListItemActions {
                actions: [
                    Action {
                        id: swipeDeleteAction
                        objectName: "swipeDeleteAction"
                        text: i18n.tr("Delete")
                        iconName: "delete"
                        onTriggered: {
                            var i = index
                            items.remove(i)
                            removeFromSearchHistory(i)
                        }
                    }
                ]
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.StyledText
                width: parent.width
                text: query
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
        var data = JSON.parse(app.settings.searchHistory)
        for(var i=0;i<data.length;i++) 
            items.append({query: data[i]})
    }

    function removeFromSearchHistory(index) {
        var sh = JSON.parse(app.settings.searchHistory)

        if(index === 0)
          sh.shift()
        else if(index === (sh.length-1))
          sh.pop()
        else    
          sh.splice(index, 1)

        app.settings.searchHistory = JSON.stringify(sh)
    }
}

