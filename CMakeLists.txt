cmake_minimum_required(VERSION 3.20)

project(RenkoPlayer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Standard Qt Project Setup (Handles deployment, resources, etc.)
# Requires Qt 6.3+
find_package(Qt6 REQUIRED COMPONENTS BuildInternals Core Gui Qml Quick OpenGL)
qt_standard_project_setup()

# FFmpeg Setup (Provided by vcpkg)
find_package(FFmpeg REQUIRED COMPONENTS AVCodec AVFormat AVUtil SwScale)

# Define the executable with Qt's wrapper
qt_add_executable(RenkoPlayer
    src/main.cpp
    src/player/VideoDecoder.cpp
    src/player/VideoDecoder.h
    src/ui/VideoRenderItem.cpp
    src/ui/VideoRenderItem.h
)

# QML Module Definition
qt_add_qml_module(RenkoPlayer
    URI RenkoPlayer
    VERSION 1.0
    QML_FILES
        src/resources/qml/main.qml
)

# Link Libraries
target_link_libraries(RenkoPlayer
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::OpenGL
    FFmpeg::AVCodec
    FFmpeg::AVFormat
    FFmpeg::AVUtil
    FFmpeg::SwScale
)

# Windows: Ensure console is hidden in release, but shown in debug if needed
# set_target_properties(RenkoPlayer PROPERTIES WIN32_EXECUTABLE ON)
