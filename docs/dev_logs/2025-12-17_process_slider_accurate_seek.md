# 2025-12-17 日志：进度条滑块跳转抖动问题的修复

## 1. 问题原因
这个问题是由于视频播放器默认采用了“关键帧定位”（Keyframe Seek）导致的。
视频编码通常由关键帧（I帧）和非关键帧（P/B帧）组成。为了快速跳转，播放器通常会直接跳转到离目标时间最近的关键帧。如果目标时间是 45秒，而最近的关键帧在 38秒，播放器就会跳转到 38秒并开始播放，导致进度条“回跳”。

## 2. 解决方案
为了解决这个问题，我们实现了“精确定位”（Accurate Seek）功能。具体做法如下：

1. 向后查找关键帧：跳转到目标时间 之前 的关键帧（例如 38秒）。
2. 预解码：从该关键帧开始解码，但 不显示 画面，也不输出音频。
3. 丢弃帧：一直丢弃解码出的帧，直到时间戳达到或超过目标时间（45秒）。
4. 开始播放：一旦达到目标时间，恢复正常的画面显示和音频输出。

## 3. 关键代码/配置变更
### 修改 `VideoDecoder.h`
```cpp
+    double m_skipUntilPts = -1.0;
```

### 修改 `VideoDecoder.cpp`
```cpp
+                            // Check if we need to skip
+                            if (m_skipUntilPts >= 0.0) {
+                                if (f.pts < m_skipUntilPts - 0.05) { // Allow small tolerance
+                                    continue; // Skip this frame
+                                }
+                                m_skipUntilPts = -1.0; // Reached target, stop skipping
+                            }
```

```cpp
+                        // Check if we need to skip audio
+                        if (m_skipUntilPts >= 0.0) {
+                             AVRational tb = m_formatCtx->streams[m_audioStreamIndex]->time_base;
+                             double audioPts = (tb.num && tb.den) ? m_frame->pts * av_q2d(tb) : 0.0;
+                             if (audioPts < m_skipUntilPts - 0.1) {
+                                 continue;
+                             }
+                        }
```

```cpp
+    m_skipUntilPts = -1.0;
```

## 4. 其他
此改动有效提升了用户体验，进度条跳转更加准确流畅，避免了因关键帧定位带来的视觉不适。
但是，这种方法会增加解码负担，尤其是在高分辨率视频上，可能会导致跳转时的短暂卡顿。未来可以考虑引入更智能的缓冲和预加载机制以进一步优化性能。