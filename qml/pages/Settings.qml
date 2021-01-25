import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Controls 2.2 as QtQc
import Ubuntu.Components.ListItems 1.3 as UCListItem

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
                    text: i18n.tr("Use Album Art for Background")
                }
                CheckBox {
                    anchors.right: parent.right
                    checked: app.settings.useAlbumartAsBackground
                    onCheckedChanged: app.settings.useAlbumartAsBackground = checked
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
                    anchors.right: parent.right
                    checked: app.settings.queryForMarket
                    onCheckedChanged: app.settings.queryForMarket = checked
                }
            }

            // setting theme this way results in errors and does not seem to
            // have an effect on the QtQc controls
            Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Dark Theme")
                }
                CheckBox {
                    id: theme
                    anchors.right: parent.right
                    checked: app.settings.theme === 1
                    onCheckedChanged: app.setDarkMode(checked ? 1 : 0)
                }
            }

            Item {
                width: parent.width
                height: authUsingBrowserSelector.height // childrenRect.height
                Label {
                    id: authUsingBrowserLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Authorize using")
                }

                QtQc.ComboBox {
                    id: authUsingBrowserSelector
                    anchors.right: parent.right
                    width: parent.width - authUsingBrowserLabel.width - app.paddingLarge

                    Component.onCompleted: currentIndex = app.settings.authUsingBrowser

                    onActivated: {
                        app.settings.authUsingBrowser = currentIndex
                    }
                    model: [
                        i18n.tr("Internal Webview"),
                        i18n.tr("External Browser")
                    ]
                }
            }

            Item {
                width: parent.width
                height: searchHistoryMaxSize.height //childrenRect.height
                Label {
                    id: searchHistoryMaxSizeLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Number of Search History Items to save")
                }
                TextField {
                    id: searchHistoryMaxSize
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - searchHistoryMaxSizeLabel.width - app.paddingLarge

                    maximumLength: 4
                    validator: IntValidator{bottom: 1; top: 500;}
                    text: app.settings.searchHistoryMaxSize
                    onTextChanged: app.settings.searchHistoryMaxSize = parseInt(text)
                }
            }

            Item {
                width: parent.width
                height: maxNumberOfResults.height // childrenRect.height
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
                    onTextChanged: app.settings.searchLimit = parseInt(text)
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

