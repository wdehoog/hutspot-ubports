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

Page {
    id: createPlaylist

    signal accepted()

    property string name: ""
    property bool publicPL: true
    property bool collaborativePL: false
    property string description: ""

    header: PageHeader {
        id: header
        contents: Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Create Playlist")
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
                enabled: name != ""
                onTriggered: {
                    accepted()
                    pageStack.pop()
                }
            }
        ]
        flickable: flickable
    }
    // unfortunately these do not work 
    // the header is not fixed and the text of the actions is not visible
    head.locked: true
    head.preset: "select"

    Flickable  {
        id: flickable

        anchors.fill: parent

        Column {
            id: column
            width: parent.width - 2*app.paddingMedium
            x: app.paddingMedium
            spacing: app.paddingMedium

            TextField {
                id: nameField
                width: parent.width
                placeholderText: i18n.tr("Name for the new playlist")
                onTextChanged: name = text
            }

            CheckBox {
                id: publicTS
                width: parent.width
                checked: true
                onCheckedChanged: {
                    publicPL = checked
                    if(checked) // a collaborative playlist cannot be public
                        collaborativeTS.checked = false
                }
                text: i18n.tr("Public")
            }

            CheckBox {
                id: collaborativeTS
                width: parent.width
                onCheckedChanged: {
                    collaborativePL = checked
                    if(checked) // a collaborative playlist cannot be public
                        publicTS.checked = false
                }
                text: i18n.tr("Collaborative")
            }

            TextField {
                id: descriptionField
                width: parent.width
                placeholderText: i18n.tr("Description (optional)")
                onTextChanged: description = text
            }
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: flickable
        anchors.right: parent.right
    }
}

