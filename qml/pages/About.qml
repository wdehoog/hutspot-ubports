/**
 * Hutspot. Copyright (C) 2019 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import QtQuick 2.2

Page {

    anchors.fill: parent

    header: PageHeader {
        id: header
        title: i18n.tr("About")
        flickable: flickable 
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageStack.pop()
            }
        ]
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        //contentHeight: column.height

        Column {
            id: column
            width: parent.width

            Rectangle {
                height: app.paddingLarge
                width: parent.width
                color: app.bgColor
            }

            Item {
                width: parent.width
                height: childrenRect.height

                UbuntuShape {
                    id: icon
                    width: units.gu(10)
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: "medium"
                    source: Image {
                        source: Qt.resolvedUrl("../resources/logo.svg")
                    }
                }

                Column {
                    id: appTitleColumn

                    anchors {
                        left: parent.left
                        leftMargin: app.paddingMedium
                        right: parent.right
                        rightMargin: app.paddingMedium
                        top: icon.bottom
                        topMargin: app.paddingMedium
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        //font.pixelSize: Theme.fontSizeLarge
                        text: "Hutspot " + app.version
                    }

                    Label {
                        horizontalAlignment: Text.AlignHCenter
                        text: i18n.tr("Spotify controller for Ubuntu Touch")
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        //font.pixelSize: Theme.fontSizeExtraSmall
                        //: I doubt this needs to be translated
                        text: i18n.tr("Copyright (C) 2021")
                        width: parent.width
                    }
                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        //font.pixelSize: Theme.fontSizeExtraSmall
                        text: i18n.tr("License: MIT")
                        width: parent.width
                    }
                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        //font.pixelSize: Theme.fontSizeExtraSmall
                        text: BUILD_DATE_TIME
                        width: parent.width
                    }

                }

            }

            Label {
                text: i18n.tr("Contributors")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: app.paddingMedium
                    right: parent.right
                    rightMargin: app.paddingMedium
                }
                //font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"Willem-Jan de Hoog"
            }

            Rectangle { 
                width: parent.width
                height: app.paddingLarge
                color: app.bgColor
            }

/*            Label {
                text: i18n.tr("Translations")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
""
            }*/

            Label {
                text: i18n.tr("Thanks to")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: app.paddingMedium
                    right: parent.right
                    rightMargin: app.paddingMedium
                }
                //font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"Maciej Janiszewski: co-author of Hutspot for SailfishOS 
Spotify: web api
librespot-org: Librespot
JMPerez: spotify-web-api-js
pipacs: O2
Whoever made: nemo-qml-plugin-dbus, qtmpris and qtdbusextended
nitroshare: qmdnsengine"

            }
        }

    }

    Scrollbar {
        id: scrollBar
        flickableItem: flickable
        anchors.right: parent.right
    }

}
