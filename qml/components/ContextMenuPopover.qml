import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3

ActionSelectionPopover {
    id: actionSelectionPopover

    property int upper: actions.children[actions.children.length-1].idx
    property int borderWidth: 4
    property int seperatorWidth: 1

    delegate: Empty {
        id: listItem

        height: visible ? implicitHeight : 0

        Label {
            text: listItem.text
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            wrapMode: Text.Wrap
            color: theme.palette.normal.overlayText
            font.bold: true
            opacity: listItem.action.enabled ? 1.0 : 0.4
            z: 2
        }

        Rectangle {
            x: borderWidth
            y: {
              if(listItem.action.idx == 0)
                return x
              return 0
            }
            width: parent.width - 2*x
            height: {
              //console.log("action: " + listItem.action.idx)
              if(actionSelectionPopover.upper == 0)
                  return parent.height - 2*x
              else if(listItem.action.idx == 0)
                  return parent.height - x - seperatorWidth
              else if(listItem.action.idx == actionSelectionPopover.upper)
                  return parent.height - x
              else    
                  return parent.height - seperatorWidth
            }
            color: "white" 
            z: 1
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            z: -1
        }

        onTriggered: actionSelectionPopover.hide()
    }
}
