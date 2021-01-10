import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Controls 2.2 as QtQc
import Ubuntu.Components.ListItems 1.3 as UCListItem

Page {
    id: settingsPage
    objectName: "SettingsPage"

    property alias _mnor : maxNumberOfResults

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
                    id: queryForMarket
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
                    id: queryForMarket
                    anchors.right: parent.right
                    checked: app.settings.queryForMarket
                    onCheckedChanged: app.settings.queryForMarket = checked
                }
            }

            // setting theme this way results in errors and does not seem to
            // have an effect on the QtQc controls
            /*Item {
                width: parent.width
                height: childrenRect.height
                Label {
                    anchors.left: parent.left
                    text: i18n.tr("Dark Theme")
                }
                CheckBox {
                    id: theme
                    anchors.right: parent.right
                    checked: app.theme.name == 'Ubuntu.Components.Themes.SuruDark'
                    onCheckedChanged: {
                        app.theme.name = checked
                          ? 'Ubuntu.Components.Themes.SuruDark'
                          : 'Ubuntu.Components.Themes.Ambiance'
                    }
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

                ComboButton {
                    id: authUsingBrowserSelector
                    anchors.right: parent.right
                    width: parent.width - authUsingBrowserLabel.width - app.paddingLarge
                    expandedHeight: collapsedHeight + units.gu(1) + wvChoices.length * units.gu(6)
                    //text: currentIndex >= 0 ? wvChoices.get(currentIndex).text : ""
                    //property alias wvChoices: wvChoices
                    //ListModel { id: wvChoices }
                    text: wvChoices[currentIndex]
                    property var wvChoices: [
                        i18n.tr("Internal Webview"),
                        i18n.tr("External Browser")
                    ]
                    comboList:  UbuntuListView {
                        delegate: UCListItem.Standard {
                            text: modelData
                            selected: model.index == authUsingBrowserSelector.currentIndex
                            //text: model.text
                            onClicked: {
                                authUsingBrowserSelector.currentIndex = model.index
                                app.settings.authUsingBrowser = model.index
                                authUsingBrowserSelector.expanded = false
                            }
                        }
                        model: authUsingBrowserSelector.wvChoices
                    }
                    property int currentIndex: -1
                    Component.onCompleted: {
                        //wvChoices.append({text: i18n.tr("Internal Webview")})
                        //wvChoices.append({text: i18n.tr("External Webview")})
                        currentIndex = app.settings.authUsingBrowser
                    }
                }

                /*QtQc.ComboBox {
                    id: authUsingBrowserSelector
                    anchors.right: parent.right
                    width: parent.width - authUsingBrowserLabel.width - app.paddingLarge
                    height: _mnor.height //pageHeader.height * 0.9

                    indicator.width: height
                    background: Rectangle {
                        color: app.normalBackgroundColor
                        border.width: 1
                        border.color: "grey"
                        radius: 7
                    }
                    delegate: QtQc.ItemDelegate {
                        width: authUsingBrowserSelector.width
                        height: authUsingBrowserSelector.height
                        text: modelData
                        //color: app.foregroundColor
                    }

                    Component.onCompleted: {
                        currentIndex = app.settings.authUsingBrowser ? 1 : 0
                        //__styleInstance.textColor = app.foregroundColor
                        //style.textColor = app.foregroundColor
                    }

                    onActivated: {
                        app.settings.authUsingBrowser = currentIndex == 1
                        console.log("new authUsingBrowser: " + app.settings.authUsingBrowser)
                    }
                    model: [
                        i18n.tr("Internal Webview"),
                        i18n.tr("External Browser")
                    ]
                }*/
            }

            Item {
                width: parent.width
                height: childrenRect.height
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

