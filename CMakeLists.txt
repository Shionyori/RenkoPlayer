cmake_minimum_required(VERSION 3.20)

project(RenkoPlayer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Standard Qt Project Setup (Handles deployment, resources, etc.)
# Requires Qt 6.3+
find_package(Qt6 REQUIRED COMPONENTS BuildInternals Core Gui Qml Quick OpenGL)
qt_standard_project_setup()

# FFmpeg Setup (Provided by vcpkg)
find_package(FFMPEG REQUIRED)

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
    ${FFMPEG_LIBRARIES}
)

# Ensure Qt plugins are deployed (Critical for Windows)
if(WIN32)
    # Copy the 'platforms' plugin directory to the executable directory
    # This is the most reliable way to ensure Qt finds the windows plugin
    add_custom_command(TARGET RenkoPlayer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:RenkoPlayer>/platforms"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<IF:$<CONFIG:Debug>,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/debug/Qt6/plugins/platforms/qwindowsd.dll,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/Qt6/plugins/platforms/qwindows.dll>"
            "$<TARGET_FILE_DIR:RenkoPlayer>/platforms/"
        COMMENT "Copying Qt platforms plugin..."
    )
    
    # Also copy qml directory for QML modules
    add_custom_command(TARGET RenkoPlayer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "$<IF:$<CONFIG:Debug>,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/debug/Qt6/qml,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/Qt6/qml>"
            "$<TARGET_FILE_DIR:RenkoPlayer>/../qml" 
        COMMENT "Copying QML modules..."
    )
endif()

target_include_directories(RenkoPlayer PRIVATE ${FFMPEG_INCLUDE_DIRS})
target_link_directories(RenkoPlayer PRIVATE ${FFMPEG_LIBRARY_DIRS})

# Windows: Ensure console is hidden in release, but shown in debug if needed
# set_target_properties(RenkoPlayer PROPERTIES WIN32_EXECUTABLE ON)
