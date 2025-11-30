# 2025-11-30 开发日志：Qt 部署优化与策略修复

## 1. 变更概述
本次主要修复了图标加载问题，优化了 Qt 部署策略（使用 `qt.conf`），并适配了 Qt 6 的新构建策略标准，消除了 CMake 警告。

## 2. 核心修复内容
*   **图标加载修复**: 引入 `qt.conf` 明确插件路径，解决因环境变量干扰导致的 `imageformats` 插件加载失败问题。
*   **部署策略优化**: 废弃了笨重的“复制插件文件夹”方案，改用生成 `qt.conf` 指向 vcpkg 安装目录，显著提升构建速度并减少磁盘占用。
*   **构建警告消除**: 显式启用 `QTP0001` (QML 模块路径策略) 和 `QTP0004` (隐式依赖策略)，消除了 CMake 配置阶段的警告。
*   **资源路径适配**: 顺应 Qt 6 标准，将 C++ 代码中的资源加载路径迁移至 `/qt/qml/` 前缀，解决了策略变更后的运行时崩溃。

## 3. 关键代码变更

### `CMakeLists.txt`
```cmake
# 启用 Qt 6 新策略
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

### `src/main.cpp`
```cpp
// 适配 Qt 6 标准资源路径 (/qt/qml/...)
app.setWindowIcon(QIcon(":/qt/qml/RenkoPlayer/src/resources/app_icon.png"));
const QUrl url(u"qrc:/qt/qml/RenkoPlayer/src/resources/qml/main.qml"_qs);
```

## 4. 结果
项目构建过程无警告，运行正常，且符合现代 Qt 开发规范。
