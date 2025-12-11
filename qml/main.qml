import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import RenkoPlayer 1.0

ApplicationWindow {
    width: 1280
    height: 720
    visible: true
    title: "RenkoPlayer - Modern C++ Player"
    color: "#1e1e1e"

    menuBar: MenuBar {
        implicitHeight: 30

        background: Rectangle {
            color: "#f0f0f0"
        }

        delegate: MenuBarItem {
            id: menuBarItem
            font.pixelSize: 14

            implicitWidth: Math.max(80, contentItem.paintedWidth + 24)
            implicitHeight: 30

            contentItem: Text {
                text: menuBarItem.text
                font: menuBarItem.font
                color: menuBarItem.enabled ? "#333333" : "#aaaaaa"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 2
                color: menuBarItem.down ? "#d0d0d0" : (menuBarItem.hovered ? "#e0e0e0" : "transparent")
                radius: 4
            }
        }

        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("&Open File...")
                onTriggered: fileDialog.open()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("E&xit")
                onTriggered: Qt.quit()
            }
        }
        Menu {
            title: qsTr("Help")
            MenuItem {
                text: qsTr("&About")
                onTriggered: aboutDialog.open()
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Please choose a video file"
        nameFilters: ["Video files (*.mp4 *.avi *.mkv *.mov *.flv *.webm)", "All files (*)"]
        onAccepted: {
            // selectedFile is a URL (e.g. file:///C:/...)
            // We set it to the text field and the player
            var path = selectedFile.toString()
            // Simple cleanup for display (optional, FFmpeg handles file:// usually, but local path is nicer)
            if (path.startsWith("file:///")) {
                // On Windows, file:///C:/path -> C:/path is often better for display
                // But for consistency, we can just pass the URL. 
                // However, let's try to make it a clean path for the text field.
                // Note: QML doesn't have a built-in URL to path converter that handles all OS quirks perfectly without C++.
                // We will pass the URL string directly. VideoRenderItem should handle it.
            }
            urlField.text = path
            videoPlayer.source = path
            videoPlayer.play()
        }
    }

    MessageDialog {
        id: aboutDialog
        title: "About RenkoPlayer"
        text: "RenkoPlayer v1.0\n\nA modern C++ video player using Qt 6 and FFmpeg.\n\nCreated by Shionyori."
        buttons: MessageDialog.Ok
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Video Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"

            VideoRenderItem {
                id: videoPlayer
                anchors.fill: parent
                visible: !isPanorama
                
                onDurationChanged: {
                    if (!isPanorama) progressSlider.to = duration
                }
                onPositionChanged: {
                    if (!isPanorama && !progressSlider.pressed) progressSlider.value = position
                }
            }

            PanoramaRenderItem {
                id: panoramaPlayer
                anchors.fill: parent
                visible: isPanorama
                
                onDurationChanged: {
                    if (isPanorama) progressSlider.to = duration
                }
                onPositionChanged: {
                    if (isPanorama && !progressSlider.pressed) progressSlider.value = position
                }

                MouseArea {
                    anchors.fill: parent
                    property point lastPos
                    onPressed: (mouse) => { lastPos = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: (mouse) => {
                        var dx = mouse.x - lastPos.x
                        var dy = mouse.y - lastPos.y
                        panoramaPlayer.yaw -= dx * 0.2
                        panoramaPlayer.pitch += dy * 0.2
                        // Clamp pitch
                        if (panoramaPlayer.pitch > 89.0) panoramaPlayer.pitch = 89.0
                        if (panoramaPlayer.pitch < -89.0) panoramaPlayer.pitch = -89.0
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                    onWheel: (wheel) => {
                        var newFov = panoramaPlayer.fov - wheel.angleDelta.y / 120 * 5
                        if (newFov < 30) newFov = 30
                        if (newFov > 120) newFov = 120
                        panoramaPlayer.fov = newFov
                    }
                }
            }
        }

        // Controls Area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: "#2d2d2d"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                // Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: formatTime(isPanorama ? panoramaPlayer.position : videoPlayer.position)
                        color: "white"
                        font.pixelSize: 14
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: isPanorama ? panoramaPlayer.duration : videoPlayer.duration
                        // Use a binding that respects user interaction to prevent jitter
                        value: pressed ? value : (isPanorama ? panoramaPlayer.position : videoPlayer.position)
                        
                        background: Rectangle {
                            x: progressSlider.leftPadding
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: progressSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#505050"

                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#3498db"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: progressSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                            border.color: "#bdc3c7"
                        }

                        // Only seek when user interacts
                        onMoved: {
                            if (isPanorama) panoramaPlayer.position = value
                            else videoPlayer.position = value
                        }
                    }

                    Text {
                        text: formatTime(isPanorama ? panoramaPlayer.duration : videoPlayer.duration)
                        color: "white"
                        font.pixelSize: 14
                    }
                }

                // Buttons & URL
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    TextField {
                        id: urlField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        placeholderText: "Enter Video URL (e.g., rtsp://..., http://..., or file path)"
                        placeholderTextColor: "gray"
                        color: "white"
                        font.pixelSize: 14
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 10
                        rightPadding: 10

                        background: Rectangle {
                            color: "#3d3d3d"
                            radius: 4
                        }
                    }

                    Button {
                        onClicked: {
                            if (isPanorama) {
                                panoramaPlayer.source = urlField.text
                                panoramaPlayer.play()
                            } else {
                                videoPlayer.source = urlField.text
                                videoPlayer.play()
                            }
                        }
                        
                        icon.source: "../assets/icons/play.svg"
                        icon.color: "lightgreen"
                        icon.width: 24
                        icon.height: 24
                        display: AbstractButton.IconOnly

                        background: Rectangle {
                            color: parent.down ? "#40ffffff" : (parent.hovered ? "#20ffffff" : "transparent")
                            radius: 4
                        }
                    }

                    Button {
                        onClicked: {
                            if (isPanorama) panoramaPlayer.pause()
                            else videoPlayer.pause()
                        }
                        
                        icon.source: "../assets/icons/pause.svg"
                        icon.color: "orange"
                        icon.width: 24
                        icon.height: 24
                        display: AbstractButton.IconOnly

                        background: Rectangle {
                            color: parent.down ? "#40ffffff" : (parent.hovered ? "#20ffffff" : "transparent")
                            radius: 4
                        }
                    }

                    Button {
                        onClicked: {
                            videoPlayer.stop()
                            panoramaPlayer.stop()
                        }
                        
                        icon.source: "../assets/icons/stop.svg"
                        icon.color: "lightcoral"
                        icon.width: 24
                        icon.height: 24
                        display: AbstractButton.IconOnly

                        background: Rectangle {
                            color: parent.down ? "#40ffffff" : (parent.hovered ? "#20ffffff" : "transparent")
                            radius: 4
                        }
                    }

                    // Volume Control
                    RowLayout {
                        spacing: 5
                        Text {
                            text: "Vol"
                            color: "white"
                            font.pixelSize: 14
                        }
                        Slider {
                            id: volumeSlider
                            from: 0.0
                            to: 1.0
                            value: 1.0
                            Layout.preferredWidth: 100
                            
                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: volumeSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#505050"

                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#3498db"
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: volumeSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                                border.color: "#bdc3c7"
                            }

                            onMoved: {
                                videoPlayer.volume = value
                                panoramaPlayer.volume = value
                            }
                        }
                    }

                    ComboBox {
                        id: resolutionCombo
                        model: ["Original", "1080p", "720p", "480p", "360p"]
                        currentIndex: 0
                        Layout.preferredWidth: 100
                        font.pixelSize: 14

                        background: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 35
                            color: resolutionCombo.pressed ? "#4a4a4a" : (resolutionCombo.hovered ? "#444444" : "#3d3d3d")
                            border.color: "#3d3d3d"
                            radius: 4
                        }                        

                        delegate: ItemDelegate {
                            width: resolutionCombo.width
                            height: 32
                            contentItem: Text {
                                text: modelData
                                color: "white"
                                font: resolutionCombo.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                leftPadding: 10
                            }
                            background: Rectangle {
                                color: pressed ? "#5a5a5a" : (resolutionCombo.highlightedIndex === index ? "#505050" : "#2d2d2d")
                            }
                            highlighted: resolutionCombo.highlightedIndex === index
                        }

                        indicator: Canvas {
                            id: canvas
                            x: resolutionCombo.width - width - resolutionCombo.rightPadding
                            y: resolutionCombo.topPadding + (resolutionCombo.availableHeight - height) / 2
                            width: 12
                            height: 8
                            contextType: "2d"

                            Connections {
                                target: resolutionCombo
                                function onPressedChanged() { canvas.requestPaint(); }
                            }

                            onPaint: {
                                context.reset();
                                context.moveTo(0, 0);
                                context.lineTo(width, 0);
                                context.lineTo(width / 2, height);
                                context.closePath();
                                context.fillStyle = "white";
                                context.fill();
                            }
                        }

                        contentItem: Text {
                            leftPadding: 10
                            rightPadding: resolutionCombo.indicator.width + resolutionCombo.spacing

                            text: resolutionCombo.displayText
                            font: resolutionCombo.font
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        popup: Popup {
                            y: resolutionCombo.height - 1
                            width: resolutionCombo.width
                            height: resolutionCombo.count * 32 + 2 * padding
                            padding: 1

                            contentItem: ListView {
                                clip: true
                                model: resolutionCombo.popup.visible ? resolutionCombo.delegateModel : null
                                currentIndex: resolutionCombo.highlightedIndex
                            }

                            background: Rectangle {
                                border.color: "#3d3d3d"
                                color: "#2d2d2d"
                                radius: 4
                            }
                        }

                        onActivated: (index) => {
                            var w = 0
                            var h = 0
                            switch(index) {
                                case 0: w = 0; h = 0; break;
                                case 1: w = 0; h = 1080; break;
                                case 2: w = 0; h = 720; break;
                                case 3: w = 0; h = 480; break;
                                case 4: w = 0; h = 360; break;
                            }
                            videoPlayer.setResolution(w, h)
                            panoramaPlayer.setResolution(w, h)
                        }
                    }

                    CheckBox {
                        text: "360° Mode"
                        font.pixelSize: 14
                        checked: isPanorama
                        onCheckedChanged: {
                            var currentPos = isPanorama ? videoPlayer.position : panoramaPlayer.position
                            var currentSrc = isPanorama ? videoPlayer.source : panoramaPlayer.source
                            
                            // Stop the previous one
                            if (isPanorama) videoPlayer.stop()
                            else panoramaPlayer.stop()
                            
                            isPanorama = checked
                            
                            // Start the new one
                            if (isPanorama) {
                                panoramaPlayer.source = currentSrc
                                panoramaPlayer.position = currentPos
                                panoramaPlayer.play()
                            } else {
                                videoPlayer.source = currentSrc
                                videoPlayer.position = currentPos
                                videoPlayer.play()
                            }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font: parent.font
                            leftPadding: parent.indicator.width + parent.spacing + 5
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
    
    property bool isPanorama: false

    function formatTime(ms) {
        var totalSeconds = Math.floor(ms / 1000);
        var minutes = Math.floor(totalSeconds / 60);
        var seconds = totalSeconds % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }
}
