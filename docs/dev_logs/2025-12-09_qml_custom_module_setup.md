# 2025-12-09 开发日志：QML 自定义模块设置与目录结构规范化

## 1. 变更概述
本次工作目标是为 RenkoPlayer 项目建立规范的 QML 自定义模块机制，确保 `VideoRenderItem` 和 `PanoramaRenderItem` 能以标准方式在 QML 中使用（`import RenkoPlayer 1.0`）。重点解决模块注册、路径配置与项目目录结构规范化问题，避免依赖 Qt 的非标准 fallback 行为。

## 2. 遇到的问题
- **问题描述**: 虽然 `qmlRegisterType` 使 QML 能识别 `VideoRenderItem`，但未提供 `qmldir` 文件，导致：
  - `import RenkoPlayer 1.0` 实际上未被 QML 引擎正式识别；
  - Qt Creator 无法提供类型智能提示；
  - 未来 Qt 版本可能存在兼容性风险。
- **根本原因**: 项目缺少标准 QML 模块结构（`qml/RenkoPlayer/qmldir`），且 `qml/` 目录位置与构建输出路径未对齐。
- **解决方案**:
  1. 在项目根目录创建标准模块目录 `qml/RenkoPlayer/`；
  2. 添加最简 `qmldir` 文件（内容：`module RenkoPlayer`）；
  3. 配置 CMake 在构建后将 `qml/` 复制到 `build/windows-release/qml/`（与 `Release/` 同级）；
  4. 在 `main.cpp` 中使用 `QDir(applicationDirPath() + "/../qml").absolutePath()` 添加 import 路径。

## 3. 关键代码/配置变更
- **新增文件**:
  - `qml/RenkoPlayer/qmldir`:
    ```qmldir
    module RenkoPlayer
    ```
- **CMakeLists.txt**:
  ```cmake
  set(QML_DEST_DIR "$<TARGET_FILE_DIR:RenkoPlayer>/../qml")
  add_custom_command(TARGET RenkoPlayer POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/qml" "${QML_DEST_DIR}"
      COMMENT "Copying QML modules to build directory"
  )
  ```
- **main.cpp**:
  ```cpp
  qmlRegisterType<VideoRenderItem>("RenkoPlayer", 1, 0, "VideoRenderItem");
  qmlRegisterType<PanoramaRenderItem>("RenkoPlayer", 1, 0, "PanoramaRenderItem");
  
  QQmlApplicationEngine engine;
  QString localQmlPath = QDir(QCoreApplication::applicationDirPath() + "/../qml").absolutePath();
  engine.addImportPath(localQmlPath);
  ```