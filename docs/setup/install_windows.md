# 在 Windows 上的安装与本地构建

本页介绍在 Windows 环境下把 RenkoPlayer 拉取、配置并本地构建运行的典型步骤，基于 CMake 与 vcpkg。

## 克隆仓库
```powershell
git clone https://github.com/Shionyori/RenkoPlayer.git
cd RenkoPlayer
```

## 安装 vcpkg（如未安装）
```powershell
cd C:\Tools
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
```

## 使用 vcpkg 安装依赖（推荐）
```powershell
$env:VCPKG_ROOT = 'C:\Tools\vcpkg' # 请按实际路径调整
& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet x64-windows
```

## 配置并构建（Release 示例）
```powershell
cmake -S . -B build\windows-release -A x64 `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
  -DCMAKE_BUILD_TYPE=Release
cmake --build build\windows-release --config Release -- /m
```

## 运行
- 通过 Visual Studio 打开 `build\windows-release\RenkoPlayer.sln` 并运行，或直接运行生成的可执行：

```powershell
& .\build\windows-release\RenkoPlayer\Release\RenkoPlayer.exe
```

注意：路径会根据 CMake 配置与构建器（MSBuild / Visual Studio）略有不同，请在你的构建目录中确认实际可执行的位置。

## （开发）启用文件系统 QML 加载
若希望在开发时直接从源码目录看到 QML 变更而无需重新打包到 qrc，可按两种方式：

1. 在 `CMakeLists.txt` 中添加 `copy_qml` 任务，把 `src/qml` 复制到 `${CMAKE_BINARY_DIR}/qml`，并确保 `main.cpp` 中的 `engine.addImportPath(applicationDir + "/../qml")` 生效。
2. 临时修改 `main.cpp` 使用 `engine.load(QUrl::fromLocalFile(...))` 指向本地 `src/qml/main.qml`（仅用于测试，发布前请恢复为 qrc）。

## 疑难排查
- 如果出现找不到模块 `import ...` 错误，检查 `build\qml` 或 `src/qml` 是否存在，并确认 `qmldir` 或 qml 文件结构正确。
- 若缺少 Qt 模块或运行时错误，确认系统安装了 Qt 运行时或通过 vcpkg 正确链接。