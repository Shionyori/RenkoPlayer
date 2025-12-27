cmake_minimum_required(VERSION 3.20)

project(RenkoUI LANGUAGES CXX)

# Set Qt Policies to NEW to avoid warnings
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Svg)

qt_add_library(RenkoUI STATIC)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(RenkoUI
    URI RenkoUI
    VERSION 1.0
    SOURCES
        src/FileSystemHelper.h
        src/FileSystemHelper.cpp
    QML_FILES
        qml/Theme.qml
        qml/RWindow.qml
        qml/RDialog.qml
        qml/RMessageDialog.qml
        qml/RFileDialog.qml
        qml/RButton.qml
        qml/RToolButton.qml
        qml/RSwitch.qml
        qml/RCheckBox.qml
        qml/RComboBox.qml
        qml/RPanel.qml
        qml/RLabel.qml
        qml/RTextField.qml
        qml/RMenu.qml
        qml/RMenuBar.qml
        qml/RMenuItem.qml
        qml/RProgressBar.qml
        qml/RSlider.qml
        qml/RScrollBar.qml
    RESOURCES
        assets/icons/eye.svg
        assets/icons/eye-off.svg
        assets/icons/refresh.svg
)

target_link_libraries(RenkoUI
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Svg
)

target_include_directories(RenkoUI PUBLIC src)