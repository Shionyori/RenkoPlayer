# 2025-12-26 修复3D模式渲染残留与RTSP超时问题

## 1. 修复 3D 模式显示上一个视频的问题

### 问题描述
在 3D (全景) 模式下切换视频时，由于 OpenGL 纹理未被及时清除，导致在新视频的第一帧解码完成前，画面仍显示上一个视频的最后一帧。

### 解决方案
*   **修改 `PanoramaRenderItem`**:
    *   引入 `m_resetTexture` 标志位。
    *   在 `setSource()` 被调用时，将 `m_resetTexture` 设为 `true`。
    *   在渲染线程的 `synchronize()` 方法中检查该标志。如果为 `true`，则立即销毁现有的 `m_texture` (OpenGL 纹理)。
    *   这确保了在切换视频源的瞬间，旧画面被清除，避免了画面残留。

## 2. 修复无效 RTSP 地址导致程序无响应

### 问题描述
当用户输入错误的 RTSP 地址或网络不可达时，`avformat_open_input` 会长时间阻塞（默认超时时间很长）。由于加载是在单独的线程中进行的，但 UI 线程在某些操作（如关闭或切换）时需要等待该线程结束 (`join`)，导致主界面卡死。

### 解决方案
*   **修改 `VideoDecoder::open`**:
    *   使用 `AVDictionary` 设置 FFmpeg 的超时参数。
    *   设置 `rw_timeout` (读写超时) 和 `stimeout` (Socket 超时) 为 5,000,000 微秒 (5秒)。
    *   现在，如果 5 秒内无法建立连接，FFmpeg 会返回错误，线程正常退出，避免了程序假死。

## 3. 优化资源释放与模式切换

### 问题描述
在 2D 和 3D 模式之间切换，或打开新文件时，未激活的播放器组件可能仍持有解码器资源或音频设备，导致资源浪费或潜在的冲突。

### 解决方案
*   **C++ 层 (`VideoRenderItem`, `PanoramaRenderItem`)**:
    *   改进 `setSource()` 方法。当传入空的 `source` 字符串时，显式调用 `m_decoder.stop()` 并释放 `QAudioSink` 等音频资源。
*   **QML 层 (`main.qml`)**:
    *   在打开新文件 (`onAccepted`) 时，根据当前模式 (`isPanorama`)，将未使用的播放器 `source` 设为空字符串。
    *   在切换 3D 模式 (`RCheckBox`) 时，先获取当前播放进度，然后将旧模式播放器的 `source` 清空，再在新模式播放器上设置源和进度。
    *   这确保了任何时候只有一个解码器实例在运行，有效管理了内存和系统资源。
