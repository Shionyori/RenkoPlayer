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
#include <libswresample/swresample.h>
#include <libavutil/imgutils.h>
#include <libavutil/time.h>
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

    // Time control
    double getDuration() const;
    void seek(double seconds);

    // Audio Support
    int getAudioData(uint8_t* data, int max_size);
    bool hasAudio() const { return m_audioStreamIndex >= 0; }
    double getAudioClock() const { return m_audioClock; }

    // Callback for new frames
    using FrameCallback = std::function<void(const Frame&)>;
    void setFrameCallback(FrameCallback callback);
    
    // Add error callback
    using ErrorCallback = std::function<void(const std::string&)>;
    void setErrorCallback(ErrorCallback callback);

    bool isPlaying() const { return m_isPlaying; }
    bool isStopped() const { return m_stopThread; }
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
    
    // Video
    AVCodecContext* m_codecCtx = nullptr;
    const AVCodec* m_codec = nullptr;
    AVFrame* m_frame = nullptr;
    AVPacket* m_packet = nullptr;
    SwsContext* m_swsCtx = nullptr;
    int m_videoStreamIndex = -1;
    int m_width = 0;
    int m_height = 0;
    double m_duration = 0.0;
    std::atomic<double> m_seekTarget{-1.0};

    // Audio
    int m_audioStreamIndex = -1;
    AVCodecContext* m_audioCodecCtx = nullptr;
    const AVCodec* m_audioCodec = nullptr;
    SwrContext* m_swrCtx = nullptr;
    std::vector<uint8_t> m_audioBuffer;
    std::mutex m_audioMutex;
    std::atomic<double> m_audioClock{0.0};

    FrameCallback m_onFrame;
    ErrorCallback m_onError;
    std::mutex m_callbackMutex;
    std::mutex m_apiMutex;
};
