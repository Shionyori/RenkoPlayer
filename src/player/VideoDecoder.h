#pragma once

#include <string>
#include <thread>
#include <atomic>
#include <functional>
#include <mutex>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

class VideoDecoder {
public:
    struct Frame {
        uint8_t* data[4];
        int linesize[4];
        int width;
        int height;
        double pts;
    };

    VideoDecoder();
    ~VideoDecoder();

    bool open(const std::string& url);
    void close();
    void play();
    void pause();
    void stop();

    // Callback for new frames
    using FrameCallback = std::function<void(const Frame&)>;
    void setFrameCallback(FrameCallback callback);

    bool isPlaying() const { return m_isPlaying; }
    int getWidth() const { return m_width; }
    int getHeight() const { return m_height; }

private:
    void decodeLoop();
    void freeResources();

    std::string m_url;
    std::atomic<bool> m_isPlaying{false};
    std::atomic<bool> m_stopThread{false};
    std::thread m_decodeThread;

    // FFmpeg context
    AVFormatContext* m_formatCtx = nullptr;
    AVCodecContext* m_codecCtx = nullptr;
    const AVCodec* m_codec = nullptr;
    AVFrame* m_frame = nullptr;
    AVPacket* m_packet = nullptr;
    SwsContext* m_swsCtx = nullptr;

    int m_videoStreamIndex = -1;
    int m_width = 0;
    int m_height = 0;

    FrameCallback m_onFrame;
    std::mutex m_callbackMutex;
};
