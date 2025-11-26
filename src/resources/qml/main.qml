import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RenkoPlayer 1.0

Window {
    width: 1280
    height: 720
    visible: true
    title: "RenkoPlayer - Modern C++ Player"
    color: "#1e1e1e"

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
            Layout.preferredHeight: 80
            color: "#2d2d2d"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
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
