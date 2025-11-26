#include "VideoDecoder.h"
#include <iostream>

VideoDecoder::VideoDecoder() {
    // Initialize network if needed (older ffmpeg versions)
    avformat_network_init();
}

VideoDecoder::~VideoDecoder() {
    stop();
    freeResources();
}

bool VideoDecoder::open(const std::string& url) {
    stop(); // Ensure previous playback is stopped
    m_url = url;

    m_formatCtx = avformat_alloc_context();
    if (avformat_open_input(&m_formatCtx, url.c_str(), nullptr, nullptr) != 0) {
        std::cerr << "Could not open source: " << url << std::endl;
        return false;
    }

    if (avformat_find_stream_info(m_formatCtx, nullptr) < 0) {
        std::cerr << "Could not find stream info" << std::endl;
        return false;
    }

    m_videoStreamIndex = -1;
    for (unsigned int i = 0; i < m_formatCtx->nb_streams; i++) {
        if (m_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            m_videoStreamIndex = i;
            break;
        }
    }

    if (m_videoStreamIndex == -1) {
        std::cerr << "No video stream found" << std::endl;
        return false;
    }

    AVCodecParameters* codecPar = m_formatCtx->streams[m_videoStreamIndex]->codecpar;
    m_codec = avcodec_find_decoder(codecPar->codec_id);
    if (!m_codec) {
        std::cerr << "Unsupported codec" << std::endl;
        return false;
    }

    m_codecCtx = avcodec_alloc_context3(m_codec);
    avcodec_parameters_to_context(m_codecCtx, codecPar);

    if (avcodec_open2(m_codecCtx, m_codec, nullptr) < 0) {
        std::cerr << "Could not open codec" << std::endl;
        return false;
    }

    m_width = m_codecCtx->width;
    m_height = m_codecCtx->height;

    m_frame = av_frame_alloc();
    m_packet = av_packet_alloc();

    // Start decoding thread
    m_stopThread = false;
    m_isPlaying = true;
    m_decodeThread = std::thread(&VideoDecoder::decodeLoop, this);

    return true;
}

void VideoDecoder::close() {
    stop();
}

void VideoDecoder::play() {
    m_isPlaying = true;
}

void VideoDecoder::pause() {
    m_isPlaying = false;
}

void VideoDecoder::stop() {
    m_stopThread = true;
    if (m_decodeThread.joinable()) {
        m_decodeThread.join();
    }
    freeResources();
}

void VideoDecoder::freeResources() {
    if (m_codecCtx) avcodec_free_context(&m_codecCtx);
    if (m_formatCtx) avformat_close_input(&m_formatCtx);
    if (m_frame) av_frame_free(&m_frame);
    if (m_packet) av_packet_free(&m_packet);
    if (m_swsCtx) sws_freeContext(m_swsCtx);
    
    m_codecCtx = nullptr;
    m_formatCtx = nullptr;
    m_frame = nullptr;
    m_packet = nullptr;
    m_swsCtx = nullptr;
}

void VideoDecoder::setFrameCallback(FrameCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onFrame = callback;
}

void VideoDecoder::decodeLoop() {
    AVFrame* pFrameRGB = av_frame_alloc();
    if (!pFrameRGB) return;

    // Buffer for RGB frame
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGBA, m_width, m_height, 1);
    uint8_t* buffer = (uint8_t*)av_malloc(numBytes * sizeof(uint8_t));
    
    av_image_fill_arrays(pFrameRGB->data, pFrameRGB->linesize, buffer, AV_PIX_FMT_RGBA, m_width, m_height, 1);

    m_swsCtx = sws_getContext(m_width, m_height, m_codecCtx->pix_fmt,
                              m_width, m_height, AV_PIX_FMT_RGBA,
                              SWS_BILINEAR, nullptr, nullptr, nullptr);

    while (!m_stopThread) {
        if (!m_isPlaying) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        if (av_read_frame(m_formatCtx, m_packet) >= 0) {
            if (m_packet->stream_index == m_videoStreamIndex) {
                if (avcodec_send_packet(m_codecCtx, m_packet) == 0) {
                    while (avcodec_receive_frame(m_codecCtx, m_frame) == 0) {
                        // Convert to RGB
                        sws_scale(m_swsCtx, (uint8_t const* const*)m_frame->data,
                                  m_frame->linesize, 0, m_height,
                                  pFrameRGB->data, pFrameRGB->linesize);

                        // Notify callback
                        {
                            std::lock_guard<std::mutex> lock(m_callbackMutex);
                            if (m_onFrame) {
                                Frame f;
                                f.width = m_width;
                                f.height = m_height;
                                f.data[0] = pFrameRGB->data[0]; // Only need the first plane for RGBA
                                f.linesize[0] = pFrameRGB->linesize[0];
                                m_onFrame(f);
                            }
                        }
                        
                        // Simple sync (naive) - assume 30fps roughly or just pump as fast as possible for now
                        // In a real player, you sync to PTS
                        std::this_thread::sleep_for(std::chrono::milliseconds(33));
                    }
                }
            }
            av_packet_unref(m_packet);
        } else {
            // End of stream or error
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }

    av_free(buffer);
    av_frame_free(&pFrameRGB);
}
