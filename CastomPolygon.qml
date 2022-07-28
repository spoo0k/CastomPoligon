import QtQuick 2.0
import QtPositioning 5.14
import QtLocation 5.14
MapItemGroup {
    id: tempItem
    property bool isActive: true
    property int pointIndex: -1
    property int lineIndex: -1
    property bool moveflag: false
    property int polyIndex: -1
    anchors.fill: parent
    ListModel{
        id: pointModel
    }
    ListModel{
        id: lineModel
    }


    MapItemView{
        z: lineView.z +1
        model: pointModel
        delegate: MapQuickItem{
            anchorPoint: Qt.point(sourceItem.width/2, sourceItem.height/2)
            coordinate: QtPositioning.coordinate(model.coords.latitude, model.coords.longitude)
            sourceItem: Image {
                width: isActive ? 40 : 30
                height: isActive ? 40 : 30
                source: "Red-Circle.png"
                MouseArea{
                    enabled: isActive
                    id: pointArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    propagateComposedEvents: true
                    onPressed: {
                        pointIndex = index
                        leftButtonArea.preventStealing = true
                        mouse.accepted = false
                    }
                    onReleased: {
                        preventStealing = false
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: someValue//polyIndex//index
                    color: "black"
                }
            }
        }
    }
    MapItemView{
        anchors.fill: parent
        id: lineView
        z: map.z + 1
        model: lineModel
        delegate: MapPolyline{
            line.color: 'green'
            opacity: isActive ? 1 : 0.5
            line.width: 10
            path: [
                {latitude: model.coord1.latitude, longitude: model.coord1.longitude},
                {latitude: model.coord2.latitude, longitude: model.coord2.longitude}
            ]
            MouseArea{
                enabled: isActive
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: true
                onPressed: {
                    lineIndex = index
                    mouse.accepted = false
                }
            }
        }
    }

    MouseArea {
        enabled: isActive
        id: rightButtonArea
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onReleased: {
            if (pointIndex != -1){
                delMarker(pointIndex)
                pointIndex = -1;
            }
            leftButtonArea.preventStealing = false
        }
        onPositionChanged: {
            pointIndex = -1;
        }
    }
    MouseArea{
        enabled: isActive
        id: leftButtonArea
        anchors.fill: tempItem
        onClicked: {
            var point = Qt.point(mouse.x, mouse.y)
            var coord = map.toCoordinate(point);
            if (mouse.button == Qt.LeftButton && !moveflag && pointIndex == -1){
                if (lineIndex == -1){
                    addMarker(coord)
                    addLine();
                }
                else {
                    sliceLine(coord, lineIndex)
                }
            }
            moveflag = false
        }
        onPositionChanged: {
            if ( pointIndex != -1){
                var point = Qt.point(mouse.x, mouse.y)
                var coord = map.toCoordinate(point);
                if(coord.isValid){
                    moveMarker(pointIndex, coord)
                }
            }
        }
        onReleased: {
            if (mouse.button == Qt.LeftButton && pointIndex != -1){
                moveflag = true;
                var point = Qt.point(mouse.x, mouse.y)
                var coord = map.toCoordinate(point);
                if(coord.isValid){
                    moveMarker(pointIndex, coord)
                }
                pointIndex = -1;
                lineIndex = -1;
                leftButtonArea.preventStealing = false
            }
        }
    }
    function moveMarker(index, coordinate){
        pointModel.set(index, {"coords": coordinate});
        if (pointModel.count === 2){
            if (index === 0)
                lineModel.set(0,{'coord1': coordinate});
            else
                lineModel.set(0,{'coord2': coordinate});
        }
        else if (pointModel.count > 2)
        {
            lineModel.set(index, {'coord1': coordinate});
            if (index !== 0) {
                lineModel.set(index - 1,{'coord2': coordinate});
            }
            else {
                lineModel.set(lineModel.count - 1, {'coord2': coordinate});
            }
        }

    }
    function addMarker(coordinate){
        pointModel.append({"coords": coordinate, 'someValue': polyIndex})
    }
    function delMarker(index){
//        pointModel.remove(index);

        console.log('\tlcount\t'+ lineModel.count)
        console.log('\tpcount\t'+ pointModel.count)
        pointModel.remove(index);
        if (pointModel.count > 1){
            if (index === 0){
                lineModel.remove(index);
                lineModel.set(lineModel.count - 1,{'coord2': pointModel.get(0).coords})
            }
            else {
                if (index !== pointModel.count) {
                    lineModel.remove(index);
                    lineModel.set(index - 1,{'coord2': pointModel.get(index).coords})
                }
                else{
                    lineModel.remove(index);
                    lineModel.set(index - 1,{'coord2': pointModel.get(0).coords})
                }
            }
            if (pointModel.count === 2){
                lineModel.remove(1);
            }
        }
        else if (pointModel.count === 1) {
            lineModel.remove(0);
        }

        console.log('lcount\t'+ lineModel.count)
        console.log('pcount\t'+ pointModel.count)
    }
    function addLine () {
        if (pointModel.count === 2){
            lineModel.append({"coord1": pointModel.get(0).coords,"coord2": pointModel.get(pointModel.count - 1).coords})
        }
        else if (pointModel.count === 3){
            lineModel.append({"coord1": pointModel.get(1).coords,"coord2": pointModel.get(pointModel.count - 1).coords})
            lineModel.append({"coord2": pointModel.get(0).coords,"coord1": pointModel.get(pointModel.count - 1).coords})
        }
        else if (pointModel.count > 3){
            lineModel.append({"coord2": pointModel.get(0).coords,"coord1": pointModel.get(pointModel.count - 1).coords})
            lineModel.set(lineModel.count - 2, {'coord2': pointModel.get(pointModel.count - 1).coords})
        }
    }

    function sliceLine(coordinate, index) {
        pointModel.insert(index + 1, {'coords': coordinate, 'someValue': polyIndex})
        lineModel.set(index,{'coord2': coordinate});
        if(index + 1 != pointModel.count -1)
            lineModel.insert(index + 1, {'coord1': coordinate, 'coord2': pointModel.get(index+2).coords})
        else
            lineModel.insert(index + 1, {'coord1': coordinate, 'coord2': pointModel.get(0).coords})
        if (pointModel.count === 3){
            lineModel.append({"coord2": pointModel.get(0).coords,"coord1": pointModel.get(pointModel.count - 1).coords})
        }
    }
    onPolyIndexChanged: {
        for ( var i = 0; i < pointModel.count; ++i){
            pointModel.set(i,{'someValue': polyIndex})
        }
    }
}
