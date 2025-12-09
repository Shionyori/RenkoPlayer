# 发布与部署建议

本页概述如何为 RenkoPlayer 制作发布包并部署到目标机器。

## 打包策略（两种常用方式）

### 1. 单一可执行（推荐，使用 qrc）
- 将 QML 与资源打包到 Qt 的资源文件（`.qrc`），从 `qrc:/...` 路径加载主 QML。这样可减少部署时缺少文件的问题。
- 打包时将所需的动态库与运行时一起打包（例如 Qt 运行时、ffmpeg 的 DLL，如果未静态链接）。使用工具如 `windeployqt` 来收集 Qt 相关 DLL。

示例发布步骤（Windows）：
1. 使用 Release 构建（详见 `docs/tutorials/build.md`）。
2. 使用 `windeployqt` 收集 Qt 运行时依赖：
```powershell
& "C:\Qt\6.x\msvc2019_64\bin\windeployqt.exe" .\RenkoPlayer.exe
```
3. 把 `RenkoPlayer.exe`、相关 DLL、资源文件和必要的 run-time 放到一个目录，打包为 zip 或安装器。

### 2. 外部 QML 目录（插件/扩展场景）
- 如果你希望用户或第三方能替换/扩展 QML，可以将 QML 保持在应用目录的 `qml` 子目录，并在运行时通过 `engine.addImportPath()` 指向它。部署时把 `qml` 目录与可执行一起发布。
- 注意：在这种部署下，必须保证 `qmldir` 与模块结构正确，且不要忘记随部署一并提供所需的 DLL。

## 生成安装程序
- 可使用诸如 `Inno Setup`、`NSIS` 或商业安装工具制作 Windows 安装程序，把可执行、依赖 DLL、`qml`（如果外部 QML）、图标、快捷方式和注册表项一起打包。

## 测试发布包
- 在干净的虚拟机或基线系统中测试发布包，确认：
  - 可执行能启动并正确加载 QML（qrc 或外部 qml）。
  - 所有媒体播放功能（依赖 ffmpeg 等）正常。

## 常见问题
- 缺少 Qt DLL 或平台插件（如 `platforms/qwindows.dll`）：使用 `windeployqt` 或手动复制 `platforms` 目录。
- QML 模块未找到：确认 `qmldir` 文件位置正确，或主 QML 使用 `qrc` 并且资源正确打包。

---

如果你希望，我可以把 `windeployqt` 的使用示例加入 `CMakeLists.txt` 后的发布脚本（PowerShell），或者帮你在 CMake 中添加一个 `install` 目标，把必要文件拷贝到 `dist` 目录以便打包。