# RenkoPlayer

一个基于 **C++20**、**Qt 6** 和 **FFmpeg** 构建的视频播放器。

## 技术栈
- **语言**: C++20
- **框架**: Qt 6.9.1 (Core, Gui, Qml, Quick, OpenGL)
- **媒体引擎**: FFmpeg 7.1
- **构建系统**: CMake 3.20+
- **包管理器**: vcpkg

## 开发环境搭建 (Windows)

### 前置要求
1.  **Visual Studio 2022** (需安装 C++ 桌面开发工作负载)。
2.  **Visual Studio Code** (需安装 CMake Tools 和 C++ 插件)。
3.  **vcpkg**: 已安装并集成到系统或 VS Code 中。

### 构建指南
本项目使用 **vcpkg Manifest Mode**，你**不需要**手动运行 `vcpkg install`，CMake 会在配置阶段自动处理所有依赖。

#### 方式一：使用 VS Code (推荐)
1.  **克隆仓库**:
    ```bash
    git clone https://github.com/Shionyori/RenkoPlayer.git
    cd RenkoPlayer
    code .
    ```

2.  **配置 CMake**:
    *   在 VS Code 底部状态栏选择构建预设：**"Visual Studio 17 2022 Release - x64"**。
    *   *注意*: 首次配置可能需要较长时间（30-60分钟），因为 vcpkg 需要从源码编译 Qt6 和 FFmpeg。

3.  **编译与运行**:
    *   按 `F7` 进行编译。
    *   按 `F5` 启动调试。

#### 方式二：使用命令行 (CLI)
如果你更喜欢使用终端，请确保已安装 CMake 和 vcpkg，并正确设置了环境变量。

1.  **配置 (Configure)**:
    请将 `[path/to/vcpkg]` 替换为你本地的 vcpkg 安装路径。
    ```powershell
    cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[path/to/vcpkg]/scripts/buildsystems/vcpkg.cmake
    ```

2.  **构建 (Build)**:
    ```powershell
    cmake --build build --config Release
    ```

3.  **运行 (Run)**:
    ```powershell
    .\build\Release\RenkoPlayer.exe
    ```

## 项目结构
```text
RenkoPlayer/
├── src/
│   ├── player/          # FFmpeg 解码核心逻辑
│   ├── ui/              # QML 集成 (VideoRenderItem)
│   ├── resources/       # QML 文件与资源
│   └── main.cpp         # 程序入口
├── docs/
│   └── dev_logs/        # 开发日志与故障排查记录
├── vcpkg.json           # 依赖清单文件
└── CMakeLists.txt       # CMake 构建配置
```

## 文档
请查看 [docs/dev_logs](./docs/dev_logs/) 目录获取详细的开发日志和故障排查过程。

## 待办事项
- [ ] 增加播放列表和用户界面功能
- [ ] 修复开启3D模式时显示的是上一个视频的问题
- [ ] 修复输入不正确的rtsp地址时程序无响应的问题