import QtQuick 2.10
import QtQuick.Window 2.10
import QtGraphicalEffects 1.0

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("Game Controller Demo")

    Rectangle
    {
        id: canvasContainer
        width: 460
        height: 460
        color:  "darkgray"
        radius: height / 2
        anchors.centerIn: parent

        Canvas {
            id: canvas
            antialiasing: true
            anchors.centerIn: parent
            width: parent.width
            height: width

            // customization
            property bool gridEnabled : true
            property real allowedButtonRadius: 0.80 // between 0 and 1

            // changing
            property int lastX;
            property int lastY;
            property real joyStickAngle

            // "constant"
            readonly property int canvasWidth: width
            readonly property int canvasHalfWidth: width / 2
            readonly property int canvasHeight: height
            readonly property int canvasHalfHeight: width / 2
            property int buttonScaledHeight: 96
            property int buttonScaledWidth: 96
            readonly property int bSWh: buttonScaledWidth / 2
            readonly property int bSHh: buttonScaledHeight / 2

            onJoyStickAngleChanged: {
                //console.log("Angle In Rad: "+joyStickAngle);
            }

            Component.onCompleted: {
                loadImage("jb_small.png");
                lastX = canvasHalfWidth;
                lastY = canvasHalfHeight;
            }

            RadialGradient {
                anchors.fill: parent
                horizontalOffset: 0
                verticalOffset: 0
                verticalRadius: parent.width
                horizontalRadius: parent.height
                angle: 0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.45; color: "transparent" }
                    GradientStop { position: 0.50; color: "white" }
                    GradientStop { position: 1.0; color: "white" }
                }
            }

            function calculateCartesian (r, theta){
                var x = r * Math.cos(theta);
                var y = r * Math.sin(theta);
                return {
                    x: x,
                    y: y
                }
            }

            function calculatePolar (x, y) {
                var r = Math.pow((Math.pow(x, 2) + Math.pow(y, 2)), 0.5);
                var theta = Math.atan2(y, x);

                return {
                    magnitude: r,
                    angle: theta
                }
            }

            onPaint: {
                /**
                James Fidler - https://codepen.io/terrarum/pen/LVobZN
                This was originally written as a series of CommonJS modules, which is why almost every function here is in an object for no reason.
                */
                /**
                Now we modify it to suite our needs in QML.
                */

                var ctx = getContext("2d");

                var space = 20,
                        i,
                        thickSpace = 100;

                var offsetX = canvasHalfWidth;
                var offsetY = canvasHalfHeight;

                var center = {
                    x: offsetX,
                    y: offsetY
                };

                var drawItem = function(item) {

                    var x = item.x;
                    var y = item.y;

                    ctx.beginPath();

                    ctx.moveTo(x, y);
                    ctx.arc(x, y, 10, 0, 2 * Math.PI, false);
                    ctx.fillStyle = "#22bb22";
                    ctx.strokeStyle = "#22bb22";
                    ctx.fill();
                    ctx.lineWidth = 0;

                    ctx.stroke();
                };

                var drawJoyStickItem = function(item) {
                    ctx.drawImage("jb_small.png", item.x-bSWh, item.y-bSHh, buttonScaledWidth, buttonScaledHeight);

                };

                var polar = function(r, theta) {
                    return {
                        magnitude: r,
                        angle: theta
                    }
                };

                var hLength,
                        vLength,
                        dLength,
                        p,
                        midpoint,
                        quartpoint,
                        offsetPos,
                        offsetPosP,
                        offsetmidpointP,
                        angle,
                        arcAngleStart,
                        arcCCW;

                var drawMouseLines = function() {
                    ctx.beginPath();
                    ctx.strokeStyle = "#bbbbbb";
                    ctx.font = "12px sans-serif";

                    hLength = mouse.x - center.x;
                    vLength = center.y - mouse.y;
                    dLength = Math.sqrt(Math.pow(hLength, 2) + Math.pow(vLength, 2));

                    // Horizontal line.
                    ctx.moveTo(center.x, center.y);
                    ctx.lineTo(mouse.x, center.y);
                    ctx.fillText(Math.abs(Math.floor(hLength)), mouse.x + (center.x - mouse.x) / 2 - 10, center.y - 5);

                    // Vertical line.
                    ctx.moveTo(mouse.x, center.y);
                    ctx.lineTo(mouse.x, mouse.y);
                    ctx.fillText(Math.abs(Math.floor(vLength)), mouse.x + 5, center.y + (mouse.y - center.y) / 2);

                    // Diagonal line.
                    ctx.moveTo(center.x, center.y);
                    ctx.lineTo(mouse.x, mouse.y);

                    p = calculatePolar(hLength, vLength);

                    midpoint = calculateCartesian(p.magnitude / 2, p.angle);
                    quartpoint = calculateCartesian(p.magnitude / 4, p.angle);

                    ctx.fillText(dLength.toFixed(2), midpoint.x + offsetX + 10, -midpoint.y + offsetY);

                    ctx.moveTo(center.x, center.y);

                    angle = Math.atan2(-midpoint.y, midpoint.x);
                    joyStickAngle = angle;

                    // Top right.
                    if (angle <= 0 && angle > -Math.PI / 2){
                        arcAngleStart = 0;
                        arcCCW = true;

                        offsetPos = polar(-5, p.angle - Math.PI / 2);
                    }
                    // Top left.
                    else if (angle <= -Math.PI / 2 && angle >= -Math.PI) {
                        arcCCW = false;
                        if (angle === -Math.PI) {
                            arcAngleStart = -Math.PI;
                        }
                        else {
                            arcAngleStart = Math.PI;
                        }

                        offsetPos = polar(5, p.angle - Math.PI / 2);
                    }
                    // Bottom right.
                    else if (angle > 0 && angle < Math.PI / 2) {
                        arcAngleStart = 0;
                        arcCCW = false;

                        offsetPos = polar(5, p.angle - Math.PI / 2);
                    }
                    // Bottom left.
                    else if (angle > Math.PI / 2 && angle <= Math.PI) {
                        arcAngleStart = Math.PI;
                        arcCCW = true;

                        offsetPos = polar(-5, p.angle - Math.PI / 2);
                    }
                    else {
                        offsetPos = polar(0, 0);
                    }

                    offsetPosP = calculateCartesian(offsetPos.magnitude, offsetPos.angle);
                    offsetmidpointP = {
                        x: midpoint.x + offsetPosP.x,
                        y: midpoint.y + offsetPosP.y
                    };

                    ctx.arc(center.x, center.y, p.magnitude / 4, arcAngleStart, angle, arcCCW);

                    ctx.stroke();
                };


                var mouse = {
                    x: lastX- ctx.shadowOffsetX,
                    y: lastY- ctx.shadowOffsetY,
                    render: function() {
                        // Draw center;
                        drawMouseLines()
                        drawItem(center);
                        ctx.beginPath();
                        ctx.strokeStyle = "#ffffff";
                        ctx.moveTo(offsetPosP.x + offsetX, -offsetPosP.y + offsetY);
                        ctx.lineTo(offsetmidpointP.x + offsetX, -offsetmidpointP.y + offsetY);
                        ctx.stroke();
                        drawJoyStickItem(mouse);
                    }
                }

                var grid = {
                    draw: function() {
                        ctx.beginPath();
                        ctx.strokeStyle = "#555555";
                        ctx.lineWidth = 1;
                        for (i = space; i < canvasWidth; i += space) {
                            ctx.moveTo(i, 0);
                            ctx.lineTo(i, canvasHeight);
                        }
                        for (i = space; i < canvasHeight; i += space) {
                            ctx.moveTo(0, i);
                            ctx.lineTo(canvasWidth, i);
                        }
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.lineWidth = 2;
                        for (i = thickSpace; i < canvasWidth; i += thickSpace) {
                            ctx.moveTo(i, 0);
                            ctx.lineTo(i, canvasHeight);
                        }
                        for (i = thickSpace; i < canvasHeight; i += thickSpace) {
                            ctx.moveTo(0, i);
                            ctx.lineTo(canvasWidth, i);
                        }
                        ctx.stroke();
                    }
                }

                var gameController = {
                    render: function() {
                        ctx.clearRect(0, 0, canvasWidth, canvasHeight);
                        if (gridEnabled)
                            grid.draw();
                        mouse.render();
                    }
                }
                // now with all those functions and classes created, lets draw all
                gameController.render();
            }

            MouseArea {
                id: area
                property bool isQuadratic: false
                property int mouseMargin: parent.height / 10 // used only in quadratic mode

                function calculateCartesian (r, theta){
                    var x = r * Math.cos(theta);
                    var y = r * Math.sin(theta);
                    return {
                        x: x,
                        y: y
                    }
                }

                function calculatePolar (x, y) {
                    var r = Math.sqrt( Math.pow(x, 2) + Math.pow(y, 2) );
                    var theta = Math.atan2(y, x);
                    return {
                        magnitude: r,
                        angle: theta
                    }
                }

                anchors.fill: parent
                onPositionChanged: {
                    if (!isQuadratic)
                    {
                        var tP = area.calculatePolar(mouseX - canvas.canvasHalfWidth ,  mouseY - canvas.canvasHalfHeight);
                        //console.log("POLAR_R", tP.magnitude)
                        if (tP.magnitude > canvas.canvasHalfWidth * canvas.allowedButtonRadius )
                            tP.magnitude = canvas.canvasHalfWidth * canvas.allowedButtonRadius;
                        var ret = area.calculateCartesian(tP.magnitude, tP.angle);
                        canvas.lastX = ret.x + canvas.canvasHalfWidth;
                        canvas.lastY = ret.y + canvas.canvasHalfHeight;
                    }
                    else
                    {
                        var tY = mouseY;
                        var tX = mouseX;
                        if ( mouseX < mouseMargin)
                            tX = mouseMargin;
                        if (mouseX > parent.width-mouseMargin )
                            tX = parent.width-mouseMargin
                        if (mouseY < mouseMargin)
                            tY = mouseMargin;
                        if (mouseY > parent.height-mouseMargin )
                            tY = parent.height-mouseMargin
                        canvas.lastX = tX
                        canvas.lastY = tY
                    }
                    canvas.requestPaint()
                }
            }
        }
    }

}
