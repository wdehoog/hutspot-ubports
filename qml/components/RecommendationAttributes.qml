/**
 * Hutspot.
 * Copyright (C) 2020 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.7
import Ubuntu.Components 1.3

import "../Util.js" as Util

Column {
    width: parent.width

    property bool expandAttributes: false

    signal attributeChanged(var attribute, var value)

    function getLabelText(attribute) {
        switch(attribute) {
            case "tempo": return i18n.tr("Tempo")
            case "energy": return i18n.tr("Energy")
            case "danceability": return i18n.tr("Danceability")
            case "instrumentalness": return i18n.tr("Instrumentalness")
            case "speechiness": return i18n.tr("Speechiness")
            case "acousticness": return i18n.tr("Acousticness")
            case "liveness": return i18n.tr("Liveness")
            case "positiveness": return i18n.tr("Positiveness")
            case "popularity": return i18n.tr("Popularity")
        }
    }

    ListModel {
        id: attributesModel
        ListElement {attribute: "tempo"; min: 0; max: 512; value: 100}
        ListElement {attribute: "energy"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "danceability"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "instrumentalness"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "speechiness"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "acousticness"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "liveness"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "positiveness"; min: 0; max: 1.0; value: 0.5}
        ListElement {attribute: "popularity"; min: 0; max: 100; value: 50}
    }

    MouseArea {
        width:  parent.width // childrenRect.width
        height: childrenRect.height
        anchors.right: parent.right
        Row {
            anchors.right: parent.right
            height: hl.height
            spacing: app.paddingMedium
            Label {
                id: hl
                font.weight: app.fontHighlightWeight
                anchors.verticalCenter: parent.verticalCenter
                text: i18n.tr("Attributes")
            }
            Icon {
                id: hi
                width: app.iconSizeMedium
                anchors.verticalCenter: parent.verticalCenter
                name: expandAttributes ? "up" : "down" 
            }
        }
        onClicked: {
            expandAttributes = !expandAttributes
        }
    }

    ListView {
        id: listView
        width: parent.width
        implicitHeight: expandAttributes ? contentItem.childrenRect.height : 0
        visible: expandAttributes

        model: attributesModel

        delegate: ListItem {
            width: parent.width

            Column {         
              id: lab
              width: parent.width * 0.25      
              anchors.verticalCenter: parent.verticalCenter
              Label {
                  anchors.left: parent.left      
                  text: getLabelText(attribute)
              }
              Label {
                  anchors.left: parent.left      
                  text: slider.value.toPrecision(3) 
              }
            }

            Slider {
                id: slider
                width: parent.width - lab.width - app.paddingMedium
                anchors.right: parent.right      
                anchors.verticalCenter: parent.verticalCenter
                minimumValue: min
                maximumValue: max
                live: true
                onPressedChanged: {
                    if(pressed) 
                      return
                    model.value = slider.value    
                    attributeChanged(attribute, model.value)
                }
                Component.onCompleted: slider.value = model.value
            }
        }
    }

    function getAttributeValues(options) {
        var i
        for(i=0;i<attributesModel.count;i++) {
            var attribute = attributesModel.get(i)
            options["target_"+attribute.attribute] = attribute.value  
            console.log("options[%1]: %2".arg("target_"+attribute.attribute).arg(attribute.value))
        }
        return options
    }

    function setAttributeValues(options) {
        var i
        for(i=0;i<attributesModel.count;i++) {
            var attribute = attributesModel.get(i)
        }
    }

}
