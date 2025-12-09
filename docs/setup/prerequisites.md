# 先决条件

本文档列出开发与运行 `RenkoPlayer` 所需的工具与环境。

## 系统
- Windows 10/11（推荐用于开发与测试）
- 可选：Linux / macOS（需自行适配构建工具与依赖）

## 必备工具
- Git
- Visual Studio 2019/2022（含 Desktop C++ 工作负载）或等效的 C++ 编译器工具链
- CMake 3.21+
- vcpkg（推荐，用于下载并管理第三方依赖）

## 运行时依赖
- Qt 6 运行时（如果不使用内置的 vcpkg 运行时）
- FFmpeg（项目通过 FFmpeg 整合媒体解码，若未静态链接需在运行环境中提供）

## 可选工具（开发便利）
- VSCode（用于快速编辑）
- PowerShell（Windows 下常用脚本/命令）

## 环境变量（可选）
- `VCPKG_ROOT`：vcpkg 安装目录（便于脚本/命令引用）
- `QML2_IMPORT_PATH`：当希望统一设置 QML 模块路径时可使用

如果你计划从文件系统加载 QML（在开发中常见），请确保构建步骤将 `src/qml` 或构建输出的 `qml` 目录放到可执行旁的合适位置，或者在 `main.cpp` 中通过 `engine.addImportPath()` 添加对应路径。