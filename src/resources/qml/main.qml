import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import RenkoPlayer 1.0

ApplicationWindow {
    width: 1280
    height: 720
    visible: true
    title: "RenkoPlayer - Modern C++ Player"
    color: "#1e1e1e"

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
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
            title: qsTr("&Help")
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
            }
        }

        // Controls Area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: "#2d2d2d"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                // Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: formatTime(videoPlayer.position)
                        color: "white"
                        font.pixelSize: 12
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: videoPlayer.duration
                        // Use a binding that respects user interaction to prevent jitter
                        value: pressed ? value : videoPlayer.position
                        
                        // Only seek when user interacts
                        onMoved: {
                            videoPlayer.position = value
                        }
                    }

                    Text {
                        text: formatTime(videoPlayer.duration)
                        color: "white"
                        font.pixelSize: 12
                    }
                }

                // Buttons & URL
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: urlField
                        Layout.fillWidth: true
                        placeholderText: "Enter Video URL (e.g., rtsp://..., http://..., or file path)"
                        text: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                        color: "white"
                        background: Rectangle {
                            color: "#3d3d3d"
                            radius: 4
                        }
                    }

                    Button {
                        text: "Play"
                        onClicked: {
                            videoPlayer.source = urlField.text
                            videoPlayer.play()
                        }
                        background: Rectangle {
                            color: "#007acc"
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Pause"
                        onClicked: {
                            videoPlayer.pause()
                        }
                        background: Rectangle {
                            color: "#e6a800"
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Stop"
                        onClicked: {
                            videoPlayer.stop()
                        }
                        background: Rectangle {
                            color: "#cc3300"
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    function formatTime(ms) {
        var totalSeconds = Math.floor(ms / 1000);
        var minutes = Math.floor(totalSeconds / 60);
        var seconds = totalSeconds % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }
}
