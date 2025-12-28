import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RenkoPlayer 1.0
import RenkoUI 1.0

RWindow {
    width: 1280
    height: 720
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: "RenkoPlayer - Modern C++ Player"
    color: Theme.background

    menuBar: RMenuBar {
        RMenu {
            title: qsTr("File")
            RMenuItem {
                text: qsTr("Open File...")
                onTriggered: fileDialog.open()
            }
            MenuSeparator {
                contentItem: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 1
                    color: Theme.divider
                }
            }
            RMenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit()
            }
        }
        RMenu {
            title: qsTr("Help")
            RMenuItem {
                text: qsTr("About")
                onTriggered: aboutDialog.open()
            }
        }
    }

    RFileDialog {
        id: fileDialog
        iconSource: "qrc:/qt/qml/RenkoPlayer/assets/icons/app.png"
        title: "Please choose a video file"
        nameFilters: ["Video files (*.mp4 *.avi *.mkv *.mov *.flv *.webm)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString()
            urlField.text = path
            
            if (isPanorama) {
                videoPlayer.source = ""
                panoramaPlayer.source = path
                panoramaPlayer.play()
            } else {
                panoramaPlayer.source = ""
                videoPlayer.source = path
                videoPlayer.play()
            }
        }
    }

    RMessageDialog {
        id: aboutDialog
        iconSource: "qrc:/qt/qml/RenkoPlayer/assets/icons/app.png"
        title: "About RenkoPlayer"
        text: "RenkoPlayer v1.0\n\nA modern C++ video player using Qt 6 and FFmpeg.\n\nCreated by Shionyori."
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (isPanorama) {
                if (panoramaPlayer.playing) panoramaPlayer.pause()
                else panoramaPlayer.play()
            } else {
                if (videoPlayer.playing) videoPlayer.pause()
                else videoPlayer.play()
            }
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            var player = isPanorama ? panoramaPlayer : videoPlayer
            var newPos = player.position - 5000
            if (newPos < 0) newPos = 0
            player.position = newPos
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            var player = isPanorama ? panoramaPlayer : videoPlayer
            var newPos = player.position + 5000
            if (newPos > player.duration) newPos = player.duration
            player.position = newPos
        }
    }

    Shortcut {
        sequence: "Up"
        onActivated: {
            var newVol = volumeSlider.value + 0.1
            if (newVol > 1.0) newVol = 1.0
            volumeSlider.value = newVol
            videoPlayer.volume = newVol
            panoramaPlayer.volume = newVol
        }
    }

    Shortcut {
        sequence: "Down"
        onActivated: {
            var newVol = volumeSlider.value - 0.1
            if (newVol < 0.0) newVol = 0.0
            volumeSlider.value = newVol
            videoPlayer.volume = newVol
            panoramaPlayer.volume = newVol
        }
    }

    property bool controlsVisible: true
    
    Timer {
        id: hideTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if ((isPanorama ? panoramaPlayer.playing : videoPlayer.playing) && !controlsPanel.isHoveringControls) {
                controlsVisible = false
            }
        }
    }

    function showControls() {
        controlsVisible = true
        hideTimer.restart()
    }

    Item {
        anchors.fill: parent

        // Video Area
        Rectangle {
            anchors.fill: parent
            color: "black" // Video background should remain black

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
                onPlayingChanged: {
                    if (!playing) showControls()
                    else hideTimer.restart()
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
                onPlayingChanged: {
                    if (!playing) showControls()
                    else hideTimer.restart()
                }

                MouseArea {
                    anchors.fill: parent
                    property point lastPos
                    onPressed: (mouse) => { 
                        lastPos = Qt.point(mouse.x, mouse.y)
                        showControls()
                    }
                    onPositionChanged: (mouse) => {
                        showControls()
                        var dx = mouse.x - lastPos.x
                        var dy = mouse.y - lastPos.y
                        panoramaPlayer.yaw -= dx * 0.2
                        panoramaPlayer.pitch += dy * 0.2
                        if (panoramaPlayer.pitch > 89.0) panoramaPlayer.pitch = 89.0
                        if (panoramaPlayer.pitch < -89.0) panoramaPlayer.pitch = -89.0
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                    onWheel: (wheel) => {
                        showControls()
                        var newFov = panoramaPlayer.fov - wheel.angleDelta.y / 120 * 5
                        if (newFov < 30) newFov = 30
                        if (newFov > 120) newFov = 120
                        panoramaPlayer.fov = newFov
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onPositionChanged: showControls()
            }
        }

        // Controls Area
        RPanel {
            id: controlsPanel
            anchors.bottom: parent.bottom
            anchors.bottomMargin: controlsVisible ? 0 : -height
            anchors.left: parent.left
            anchors.right: parent.right
            height: 100
            color: Theme.surface
            opacity: 0.85
            radius: 0 // Flat bottom panel
            
            property bool isHoveringControls: false

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: controlsPanel.isHoveringControls = true
                onExited: {
                    controlsPanel.isHoveringControls = false
                    showControls()
                }
                onPositionChanged: showControls()
                onPressed: showControls()
                propagateComposedEvents: true
                onClicked: (mouse) => mouse.accepted = false
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingLarge
                spacing: Theme.spacingNormal

                // Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingNormal

                    RLabel {
                        text: formatTime(isPanorama ? panoramaPlayer.position : videoPlayer.position)
                    }

                    RSlider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: isPanorama ? panoramaPlayer.duration : videoPlayer.duration
                        value: pressed ? value : (isPanorama ? panoramaPlayer.position : videoPlayer.position)
                        
                        // Enhanced visibility styling
                        trackColor: "#BDBDBD"
                        handleSize: 20
                        handleBorderWidth: 3
                        handleBorderColor: Theme.surface
                        
                        onMoved: {
                            if (isPanorama) panoramaPlayer.position = value
                            else videoPlayer.position = value
                        }
                    }

                    RLabel {
                        text: formatTime(isPanorama ? panoramaPlayer.duration : videoPlayer.duration)
                    }
                }

                // Buttons & URL
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingLarge

                    RTextField {
                        id: urlField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        placeholderText: "Enter Video URL (e.g., rtsp://..., http://..., or file path)"
                        
                        backgroundColor: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)
                    }

                    RToolButton {
                        onClicked: {
                            if (isPanorama) {
                                videoPlayer.source = ""
                                panoramaPlayer.source = urlField.text
                                panoramaPlayer.play()
                            } else {
                                panoramaPlayer.source = ""
                                videoPlayer.source = urlField.text
                                videoPlayer.play()
                            }
                        }
                        icon.source: "../assets/icons/play.svg"
                        icon.color: Theme.success
                        icon.width: 24
                        icon.height: 24
                        text: ""
                    }

                    RToolButton {
                        onClicked: {
                            if (isPanorama) panoramaPlayer.pause()
                            else videoPlayer.pause()
                        }
                        icon.source: "../assets/icons/pause.svg"
                        icon.color: Theme.warning
                        icon.width: 24
                        icon.height: 24
                        text: ""
                    }

                    RToolButton {
                        onClicked: {
                            videoPlayer.stop()
                            panoramaPlayer.stop()
                        }
                        icon.source: "../assets/icons/stop.svg"
                        icon.color: Theme.error
                        icon.width: 24
                        icon.height: 24
                        text: ""
                    }

                    // Volume Control
                    RowLayout {
                        spacing: Theme.spacingSmall
                        RLabel {
                            text: "Vol"
                        }
                        RSlider {
                            id: volumeSlider
                            from: 0.0
                            to: 1.0
                            value: 1.0
                            Layout.preferredWidth: 100
                            
                            // Enhanced visibility styling
                            trackColor: "#BDBDBD"
                            handleSize: 16
                            handleBorderWidth: 3
                            handleBorderColor: Theme.surface
                            
                            onMoved: {
                                videoPlayer.volume = value
                                panoramaPlayer.volume = value
                            }
                        }
                    }

                    RComboBox {
                        id: resolutionCombo
                        model: ["Original", "1080p", "720p", "480p", "360p"]
                        currentIndex: 0
                        Layout.preferredWidth: 100
                        
                        backgroundColor: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)

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

                    RCheckBox {
                        id: panoramaCheckBox
                        text: "360° Mode"
                        checked: isPanorama
                        
                        indicatorColor: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.4)

                        onCheckedChanged: {
                            var currentPos = isPanorama ? panoramaPlayer.position : videoPlayer.position
                            var currentSrc = isPanorama ? panoramaPlayer.source : videoPlayer.source
                            
                            if (isPanorama) panoramaPlayer.source = ""
                            else videoPlayer.source = ""
                            
                            isPanorama = checked
                            
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
