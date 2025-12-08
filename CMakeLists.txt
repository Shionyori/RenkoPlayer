cmake_minimum_required(VERSION 3.20)

project(RenkoPlayer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Standard Qt Project Setup (Handles deployment, assets, etc.)
# Requires Qt 6.3+
find_package(Qt6 REQUIRED COMPONENTS BuildInternals Core Gui Qml Quick QuickControls2 OpenGL Multimedia Svg)
qt_standard_project_setup()

# Set Qt Policies to NEW to avoid warnings
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

# FFmpeg Setup (Provided by vcpkg)
find_package(FFmpeg REQUIRED COMPONENTS avcodec avformat avutil swscale swresample)

# Manually find swscale and swresample as the FindFFmpeg module might not export them correctly
find_library(SWSCALE_LIB NAMES swscale libswscale REQUIRED)
find_library(SWRESAMPLE_LIB NAMES swresample libswresample REQUIRED)

# Define the executable with Qt's wrapper
qt_add_executable(RenkoPlayer
    src/main.cpp
    src/core/VideoDecoder.cpp
    src/core/VideoDecoder.h
    src/ui/VideoRenderItem.cpp
    src/ui/VideoRenderItem.h
    src/ui/PanoramaRenderItem.cpp
    src/ui/PanoramaRenderItem.h
    assets/RenkoPlayer.rc
)

# QML Module Definition
qt_add_qml_module(RenkoPlayer
    URI RenkoPlayer
    VERSION 1.0
    QML_FILES
        src/qml/main.qml
    RESOURCES
        assets/icons/app.ico
        assets/icons/play.svg
        assets/icons/pause.svg
        assets/icons/stop.svg
)

# Link Libraries
target_link_libraries(RenkoPlayer
    PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::OpenGL
    Qt6::Multimedia
    Qt6::Svg
    ${FFMPEG_LIBRARIES}
    ${SWSCALE_LIB}
    ${SWRESAMPLE_LIB}
)

# Ensure Qt plugins are deployed (Critical for Windows)
if(WIN32)
    # Modern Approach: Use qt.conf to point to existing Qt plugins/QML instead of copying them.
    # This saves disk space and build time.
    # Generate qt.conf at build time (POST_BUILD) so it only is created for the active configuration.
    add_custom_command(TARGET RenkoPlayer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "[Paths]" > "$<TARGET_FILE_DIR:RenkoPlayer>/qt.conf"
        COMMAND ${CMAKE_COMMAND} -E echo "Prefix=$<IF:$<CONFIG:Debug>,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/debug/Qt6,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/Qt6>" >> "$<TARGET_FILE_DIR:RenkoPlayer>/qt.conf"
        COMMAND ${CMAKE_COMMAND} -E echo "Plugins=plugins" >> "$<TARGET_FILE_DIR:RenkoPlayer>/qt.conf"
        COMMAND ${CMAKE_COMMAND} -E echo "Qml2Imports=qml" >> "$<TARGET_FILE_DIR:RenkoPlayer>/qt.conf"
        COMMENT "Generating qt.conf..."
    )

    # Copy all runtime DLLs (Qt, FFmpeg, etc.) to the executable directory
    # This allows the executable to be run directly (double-click) without setting PATH.
    add_custom_command(TARGET RenkoPlayer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "$<IF:$<CONFIG:Debug>,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/debug/bin,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/bin>"
            "$<TARGET_FILE_DIR:RenkoPlayer>"
        COMMENT "Copying runtime DLLs..."
    )
endif()

target_include_directories(RenkoPlayer PRIVATE ${FFMPEG_INCLUDE_DIRS})
target_link_directories(RenkoPlayer PRIVATE ${FFMPEG_LIBRARY_DIRS})

# Windows: Ensure console is hidden in release, but shown in debug if needed
# set_target_properties(RenkoPlayer PROPERTIES WIN32_EXECUTABLE ON)
