import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebEngine 1.7

import "Spotify.js" as Spotify
import "Util.js" as Util

import "components"
import "pages"

MainView {
    id: app
    
    property alias settings: settings

    property double paddingSmall: units.gu(0.5)
    property double paddingMedium: units.gu(1)
    property double paddingLarge: units.gu(2)

    property double iconSizeMedium: units.gu(4)

    objectName: 'mainView'
    applicationName: 'hutspot.wdehoog'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)
    
    PageStack {
        id: pageStack
        anchors.fill: parent
    }

    function loadFirstPage() {
        var pageUrl = undefined
        /*switch(firstPage.value) {
        default:
        case "PlayingPage":
            // when not having the Playing page as attached page
            if(!playing_as_attached_page.value)
                pageUrl = Qt.resolvedUrl("pages/Playing.qml")
            else
                pageUrl = Qt.resolvedUrl("pages/MyStuff.qml")
            break;
        case "NewReleasePage":
            pageUrl = Qt.resolvedUrl("pages/NewAndFeatured.qml")
            break;
        case "MyStuffPage":
            pageUrl = Qt.resolvedUrl("pages/MyStuff.qml")
            break;
        case "TopStuffPage":
            pageUrl = Qt.resolvedUrl("pages/TopStuff.qml")
            break;
        case "SearchPage":
            pageUrl = Qt.resolvedUrl("pages/Search.qml")
            break;
        case 'GenreMoodPage':
            pageUrl = Qt.resolvedUrl("pages/GenreMood.qml")
            break;
        case 'HistoryPage':
            pageUrl = Qt.resolvedUrl("pages/History.qml")
            break;
        case 'RecommendedPage':
            pageUrl = Qt.resolvedUrl("pages/Recommended.qml")
            break;
        }*/
        pageUrl = Qt.resolvedUrl("pages/Menu.qml")
        if(pageUrl !== undefined ) {
            pageStack.clear()
            pageStack.push(Qt.resolvedUrl(pageUrl))
        }
    }

    // when using menu dialog
    function doSelectedMenuItem(selectedIndex) {
        switch(selectedIndex) {
        case Util.HutspotMenuItem.ShowPlayingPage:
            app.showPage('PlayingPage')
            break
        case Util.HutspotMenuItem.ShowNewReleasePage:
            app.showPage('NewReleasePage')
            break
        case Util.HutspotMenuItem.ShowMyStuffPage:
            app.showPage('MyStuffPage')
            break
        case Util.HutspotMenuItem.ShowTopStuffPage:
            app.showPage('TopStuffPage')
            break
        case Util.HutspotMenuItem.ShowGenreMoodPage:
            app.showPage('GenreMoodPage')
            break
        case Util.HutspotMenuItem.ShowHistoryPage:
            app.showPage('HistoryPage')
            break
        case Util.HutspotMenuItem.ShowRecommendedPage:
            app.showPage('RecommendedPage')
            break
        case Util.HutspotMenuItem.ShowSearchPage:
            app.showPage('SearchPage')
            break
        case Util.HutspotMenuItem.ShowDevicesPage:
            pageStack.push(Qt.resolvedUrl("pages/Devices.qml"))
            break
        case Util.HutspotMenuItem.ShowSettingsPage:
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
            break
        case Util.HutspotMenuItem.ShowAboutPage:
            pageStack.push(Qt.resolvedUrl("pages/About.qml"))
            break;
        case Util.HutspotMenuItem.ShowHelp:
            Qt.openUrlExternally("http://sailfish-spotify.github.io/hutspot/")
            break;
        }
    }

    function showPage(pageName) {
        var page
        switch(pageName) {
        case 'PlayingPage':
            // when not having the Playing page as attached page
            // pop all pages above playing page or add it
            var pPage = pageStack.find(function(page) {
                return page.objectName === "PlayingPage"
            })
            if(pPage !== null)
                pageStack.pop(pPage)
            else
                pageStack.push(playingPage)
            break;
        case 'NewReleasePage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/NewAndFeatured.qml"))
            break;
        case 'MyStuffPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/MyStuff.qml"))
            break;
        case 'TopStuffPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/TopStuff.qml"))
            break;
        case 'SearchPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/Search.qml"))
            break;
        case 'GenreMoodPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/GenreMood.qml"))
            break;
        case 'HistoryPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/History.qml"))
            break;
        case 'RecommendedPage':
            //pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/Recommended.qml"))
            break;
        default:
            return
        }
        //if(playing_as_attached_page.value)
        //    pageStack.pushAttached(playingPage)
        //firstPage.value = pageName
    }

    Component.onCompleted: {
        startSpotify()
    }

    function startSpotify() {
        if (!spotify.isLinked()) {
            spotify.doO2Auth(Spotify._scope, false /*auth_using_browser.value*/)
        } else {
            var now = new Date ()
            console.log("Currently it is " + now.toDateString() + " " + now.toTimeString())
            var tokenExpireTime = spotify.getExpires()
            var tokenExpireDate = new Date(tokenExpireTime*1000)
            console.log("Current token expires on: " + tokenExpireDate.toDateString() + " " + tokenExpireDate.toTimeString())
            // do not set the 'global' hasValidToken since we will refresh anyway
            // and that will interfere
            var hasValidToken = tokenExpireDate > now
            console.log("Token is " + hasValidToken ? "still valid" : "expired")

            // with Spotify's stupid short living tokens, we can totally assume
            // it's already expired
            spotify.refreshToken();
        }
    }

    property int tokenExpireTime: 0 // seconds from epoch
    property bool hasValidToken: false

    Connections {
        target: spotify

        onExtraTokensReady: { // (const QVariantMap &extraTokens);
            // extraTokens
            //   scope: ""
            //   token_type: "Bearer"
        }

        onLinkingFailed: {
            console.log("Connections.onLinkingFailed")
            //app.connectionText = qsTr("Disconnected")
        }

        onLinkingSucceeded: {
            console.log("Connections.onLinkingSucceeded")
            //console.log("username: " + spotify.getUserName())
            //console.log("token   : " + spotify.getToken())
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            tokenExpireTime = spotify.getExpires()
            var date = new Date(tokenExpireTime*1000)
            console.log("expires on: " + date.toDateString() + " " + date.toTimeString())
            //app.connectionText = qsTr("Connected")
            //loadUser()
            loadFirstPage()
        }

        onLinkedChanged: {
            console.log("Connections.onLinkingChanged")
        }

        onRefreshFinished: {
            console.log("Connections.onRefreshFinished error code: " + errorCode +", msg: " + errorString)
            if(errorCode !== 0) {
                showErrorMessage(errorString, qsTr("Failed to Refresh Authorization Token"))
            } else {
                console.log("expires: " + tokenExpireTime)
                tokenExpireTime = spotify.getExpires()
                var expDate = new Date(tokenExpireTime*1000)
                console.log("expires on: " + expDate.toDateString() + " " + expDate.toTimeString())
                var now = new Date()
                hasValidToken = expDate > now
            }
        }

        onOpenBrowser: {
           console.log("onOpenBrowser: " + url)
           //if(settings.authUsingBrowser) {
           //    Qt.openUrlExternally(url)
           //} else {
               pageStack.push(Qt.resolvedUrl("pages/Menu.qml"))
               pageStack.push(Qt.resolvedUrl("pages/WebAuth.qml"), {authURL: url })
           //}
        }

        onCloseBrowser: {
            //loadFirstPage()
        }
    }

    property alias controller: spotifyController
    SpotifyController {
        id: spotifyController
    }

    property alias spotifyDataCache: spotifyDataCache
    SpotifyDataCache {
        id: spotifyDataCache
    }

    property var foundDevices: []     // the device info queried by getInfo
    property var connectDevices: ({}) // the device info discovered by mdns

    signal devicesChanged()

    onDevicesChanged: {        
        // for logging Librespot discovery
        var ls = isLibrespotInDiscoveredList()
        if(ls !== null) {
            if(logging_flags.discovery)console.log("onDevicesChanged: " + (ls!==null)?"Librespot is discovered":"not yet")
            if(!isLibrespotInDevicesList()) {
                if(logging_flags.discovery)console.log("Librespot is not in the devices list")
                // maybe the list needs to be updated
                if(hasValidToken)
                    spotifyController.checkForNewDevices()
            } else {
                if(logging_flags.discovery)console.log("Librespot is already in the devices list")
            }
        }
        //handleCurrentDevice()
    }

    Settings {
        id: settings

        property int searchLimit: 50
        property int sorted_list_limit: 1000

        property int currentItemClassMyStuff: 0

        property bool authUsingBrowser: true
    }
}
