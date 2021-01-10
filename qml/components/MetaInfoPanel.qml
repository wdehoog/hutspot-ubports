/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2

Item {
    width: parent.width
    height: labelsColumn.height

    property string firstLabelText: ""
    property string secondLabelText: ""
    property string thirdLabelText: ""
    property bool isFavorite: false

    property alias firstLabel: firstLabel
    property alias secondLabel: secondLabel
    property alias thirdLabel: thirdLabel

    signal firstLabelClicked()
    signal secondLabelClicked()
    signal thirdLabelClicked()

    signal toggleFavorite()

    signal contextMenuRequested()

    Column {
        id: labelsColumn
        width: parent.width
        spacing: app.paddingSmall

        Label {
            id: firstLabel
            //color: Theme.highlightColor
            font.bold: true
            width: parent.width
            wrapMode: Text.Wrap
            text: firstLabelText
            MouseArea {
                anchors.fill: parent
                onClicked: firstLabelClicked()
                onPressAndHold: contextMenuRequested()
            }
        }

        Row {
            width: parent.width
            height: col2.height

            Column {
                id: col2
                spacing: app.paddingSmall
                width: parent.width - savedImage.width

                Label {
                    id: secondLabel
                    //color: Theme.primaryColor
                    //font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    text:  secondLabelText
                    MouseArea {
                        anchors.fill: parent
                        onClicked: secondLabelClicked()
                        onPressAndHold: contextMenuRequested()
                    }
                }
                Label {
                    id: thirdLabel
                    width: parent.width
                    //font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    text: thirdLabelText
                    MouseArea {
                        anchors.fill: parent
                        onClicked: thirdLabelClicked()
                        onPressAndHold: contextMenuRequested()
                    }
                }
            }
            Image {
                id: savedImage
                //anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: app.iconSizeSmall
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: isFavorite ? "image://theme/starred" : "image://theme/non-starred"
                MouseArea {
                     anchors.fill: parent
                     onClicked: toggleFavorite()
                     onPressAndHold: contextMenuRequested()
                }
            }
        }
    }
}
