# 2025-11-27 开发日志：环境搭建与核心崩溃问题排查

## 1. 工作概述
本次工作的核心目标是初始化 **RenkoPlayer** 项目，并搭建基于 **Windows + VS Code + CMake + vcpkg** 的现代化 C++ 开发环境。
经过调试，成功解决了构建工具链配置、Qt 运行时插件缺失以及 QML 资源加载失败等关键问题，目前项目已能正常编译并启动 UI。

## 2. 技术栈与环境
*   **OS**: Windows 11 (x64)
*   **IDE**: Visual Studio Code
*   **编译器**: MSVC (Visual Studio 2022 Build Tools)
*   **构建系统**: CMake 3.20+ (Generator: Visual Studio 17 2022)
*   **包管理**: vcpkg (Manifest Mode)
*   **核心框架**: 
    *   Qt 6.9.1 (Core, Gui, Qml, Quick, OpenGL)
    *   FFmpeg 7.1 (avcodec, avformat, swscale)

## 3. 遇到的核心问题与排查过程

### 3.1 构建配置：Ninja 无法找到 MSVC 环境
*   **问题现象**: 
    使用默认的 `Ninja` 生成器配置 CMake 时，报错 `CMAKE_CXX_COMPILER not set`，无法找到 `cl.exe`。
*   **根本原因**: 
    Ninja 依赖于外部环境提供的编译器路径（通常需要在 Developer Command Prompt 中运行），而 VS Code 直接启动时未继承这些环境变量。
*   **解决方案**: 
    放弃 Ninja，改用 **Visual Studio 17 2022** 生成器。这会生成 `.sln` 解决方案文件，由 CMake 自动处理 MSVC 的环境查找和配置。
    *   *操作*: 修改 `CMakePresets.json` 或 CMake 配置命令。

### 3.2 运行时崩溃：Qt 平台插件 (qwindows.dll) 缺失
*   **问题现象**: 
    编译成功后运行，弹出 "Debug Error!" 对话框，控制台输出：
    `qt.qpa.plugin: Could not find the Qt platform plugin "windows" in ""`
*   **根本原因**: 
    1.  Qt 程序启动时需要加载平台插件（`qwindows.dll`），默认查找路径为可执行文件同级的 `platforms/` 目录。
    2.  vcpkg 将 DLL 安装在 `vcpkg_installed` 深层目录中，不会自动部署到构建输出目录。
    3.  **版本陷阱**: Debug 模式编译的程序必须链接 `qwindowsd.dll` (带 `d`)，Release 模式链接 `qwindows.dll`。混用会导致加载失败。
*   **尝试过的方案**:
    *   *方案一（失败）*: 生成 `qt.conf` 指定 Prefix。虽然能解决路径问题，但不够灵活，且容易与系统环境变量冲突。
    *   *方案二（成功）*: 使用 CMake 的 `POST_BUILD` 命令，在编译完成后自动将对应的 DLL 复制到 `bin/platforms/` 目录。

### 3.3 启动即退出：QML 资源路径错误
*   **问题现象**: 
    解决了插件问题后，程序启动后窗口未显示即退出，日志提示 `QQmlApplicationEngine failed to load component`，或者无任何报错直接结束。
*   **根本原因**: 
    CMake 的 `qt_add_qml_module` 宏会将 QML 文件打包进二进制资源（qrc），但其生成的资源路径前缀（Prefix）并不直观。
    我们预想的路径是 `qrc:/qt/qml/RenkoPlayer/main.qml`，但实际生成的路径是 `qrc:/RenkoPlayer/src/resources/qml/main.qml`。
*   **排查手段**: 
    在 `main.cpp` 中临时加入 `QDirIterator` 代码，遍历并打印 `qrc:/` 下的所有文件，从而找到了真实路径。
    ```cpp
    // 调试代码片段
    QDirIterator it(":", QDirIterator::Subdirectories);
    while (it.hasNext()) qDebug() << it.next();
    ```

## 4. 关键配置变更

### `CMakeLists.txt` (最终生效版)
重点在于 FFmpeg 的查找链接和 Qt 插件的自动复制：
```cmake
# FFmpeg 链接
find_package(FFMPEG REQUIRED)
target_link_libraries(RenkoPlayer PRIVATE ${FFMPEG_LIBRARIES})

# Windows 平台插件自动部署
if(WIN32)
    add_custom_command(TARGET RenkoPlayer POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:RenkoPlayer>/platforms"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<IF:$<CONFIG:Debug>,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/debug/Qt6/plugins/platforms/qwindowsd.dll,${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/Qt6/plugins/platforms/qwindows.dll>"
            "$<TARGET_FILE_DIR:RenkoPlayer>/platforms/"
    )
endif()
```

### `vcpkg.json`
```json
{
  "dependencies": [ "qtbase", "qtdeclarative", "qt5compat", "ffmpeg", "opengl" ]
}
```

## 5. 经验总结与注意事项

1.  **vcpkg 缓存**: 修改 `vcpkg.json` 后，建议删除 `build` 目录重新配置 CMake，以确保依赖关系正确更新。
2.  **Qt 插件调试**: 遇到 `qt.qpa.plugin` 错误时，首先检查 `platforms/qwindows(d).dll` 是否存在于 exe 旁。
3.  **QML 路径**: 不要凭感觉猜测资源路径。使用 `QDirIterator` 打印资源树是最高效的排查方法。
4.  **环境变量**: VS Code 的 `.vscode/launch.json` 中配置 `PATH` 环境变量对于加载第三方 DLL（如 FFmpeg 的 dll）至关重要。