import QtQuick 2.14
import QtQuick.Window 2.14
import QtLocation 5.14
import QtPositioning 5.14
import QtQuick.Controls 2.15

Window {
    id:main
    visible: true
    minimumWidth: 640
    minimumHeight: 480

    property int curPolygon: -1;
    ListView{
        id: testView
        model: polyModel//buttonModel
        anchors.top:addButton.bottom
        anchors.bottom: parent.bottom
        width: main.width*0.2
        delegate: Item{
            width: main.width*0.2 - scrollBar.width
            height: 50

            Rectangle {
                anchors.fill: parent
                Text {
                    anchors.centerIn: parent
                    text: 'polygon ' + (index + 1)
                }
                opacity: activ ? 1 : 0.5
                radius: height * 0.3
                color: 'green'
                MouseArea{
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if(mouse.button === Qt.LeftButton){
                            polyModel.set(index, {'activ': polyModel.get(index).activ ^ 1 ? true: false})
                            if (index !== curPolygon && curPolygon != -1){
                                polyModel.set(curPolygon, {'activ': false})
                            }
                            curPolygon = index
                        }
                        else if (mouse.button === Qt.RightButton){
                            if (index === curPolygon)
                                curPolygon = -1
                            else if (index < curPolygon)
                                curPolygon -= 1
                            for (var i = index + 1; i < polyModel.count;++i){
                                polyModel.set(i, {'idx': i})
                            }
                            polyModel.remove(index)
                        }
                    }
                }
            }
        }
    }
    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        active: true
        policy: ScrollBar.AlwaysOn
    }

    ListModel {
        id:polyModel
    }

    Button{
        id: addButton
        text: 'Add Polygone'
        width: main.width*0.2
        onClicked: {
            polyModel.append({'activ': false, 'idx': polyModel.count + 1});
        }
    }

    Map {
        visible: true
        id: map
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width*0.8
        height: parent.height
        plugin: Plugin {
            name: "osm"
        }
        center: QtPositioning.coordinate(59.91, 10.75) // Oslo
        zoomLevel: 14

        MapItemView{
            model:polyModel
            delegate: CastomPolygon{
                isActive: activ
                polyIndex: idx

            }
        }
    }
}
