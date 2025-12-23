import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Qt.labs.settings
import Qt.labs.platform as Platform
import RenkoUI 1.0

RDialog {
    id: control
    width: 800
    height: 560
    title: qsTr("Open File")

    // === Public API ===
    property var nameFilters: ["All files (*)"]
    property string selectedNameFilter: nameFilters[0]
    property int fileMode: openFile
    property url selectedFile
    property list<url> selectedFiles

    // === Constants ===
    readonly property int openFile: 0
    readonly property int openFiles: 1
    readonly property int saveFile: 2

    // === Internal State ===
    property string currentPath: Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation) || "file:///"
    property string fileNameInput: ""

    // === Settings ===
    Settings {
        id: settings
        category: "RenkoPlayer/RFileDialog"
        property alias lastPath: control._lastPath
        property alias lastFilter: control._lastFilter
        property alias showHidden: folderModel.showHidden
    }
    property string _lastPath: currentPath
    property string _lastFilter: selectedNameFilter

    // Disable standard buttons to use custom ones with validation logic
    standardButtons: Dialog.NoButton

    onAccepted: {
        if (fileMode === saveFile && fileNameInput.trim()) {
            var cleanPath = currentPath.replace(/\/+$/, "")
            selectedFile = "file:///" + cleanPath + "/" + fileNameInput.trim()
        }
        else if (selectedFile) {
            var dir = selectedFile.toString().replace(/[^\\/]*$/, "")
            settings.lastPath = dir
        }
        settings.lastFilter = selectedNameFilter

        if (selectedFile) {
            var urlStr = selectedFile.toString()
            var localPath = urlStr
            if (urlStr.startsWith("file:///")) {
                localPath = urlStr.slice(8)
            } else if (urlStr.startsWith("file://")) {
                 localPath = urlStr.slice(7)
            }
            var dir = localPath.replace(/[^\\/]*$/, "")
            settings.lastPath = dir
        }
        settings.lastFilter = selectedNameFilter
    }

    Component.onCompleted: {
        var startPath = settings.lastPath || Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation) || ""
        navigateTo(startPath)

        if (settings.lastFilter && nameFilters.includes(settings.lastFilter)) {
            selectedNameFilter = settings.lastFilter
        }
    }

    // === Places ===
    readonly property var places: [
        { name: qsTr("Computer"), path: "file:///" },
        { name: qsTr("Home"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation) },
        { name: qsTr("Desktop"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation) },
        { name: qsTr("Documents"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation) },
        { name: qsTr("Downloads"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation) },
        { name: qsTr("Music"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation) },
        { name: qsTr("Pictures"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.PicturesLocation) },
        { name: qsTr("Videos"), path: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation) }
    ]

    // === Model ===
    FolderListModel {
        id: folderModel
        folder: "file:///" + currentPath
        showDirsFirst: true
        showDotAndDotDot: false
        nameFilters: control._parseNameFilter(selectedNameFilter)
    }

    function _parseNameFilter(filter) {
        var m = filter.match(/\(([^)]+)\)/)
        if (m) {
            return m[1].split(/\s+/).filter(s => s.trim().startsWith("*"))
        }
        return ["*"]
    }

    function _cleanPath(path) {
        var p = path.toString().replace(/\\/g, "/")
        if (p.startsWith("file:///")) p = p.slice(8)
        else if (p.startsWith("file://")) p = p.slice(7)
        
        // Uppercase drive letter for Windows consistency
        if (p.length > 1 && p[1] === ':') {
            p = p[0].toUpperCase() + p.slice(1)
        }
        return p
    }

    function navigateTo(path) {
        currentPath = _cleanPath(path)
        fileNameInput = ""
    }

    function _ensureFileUrl(path) {
        return "file:///" + _cleanPath(path)
    }

    // === UI ===
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge // Add margins to reduce crowding
        spacing: Theme.spacingLarge // Increase spacing between main sections

        // Address Bar / Breadcrumbs
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingNormal // Increase spacing in row

            // Breadcrumb View
            RPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                padding: 0
                
                ListView {
                    id: breadcrumbView
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSmall
                    orientation: ListView.Horizontal
                    spacing: 2
                    
                    model: {
                        if (currentPath === "") return ["Computer"]
                        
                        var path = currentPath.replace(/\\/g, "/")
                        if (path.endsWith("/")) path = path.slice(0, -1)
                        
                        var displayParts = ["Computer"]
                        var rawParts = path.split("/")
                        
                        for (var i = 0; i < rawParts.length; i++) {
                            var p = rawParts[i]
                            if (p === "") continue
                            if (p.endsWith(":")) p += "/"
                            displayParts.push(p)
                        }
                        return displayParts
                    }
                    
                    delegate: RButton {
                        text: modelData
                        isIconOnly: false
                        flat: true
                        height: 36
                        customBackgroundColor: "transparent"
                        customAccentColor: Theme.surfaceHighlight
                        
                        // Custom hover effect for breadcrumbs
                        background: Rectangle {
                            radius: Theme.radiusSmall
                            color: parent.hovered ? Theme.surfaceHighlight : "transparent"
                            border.width: 0
                            
                            layer.enabled: parent.hovered
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 1
                                radius: 4
                                samples: 9
                                color: "#40000000"
                            }
                        }
                        
                        onClicked: {
                            if (index === 0) {
                                navigateTo("file:///")
                                return
                            }
                            
                            var newPath = ""
                            for (var i = 1; i <= index; i++) {
                                var part = breadcrumbView.model[i]
                                if (newPath.length > 0 && !newPath.endsWith("/")) newPath += "/"
                                newPath += part
                            }
                            navigateTo(newPath)
                        }
                    }
                }
            }

            RButton {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                icon.source: checked ? "qrc:/qt/qml/RenkoUI/assets/icons/eye.svg" : "qrc:/qt/qml/RenkoUI/assets/icons/eye-off.svg"
                icon.width: 20
                icon.height: 20
                isIconOnly: true
                checkable: true
                checked: folderModel.showHidden
                onCheckedChanged: folderModel.showHidden = checked
                tooltip: checked ? qsTr("Hide Hidden Files") : qsTr("Show Hidden Files")
                
                // Visual indicator for checked state
                customAccentColor: checked ? Theme.accent : Theme.surfaceHighlight
            }
            
            RButton {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                icon.source: "qrc:/qt/qml/RenkoUI/assets/icons/refresh.svg"
                icon.width: 20
                icon.height: 20
                isIconOnly: true
                tooltip: qsTr("Refresh")
                onClicked: {
                    folderModel.folder = ""
                    folderModel.folder = Qt.binding(function() { return "file:///" + currentPath })
                }
            }
        }

        // Main Content
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingLarge

            // Places
            ListView {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                clip: true
                model: control.places
                delegate: ItemDelegate {
                    width: ListView.view.width
                    text: modelData.name
                    
                    contentItem: RLabel {
                        text: modelData.name
                        color: parent.highlighted ? Theme.textInverse : Theme.text
                    }
                    
                    background: Rectangle {
                        color: parent.highlighted ? Theme.accent : 
                               parent.hovered ? Theme.surfaceHighlight : "transparent"
                        radius: Theme.radiusSmall
                    }
                    
                    highlighted: ListView.isCurrentItem
                    onClicked: {
                        ListView.view.currentIndex = index
                        if (modelData.path) navigateTo(modelData.path)
                    }
                }
            }

            // File List
            RPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 1
                
                ListView {
                    id: fileListView
                    anchors.fill: parent
                    clip: true
                    model: folderModel
                    keyNavigationEnabled: true

                    property var selectedIndexes: []

                    function isSelected(idx) {
                        return selectedIndexes.includes(idx)
                    }

                    function clearSelection() {
                        selectedIndexes = []
                    }

                    function toggleSelection(idx, multi) {
                        var isDir = folderModel.get(idx, "fileIsDir")
                        var fName = folderModel.get(idx, "fileName")

                        if (control.fileMode !== control.openFiles) {
                            selectedIndexes = [idx]
                            control.selectedFile = control._ensureFileUrl(folderModel.get(idx, "filePath"))
                            if (!isDir) control.fileNameInput = fName
                            return
                        }
                        if (multi && isSelected(idx)) {
                            selectedIndexes.splice(selectedIndexes.indexOf(idx), 1)
                        } else {
                            if (!multi) clearSelection()
                            if (!isSelected(idx)) selectedIndexes.push(idx)
                        }
                        if (selectedIndexes.length > 0) {
                            control.selectedFile = control._ensureFileUrl(folderModel.get(selectedIndexes[0], "filePath"))
                            if (selectedIndexes.length === 1 && !folderModel.get(selectedIndexes[0], "fileIsDir")) {
                                control.fileNameInput = folderModel.get(selectedIndexes[0], "fileName")
                            }
                        } else {
                            control.selectedFile = undefined
                        }
                    }

                    delegate: ItemDelegate {
                        id: delegateItem
                        width: ListView.view.width
                        height: 34
                        
                        highlighted: fileListView.isSelected(index)
                        hoverEnabled: true

                        background: Rectangle {
                            color: highlighted ? Theme.selectionLight :
                                   hovered ? Theme.surfaceHighlight : "transparent"
                            radius: Theme.radiusSmall
                            
                            layer.enabled: highlighted
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 1
                                radius: 6
                                samples: 13
                                color: "#809E9E9E" // Light gray shadow (semi-transparent)
                            }
                        }

                        contentItem: Row {
                            spacing: Theme.spacingNormal
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: Theme.spacingSmall

                            Rectangle {
                                width: 16; height: 16
                                radius: 2
                                color: fileIsDir ? Theme.accent : Theme.secondary
                            }

                            RLabel {
                                text: fileName
                                color: highlighted ? Theme.text : Theme.text // Text color on light selection
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: {
                            var multi = Qt.keyboardModifiers & (Qt.ControlModifier | Qt.ShiftModifier)
                            fileListView.toggleSelection(index, multi)
                        }

                        onDoubleClicked: {
                            if (!fileIsDir) {
                                control.selectedFile = control._ensureFileUrl(filePath)
                                control.accept()
                            } else {
                                var localPath = filePath.toString()
                                if (localPath.startsWith("file:///")) {
                                    localPath = localPath.slice(8)
                                }
                                control.navigateTo(localPath)
                            }
                        }
                    }
                    
                    ScrollBar.vertical: RScrollBar {}
                }
            }
        }

        // File Name Input (Always Visible)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingNormal
            
            RLabel {
                text: qsTr("File name:")
            }
            
            RTextField {
                id: saveField
                Layout.fillWidth: true
                placeholderText: qsTr("File name")
                text: fileNameInput
                onTextChanged: fileNameInput = text
                onAccepted: control.accept()
            }
            
            RComboBox {
                Layout.preferredWidth: 200
                model: control.nameFilters
                currentIndex: control.nameFilters.indexOf(control.selectedNameFilter)
                onCurrentTextChanged: selectedNameFilter = currentText
            }
        }

        // Buttons
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.spacingLarge

            RButton {
                text: fileMode === saveFile ? qsTr("Save") : qsTr("Open")
                enabled: {
                    if (fileMode === saveFile) {
                        return saveField.text.trim() !== ""
                    } else {
                        return control.selectedFile !== undefined || (saveField.text.trim() !== "")
                    }
                }
                onClicked: {
                    // If text field has content but no file selected in list, try to use text field
                    if (!control.selectedFile && saveField.text.trim() !== "") {
                         var path = currentPath + (currentPath.endsWith("/") ? "" : "/") + saveField.text.trim()
                         control.selectedFile = control._ensureFileUrl(path)
                    }
                    control.accept()
                }
                Keys.onReturnPressed: control.accept()
                Keys.onEnterPressed: control.accept()
            }

            RButton {
                text: qsTr("Cancel")
                onClicked: control.reject()
                Keys.onEscapePressed: control.reject()
            }
        }
    }
}
