import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3

Page {
    id: settingsPage
    objectName: "SettingsPage"


    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Settings")
        flickable: flick
    }

    Flickable {
        id: flick
        anchors.fill: parent

        Column {
            id: column
            width: parent.width - 2*app.paddingMedium
            y: app.paddingLarge
            x: app.paddingMedium
            spacing: app.paddingLarge

            Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Confirm Un-Follow/Save")
                }
                CheckBox {
                    anchors.right: parent.right
                    checked: app.settings.confirmUnFollowSave
                    onCheckedChanged: app.settings.confirmUnFollowSave = checked
                }
            }
            Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Query for Market")
                    //description: qsTr("Show only content playable in the country associated with the user account")
                }
                CheckBox {
                    id: queryForMarket 
                    anchors.right: parent.right
                    checked: app.settings.queryForMarket
                    onCheckedChanged: app.settings.queryForMarket = checked
                }
            }

            /*Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Authorize using Browser")
                }
                CheckBox {
                    id: authUsingBrowser 
                    anchors.right: parent.right
                    checked: app.settings.authUsingBrowser
                    onCheckedChanged: app.settings.authUsingBrowser = checked
                }
            }*/

            Item {
                width: parent.width
                height: childrenRect.height 
                Label {
                    id: authUsingBrowserLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Authorize using")
                }

                ItemSelector {
                    id: authUsingBrowserSelector
                    anchors.right: parent.right
                    width: parent.width - authUsingBrowserLabel.width - app.paddingLarge
                    height: currentlyExpanded ? 2 * itemHeight : itemHeight

                    selectedIndex: app.settings.authUsingBrowser ? 1 : 0 
                    onDelegateClicked: {
                        app.settings.authUsingBrowser = index == 1
                        console.log("new authUsingBrowser: " + app.settings.authUsingBrowser);
                    }
                    model: [
                        i18n.tr("Internal Webview"),
                        i18n.tr("External Browser")
                    ]
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    id: maxNumberOfResultsLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Number of results per request (limit)")
                }
                TextField {
                    id: maxNumberOfResults
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - maxNumberOfResultsLabel.width - app.paddingLarge

                    maximumLength: 4
                    validator: IntValidator{bottom: 1; top: 5000;}
                    text: app.settings.searchLimit
                    onAccepted: app.settings.searchLimit = parseInt(text)
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Prevent suspending while playing")
                }
                CheckBox {
                    id: preventSuspendWhilePlaying
                    anchors.right: parent.right
                    checked: app.settings.preventSuspendWhilePlaying
                    onCheckedChanged: app.settings.preventSuspendWhilePlaying = checked
                }
            }
            /*TextField {
                id: country
                placeholderText: label
                label: qsTr("Country Code (2 characters)")
                width: parent.width
                maximumLength: 2
                inputMethodHints: Qt.ImhUppercaseOnly
                onTextChanged: {
                    if(text.length > 0)
                        app.locale_config.country = text
                }
            }*/
        }

    }

}

