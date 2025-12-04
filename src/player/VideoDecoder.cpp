#include "VideoDecoder.h"
#include <iostream>

extern "C" {
#include <libavutil/opt.h>
}

VideoDecoder::VideoDecoder() {
    // Initialize network if needed (older ffmpeg versions)
    avformat_network_init();
    m_stopThread = true; // Initially stopped
}

VideoDecoder::~VideoDecoder() {
    stop();
    freeResources();
}

void VideoDecoder::freeResources() {
    if (m_codecCtx) avcodec_free_context(&m_codecCtx);
    if (m_audioCodecCtx) avcodec_free_context(&m_audioCodecCtx);
    if (m_formatCtx) avformat_close_input(&m_formatCtx);
    if (m_frame) av_frame_free(&m_frame);
    if (m_packet) av_packet_free(&m_packet);
    if (m_swsCtx) sws_freeContext(m_swsCtx);
    if (m_swrCtx) swr_free(&m_swrCtx);
    
    m_codecCtx = nullptr;
    m_audioCodecCtx = nullptr;
    m_formatCtx = nullptr;
    m_frame = nullptr;
    m_packet = nullptr;
    m_swsCtx = nullptr;
    m_swrCtx = nullptr;
    m_duration = 0.0;
    m_audioStreamIndex = -1;
    m_videoStreamIndex = -1;
    
    std::lock_guard<std::mutex> lock(m_audioMutex);
    m_audioBuffer.clear();
}

bool VideoDecoder::open(const std::string& url) {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    
    // Stop previous playback internally
    m_stopThread = true;
    if (m_decodeThread.joinable()) {
        m_decodeThread.join();
    }
    freeResources();

    m_url = url;

    m_formatCtx = avformat_alloc_context();
    int ret = avformat_open_input(&m_formatCtx, url.c_str(), nullptr, nullptr);
    if (ret != 0) {
        char errbuf[1024];
        av_strerror(ret, errbuf, sizeof(errbuf));
        std::string errorMsg = "Could not open source: " + url + " Error: " + std::string(errbuf);
        std::cerr << errorMsg << std::endl;
        
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    if (avformat_find_stream_info(m_formatCtx, nullptr) < 0) {
        std::string errorMsg = "Could not find stream info";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    // Find Video Stream
    m_videoStreamIndex = -1;
    for (unsigned int i = 0; i < m_formatCtx->nb_streams; i++) {
        if (m_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            m_videoStreamIndex = i;
            break;
        }
    }

    // Find Audio Stream
    m_audioStreamIndex = -1;
    for (unsigned int i = 0; i < m_formatCtx->nb_streams; i++) {
        if (m_formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            m_audioStreamIndex = i;
            break;
        }
    }

    if (m_videoStreamIndex == -1) {
        std::string errorMsg = "No video stream found";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    // Init Video Codec
    AVCodecParameters* codecPar = m_formatCtx->streams[m_videoStreamIndex]->codecpar;
    m_codec = avcodec_find_decoder(codecPar->codec_id);
    if (!m_codec) {
        std::string errorMsg = "Unsupported video codec";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    m_codecCtx = avcodec_alloc_context3(m_codec);
    avcodec_parameters_to_context(m_codecCtx, codecPar);

    if (avcodec_open2(m_codecCtx, m_codec, nullptr) < 0) {
        std::string errorMsg = "Could not open video codec";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    m_width = m_codecCtx->width;
    m_height = m_codecCtx->height;

    // Init Audio Codec
    if (m_audioStreamIndex >= 0) {
        AVCodecParameters* audioCodecPar = m_formatCtx->streams[m_audioStreamIndex]->codecpar;
        m_audioCodec = avcodec_find_decoder(audioCodecPar->codec_id);
        if (m_audioCodec) {
            m_audioCodecCtx = avcodec_alloc_context3(m_audioCodec);
            avcodec_parameters_to_context(m_audioCodecCtx, audioCodecPar);
            if (avcodec_open2(m_audioCodecCtx, m_audioCodec, nullptr) == 0) {
                // Init SwrContext for resampling to Stereo S16LE 44100Hz
                m_swrCtx = swr_alloc();
                
                // Input properties
                av_opt_set_chlayout(m_swrCtx, "in_chlayout", &m_audioCodecCtx->ch_layout, 0);
                av_opt_set_int(m_swrCtx, "in_sample_rate", m_audioCodecCtx->sample_rate, 0);
                av_opt_set_sample_fmt(m_swrCtx, "in_sample_fmt", m_audioCodecCtx->sample_fmt, 0);
                
                // Output properties (Stereo, 44100, S16)
                AVChannelLayout out_layout = AV_CHANNEL_LAYOUT_STEREO;
                av_opt_set_chlayout(m_swrCtx, "out_chlayout", &out_layout, 0);
                av_opt_set_int(m_swrCtx, "out_sample_rate", 44100, 0);
                av_opt_set_sample_fmt(m_swrCtx, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0);
                
                swr_init(m_swrCtx);
            } else {
                std::cerr << "Could not open audio codec" << std::endl;
                m_audioStreamIndex = -1; // Disable audio
            }
        }
    }

    if (m_width <= 0 || m_height <= 0) {
        std::string errorMsg = "Invalid video dimensions";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        return false;
    }

    if (m_formatCtx->duration != AV_NOPTS_VALUE) {
        m_duration = (double)m_formatCtx->duration / AV_TIME_BASE;
    } else {
        m_duration = 0.0;
    }

    m_frame = av_frame_alloc();
    m_packet = av_packet_alloc();

    // Start decoding thread
    m_stopThread = false;
    m_isPlaying = true;
    m_seekTarget = -1.0;
    m_decodeThread = std::thread(&VideoDecoder::decodeLoop, this);

    return true;
}

void VideoDecoder::close() {
    stop();
}

void VideoDecoder::play() {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    if (m_stopThread) {
        if (!m_url.empty()) {
            // We can't call open() here because it locks m_apiMutex.
            // We need to release lock or use internal open.
            // But open() is complex.
            // Let's just unlock and call open.
            // But wait, m_url might change? No, we are inside play().
            std::string url = m_url;
            m_apiMutex.unlock();
            open(url);
            m_apiMutex.lock();
        }
    } else {
        m_isPlaying = true;
    }
}

void VideoDecoder::pause() {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    m_isPlaying = false;
}

void VideoDecoder::stop() {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    m_stopThread = true;
    if (m_decodeThread.joinable()) {
        m_decodeThread.join();
    }
    freeResources();
}

double VideoDecoder::getDuration() const {
    // m_duration is atomic-ish (double read is usually atomic on x64 but not guaranteed)
    // But it's only written in open() and freeResources().
    return m_duration;
}

void VideoDecoder::seek(double seconds) {
    m_seekTarget = seconds;
}

void VideoDecoder::setFrameCallback(FrameCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onFrame = callback;
}

void VideoDecoder::setErrorCallback(ErrorCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onError = callback;
}

int VideoDecoder::getAudioData(uint8_t* data, int max_size) {
    std::lock_guard<std::mutex> lock(m_audioMutex);
    if (m_audioBuffer.empty()) return 0;
    
    int to_copy = std::min((int)m_audioBuffer.size(), max_size);
    memcpy(data, m_audioBuffer.data(), to_copy);
    
    // Remove read data
    m_audioBuffer.erase(m_audioBuffer.begin(), m_audioBuffer.begin() + to_copy);
    
    return to_copy;
}

void VideoDecoder::decodeLoop() {
    if (!m_formatCtx || !m_codecCtx) return;

    AVFrame* pFrameRGB = av_frame_alloc();
    if (!pFrameRGB) return;

    // Buffer for RGB frame
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGBA, m_width, m_height, 1);
    uint8_t* buffer = (uint8_t*)av_malloc(numBytes * sizeof(uint8_t));
    
    av_image_fill_arrays(pFrameRGB->data, pFrameRGB->linesize, buffer, AV_PIX_FMT_RGBA, m_width, m_height, 1);

    // Check pixel format
    if (m_codecCtx->pix_fmt == AV_PIX_FMT_NONE) {
         std::cerr << "Invalid pixel format" << std::endl;
         av_free(buffer);
         av_frame_free(&pFrameRGB);
         return;
    }

    m_swsCtx = sws_getContext(m_width, m_height, m_codecCtx->pix_fmt,
                              m_width, m_height, AV_PIX_FMT_RGBA,
                              SWS_BILINEAR, nullptr, nullptr, nullptr);
    
    if (!m_swsCtx) {
        std::string errorMsg = "Could not initialize SWS context";
        std::cerr << errorMsg << std::endl;
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        if (m_onError) m_onError(errorMsg);
        av_free(buffer);
        av_frame_free(&pFrameRGB);
        return;
    }

    while (!m_stopThread) {
        // Handle Seek
        double target = m_seekTarget.exchange(-1.0);
        if (target >= 0.0) {
            // Check for valid time_base
            AVRational tb = m_formatCtx->streams[m_videoStreamIndex]->time_base;
            if (tb.num != 0 && tb.den != 0) {
                int64_t ts = target / av_q2d(tb);
                if (av_seek_frame(m_formatCtx, m_videoStreamIndex, ts, AVSEEK_FLAG_BACKWARD) >= 0) {
                    avcodec_flush_buffers(m_codecCtx);
                }
            }
        }

        if (!m_isPlaying) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        int readRet = av_read_frame(m_formatCtx, m_packet);
        if (readRet >= 0) {
            if (m_packet->stream_index == m_videoStreamIndex) {
                if (avcodec_send_packet(m_codecCtx, m_packet) == 0) {
                    while (avcodec_receive_frame(m_codecCtx, m_frame) == 0) {
                        // Convert to RGB
                        if (m_swsCtx) {
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
                                    
                                    AVRational tb = m_formatCtx->streams[m_videoStreamIndex]->time_base;
                                    if (tb.num != 0 && tb.den != 0) {
                                         f.pts = m_frame->best_effort_timestamp * av_q2d(tb);
                                    } else {
                                         f.pts = 0;
                                    }
                                    m_onFrame(f);
                                }
                            }
                        }
                        
                        // Simple sync (naive) - assume 30fps roughly or just pump as fast as possible for now
                        // In a real player, you sync to PTS
                        std::this_thread::sleep_for(std::chrono::milliseconds(33));
                    }
                }
            } else if (m_packet->stream_index == m_audioStreamIndex) {
                if (avcodec_send_packet(m_audioCodecCtx, m_packet) == 0) {
                    while (avcodec_receive_frame(m_audioCodecCtx, m_frame) == 0) {
                        if (m_swrCtx) {
                            // Resample
                            int dst_samples = av_rescale_rnd(swr_get_delay(m_swrCtx, m_audioCodecCtx->sample_rate) +
                                            m_frame->nb_samples, 44100, m_audioCodecCtx->sample_rate, AV_ROUND_UP);
                            
                            uint8_t* output_buffer = nullptr;
                            av_samples_alloc(&output_buffer, nullptr, 2, dst_samples, AV_SAMPLE_FMT_S16, 0);
                            
                            int converted_samples = swr_convert(m_swrCtx, &output_buffer, dst_samples,
                                            (const uint8_t**)m_frame->data, m_frame->nb_samples);
                            
                            if (converted_samples > 0) {
                                int buffer_size = av_samples_get_buffer_size(nullptr, 2, converted_samples, AV_SAMPLE_FMT_S16, 1);
                                
                                std::lock_guard<std::mutex> lock(m_audioMutex);
                                // Limit buffer size to avoid OOM if audio is faster than playback
                                if (m_audioBuffer.size() < 1024 * 1024 * 10) { // 10MB limit
                                    size_t current_size = m_audioBuffer.size();
                                    m_audioBuffer.resize(current_size + buffer_size);
                                    memcpy(m_audioBuffer.data() + current_size, output_buffer, buffer_size);
                                }
                            }
                            
                            if (output_buffer) av_freep(&output_buffer);
                        }
                    }
                }
            }
            av_packet_unref(m_packet);
        } else {
            if (readRet == AVERROR_EOF) {
                // End of stream, loop or stop? For now just wait
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            } else {
                // Error
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        }
    }

    av_free(buffer);
    av_frame_free(&pFrameRGB);
}
