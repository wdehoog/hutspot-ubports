/**
 * Copyright (C) 2019 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQuick 2.2

import "../Util.js" as Util

Page {

    objectName: "MenuPage"

    property bool popOnExit: true
    property int selectedMenuItem: -1
    property int _currentIndex: -1
    property bool _started: false

    anchors.fill: parent

    header: PageHeader {
        title: i18n.tr("Hutspot") 
        flickable: listView

        trailingActionBar.actions: [
            Action {
                iconName: "help"
                text: i18n.tr("Help")
                onTriggered: Qt.openUrlExternally("https://wdehoog.github.io/hutspot-ut")
            },
            Action {
                iconName: "info"
                text: i18n.tr("About")
                onTriggered: app.doSelectedMenuItem(Util.HutspotMenuItem.ShowAboutPage)
            },
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: app.doSelectedMenuItem(Util.HutspotMenuItem.ShowSettingsPage)
            }
        ]
    }

    ListModel {
        id: menuModel
    }

    Component.onCompleted: {
        /*if(!app.playing_as_attached_page.value)
            menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowPlayingPage,
                              name: i18n.tr("Playing"),
                              icon: "image://theme/icon-m-music"
                             })*/
        /*menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowNewReleasePage,
                          name: i18n.tr("New & Featured"),
                          icon: "image://theme/icon-m-health"
                         })*/
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowLibraryPage,
                          name: ("Library"),
                          icon: "image://theme/view-list-symbolic"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowTopStuffPage,
                          name: i18n.tr("Top"),
                          icon: "image://theme/unlike"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowRecommendedPage,
                          name: i18n.tr("Recommended"),
                          icon: "image://theme/thumb-up"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowGenreMoodPage,
                          name: i18n.tr("Genre & Mood"),
                          icon: "image://theme/weather-app-symbolic",
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowSearchPage,
                          name: i18n.tr("Search"),
                          icon: "image://theme/toolkit_input-search"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowHistoryPage,
                          name: i18n.tr("History"),
                          icon: "image://theme/history"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowDevicesPage,
                          name: i18n.tr("Devices"),
                          icon: "image://theme/audio-speakers-symbolic",
                          name: "devices"
                                //"image://theme/audio-volume-muted-blocking-panel"
                         })
        /*menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowSettingsPage,
                          name: i18n.tr("Settings"),
                          icon: "image://theme/icon-m-developer-mode"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowHelp,
                          name: i18n.tr("Help"),
                          icon: "image://theme/icon-m-question"
                         })
        menuModel.append({hutspotMenuItem: Util.HutspotMenuItem.ShowAboutPage,
                          name: i18n.tr("About"),
                          icon: "image://theme/icon-m-about"
                         })*/
    }

    ListView {
        id: listView
        model: menuModel

        anchors.fill: parent

        delegate: ListItem {
            width: parent.width - 2 * app.paddingLarge
            x: app.paddingLarge

            Image {
                id: image
                width: app.iconSizeMedium
                height: width
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: model.icon
            }

            Colorize {
                visible: name == "devices" && !app.controller.hasCurrentDevice
                anchors.fill: image
                source: image
                hue: 0.0
                saturation: 1.0
                lightness: -0.2
            }

            Text {
                anchors.left: image.right
                anchors.leftMargin: app.paddingLarge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                //color: _currentIndex === index ? Theme.highlightColor : Theme.primaryColor
                text: model.name
            }

            MouseArea {
                anchors.fill: parent
                onPressed: _currentIndex = index
                onReleased:  _currentIndex = 0
                onClicked: {
                    selectedMenuItem = model.hutspotMenuItem
                    closeIt()
                }
            }

        }
    }
    
    function closeIt() {
        // we want the dialog to be removed from the page stack before
        // the caller acts.
        //if(popOnExit)
        //    pageStack.popAttached(undefined, PageStackAction.Immediate)
        app.doSelectedMenuItem(selectedMenuItem)
    }
}
