# RenkoPlayer

A modern, C++ based video player using Qt 6 and FFmpeg.

## Features
- **Modern UI**: Built with Qt Quick (QML) for a fluid, dark-themed interface.
- **Powerful Backend**: Uses FFmpeg for decoding, supporting a wide range of formats and network streams.
- **Streaming Support**: Capable of playing RTSP, RTMP, HLS, and HTTP streams directly.
- **Architecture**: Clean separation between the C++ decoding core and the QML UI.

## Prerequisites

To build this project, you need:
1.  **C++ Compiler** (MSVC, GCC, or Clang) supporting C++20.
2.  **CMake** (3.20+).
3.  **Qt 6** (Core, Gui, Qml, Quick, OpenGL modules).
4.  **FFmpeg** (Development libraries: avcodec, avformat, avutil, swscale).

### Installing Dependencies (Windows via vcpkg)

It is highly recommended to use `vcpkg` to manage dependencies.

1.  Install vcpkg:
    ```powershell
    git clone https://github.com/microsoft/vcpkg
    .\vcpkg\bootstrap-vcpkg.bat
    ```
2.  Install libraries:
    ```powershell
    .\vcpkg\vcpkg install qtbase qtdeclarative ffmpeg opengl --triplet x64-windows
    ```

## Build Instructions

1.  Open the project folder in VS Code or a terminal.
2.  Configure with CMake (assuming vcpkg toolchain usage):
    ```powershell
    cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[path/to/vcpkg]/scripts/buildsystems/vcpkg.cmake
    ```
3.  Build:
    ```powershell
    cmake --build build --config Release
    ```
4.  Run:
    ```powershell
    .\build\Release\RenkoPlayer.exe
    ```

## Project Structure

- `src/main.cpp`: Application entry point.
- `src/player/`: Core video decoding logic (FFmpeg wrapper).
- `src/ui/`: QML integration and rendering classes.
- `src/resources/qml/`: QML UI files.

## Notes
- This is a demo implementation. Audio synchronization is not implemented in this basic version (video only).
- Ensure FFmpeg DLLs are in the executable directory if not automatically copied.
