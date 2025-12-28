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
    m_skipUntilPts = -1.0;
    
    std::lock_guard<std::mutex> lock(m_audioMutex);
    m_audioBuffer.clear();
}

void VideoDecoder::setTargetResolution(int width, int height) {
    m_targetWidth = width;
    m_targetHeight = height;
}

bool VideoDecoder::open(const std::string& url) {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    
    // Stop previous playback internally
    m_stopThread = true;
    if (m_decodeThread.joinable()) {
        m_decodeThread.join();
    }
    freeResources();

    // Reset stop flag for new playback
    m_stopThread = false;

    m_url = url;

    m_formatCtx = avformat_alloc_context();
    
    // Setup interrupt callback
    m_lastPacketTime = av_gettime();
    m_formatCtx->interrupt_callback.callback = interrupt_cb;
    m_formatCtx->interrupt_callback.opaque = this;

    AVDictionary* options = nullptr;
    // Set timeout to 30 seconds (in microseconds) for protocols that support it
    av_dict_set(&options, "rw_timeout", "30000000", 0);
    av_dict_set(&options, "stimeout", "30000000", 0);
    // Increase buffer size for HTTP
    av_dict_set(&options, "buffer_size", "1024000", 0);
    
    int ret = avformat_open_input(&m_formatCtx, url.c_str(), nullptr, &options);
    av_dict_free(&options);
    
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

    {
        std::lock_guard<std::mutex> lock(m_durationMutex);
        if (m_formatCtx->duration != AV_NOPTS_VALUE) {
            m_duration = (double)m_formatCtx->duration / AV_TIME_BASE;
        } else {
            m_duration = 0.0;
        }
    }

    m_frame = av_frame_alloc();
    m_packet = av_packet_alloc();

    // Start decoding thread
    // m_stopThread is already false
    m_isPlaying = true;
    m_seekTarget = -1.0;
    m_decodeThread = std::thread(&VideoDecoder::decodeLoop, this);

    return true;
}

void VideoDecoder::close() {
    stop();
}

void VideoDecoder::play() {
    std::string urlToOpen;
    {
        std::lock_guard<std::mutex> lock(m_apiMutex);
        if (!m_stopThread) {
            m_isPlaying = true;
            return;
        }
        if (m_url.empty()) {
            return; // Nothing to play
        }
        urlToOpen = m_url;
        // m_apiMutex release automatically here (end of scope)
    }
    open(urlToOpen);
}

void VideoDecoder::pause() {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    m_isPlaying = false;
}

void VideoDecoder::stop() {
    std::lock_guard<std::mutex> lock(m_apiMutex);
    m_isPlaying = false;
    m_stopThread = true;
    if (m_decodeThread.joinable()) {
        m_decodeThread.join();
    }
    freeResources();
}

double VideoDecoder::getDuration() const {
    std::lock_guard<std::mutex> lock(m_durationMutex);
    return m_duration;
}

void VideoDecoder::seek(double seconds) {
    if (seconds < 0.0 || (m_duration > 0.0 && seconds > m_duration)) return; // Out of bounds
    {
        std::lock_guard<std::mutex> lock(m_audioMutex);
        m_audioBuffer.clear(); // Clear audio buffer on seek
    }
    m_seekTarget.store(seconds, std::memory_order_relaxed); // Set seek target
}

void VideoDecoder::setFrameCallback(FrameCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onFrame = callback;
}

void VideoDecoder::setErrorCallback(ErrorCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onError = callback;
}

void VideoDecoder::setEndCallback(EndCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_onEnd = callback;
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

int VideoDecoder::interrupt_cb(void* ctx) {
    VideoDecoder* decoder = static_cast<VideoDecoder*>(ctx);
    return decoder->checkTimeout() ? 1 : 0;
}

bool VideoDecoder::checkTimeout() const {
    if (m_stopThread) return true;
    
    int64_t currentTime = av_gettime();
    if (currentTime - m_lastPacketTime > m_timeoutMicroseconds) {
        return true;
    }
    return false;
}

void VideoDecoder::decodeLoop() {
    if (!m_formatCtx || !m_codecCtx) return;

    AVFrame* pFrameRGB = av_frame_alloc();
    if (!pFrameRGB) return;

    int currentDstWidth = 0;
    int currentDstHeight = 0;
    uint8_t* buffer = nullptr;

    while (!m_stopThread) {
        // 处理 seek 请求
        double target = m_seekTarget.exchange(-1.0, std::memory_order_relaxed);
        if (target >= 0.0) {
            int64_t ts = (int64_t)(target * AV_TIME_BASE); // 转为 AV_TIME_BASE 单位

            // Seek 整个文件（所有流）
            // Use AVSEEK_FLAG_BACKWARD to ensure we land before the target
            if (avformat_seek_file(m_formatCtx, -1, INT64_MIN, ts, ts, AVSEEK_FLAG_BACKWARD) < 0) {
                 // Fallback
                 avformat_seek_file(m_formatCtx, -1, INT64_MIN, ts, INT64_MAX, 0);
            }

            avcodec_flush_buffers(m_codecCtx);
            if (m_audioCodecCtx) {
                avcodec_flush_buffers(m_audioCodecCtx);
            }
            m_lastVideoPts = -1.0; // 重置视频 PTS
            m_skipUntilPts = target; // Set skip target
            
            // Clear audio buffer to avoid playing old audio
            {
                std::lock_guard<std::mutex> lock(m_audioMutex);
                m_audioBuffer.clear();
            }
        }

        if (!m_isPlaying) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        // Determine target size
        int dstWidth = m_targetWidth;
        int dstHeight = m_targetHeight;

        if (dstHeight > 0 && dstWidth == 0) {
             // Calculate width from aspect ratio
             if (m_height > 0) {
                dstWidth = (int)((int64_t)m_width * dstHeight / m_height);
                // Ensure even width
                dstWidth = (dstWidth + 1) & ~1; 
             }
        } else if (dstWidth > 0 && dstHeight == 0) {
             if (m_width > 0) {
                dstHeight = (int)((int64_t)m_height * dstWidth / m_width);
                dstHeight = (dstHeight + 1) & ~1;
             }
        } else if (dstWidth <= 0 && dstHeight <= 0) {
             dstWidth = m_width;
             dstHeight = m_height;
        }

        // Check if we need to (re)initialize context and buffers
        if (dstWidth != currentDstWidth || dstHeight != currentDstHeight || !m_swsCtx) {
            if (buffer) av_free(buffer);
            if (m_swsCtx) sws_freeContext(m_swsCtx);
            
            currentDstWidth = dstWidth;
            currentDstHeight = dstHeight;

            int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGBA, currentDstWidth, currentDstHeight, 1);
            buffer = (uint8_t*)av_malloc(numBytes * sizeof(uint8_t));

            if (!buffer) {
                std::string errorMsg = "Failed to allocate output frame buffer";
                std::cerr << errorMsg << std::endl;
                std::lock_guard<std::mutex> lock(m_callbackMutex);
                if (m_onError) m_onError(errorMsg);
                break; // 退出 decodeLoop
            }
            
            av_image_fill_arrays(pFrameRGB->data, pFrameRGB->linesize, buffer, AV_PIX_FMT_RGBA, currentDstWidth, currentDstHeight, 1);

            m_swsCtx = sws_getContext(m_width, m_height, m_codecCtx->pix_fmt,
                                      currentDstWidth, currentDstHeight, AV_PIX_FMT_RGBA,
                                      SWS_BILINEAR, nullptr, nullptr, nullptr);
            
            if (!m_swsCtx) {
                std::string errorMsg = "Could not initialize SWS context";
                std::cerr << errorMsg << std::endl;
                std::lock_guard<std::mutex> lock(m_callbackMutex);
                if (m_onError) m_onError(errorMsg);
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                continue; // 跳过本次解码
            }
        }

        int readRet = av_read_frame(m_formatCtx, m_packet);
        
        // Update last packet time on successful read
        if (readRet >= 0) {
            m_lastPacketTime = av_gettime();
        }

        if (readRet >= 0) {
            if (m_packet->stream_index == m_videoStreamIndex) {
                if (avcodec_send_packet(m_codecCtx, m_packet) == 0) {
                    while (avcodec_receive_frame(m_codecCtx, m_frame) == 0) {
                        // Convert to RGBA
                        if (m_swsCtx) {
                            sws_scale(m_swsCtx, (const uint8_t* const*)m_frame->data,
                                    m_frame->linesize, 0, m_height,
                                    pFrameRGB->data, pFrameRGB->linesize);

                            // 1. 准备 Frame 数据
                            Frame f;
                            f.width = currentDstWidth;
                            f.height = currentDstHeight;
                            f.linesize = currentDstWidth * 4; // RGBA: 4 bytes/pixel

                            // 2. 获取 PTS
                            AVRational tb = m_formatCtx->streams[m_videoStreamIndex]->time_base;
                            f.pts = (tb.num && tb.den) ? m_frame->best_effort_timestamp * av_q2d(tb) : 0.0;

                            // Check if we need to skip
                            if (m_skipUntilPts >= 0.0) {
                                if (f.pts < m_skipUntilPts - 0.05) { // Allow small tolerance
                                    continue; // Skip this frame
                                }
                                m_skipUntilPts = -1.0; // Reached target, stop skipping
                            }

                            // 3. 深拷贝像素数据（逐行，避免 linesize padding 问题）
                            int totalBytes = f.linesize * f.height;
                            f.rgba.resize(totalBytes);
                            for (int y = 0; y < f.height; ++y) {
                                const uint8_t* src = pFrameRGB->data[0] + y * pFrameRGB->linesize[0];
                                uint8_t* dst = f.rgba.data() + y * f.linesize;
                                std::memcpy(dst, src, f.linesize); // 只拷有效像素（width * 4）
                            }

                            // 4. 回调（线程安全）
                            {
                                std::lock_guard<std::mutex> lock(m_callbackMutex);
                                if (m_onFrame) {
                                    m_onFrame(f);
                                }
                            }

                            // 5. 基于 PTS 的简单同步（替代固定 33ms）
                            if (m_lastVideoPts >= 0.0 && f.pts > m_lastVideoPts) {
                                double delay = f.pts - m_lastVideoPts;
                                int64_t sleepMs = static_cast<int64_t>(delay * 1000);
                                if (sleepMs > 0 && sleepMs < 500) { // 防异常值
                                    std::this_thread::sleep_for(std::chrono::milliseconds(sleepMs));
                                }
                            }
                            m_lastVideoPts = f.pts;
                        }
                    }
                }
            } else if (m_packet->stream_index == m_audioStreamIndex) {
                if (avcodec_send_packet(m_audioCodecCtx, m_packet) == 0) {
                    while (avcodec_receive_frame(m_audioCodecCtx, m_frame) == 0) {
                        // Check if we need to skip audio
                        if (m_skipUntilPts >= 0.0) {
                             AVRational tb = m_formatCtx->streams[m_audioStreamIndex]->time_base;
                             double audioPts = (tb.num && tb.den) ? m_frame->pts * av_q2d(tb) : 0.0;
                             if (audioPts < m_skipUntilPts - 0.1) {
                                 continue;
                             }
                        }

                        if (m_swrCtx) {
                            // 1. 先检查音频缓冲区是否过大（避免 OOM）
                            {
                                std::lock_guard<std::mutex> lock(m_audioMutex);
                                if (m_audioBuffer.size() > 5 * 1024 * 1024) { // 5MB threshold
                                    continue; // 跳过重采样
                                }
                            }

                            // 2. 计算输出样本数
                            int64_t delay = swr_get_delay(m_swrCtx, m_audioCodecCtx->sample_rate);
                            int dst_samples = (int)av_rescale_rnd(
                                delay + m_frame->nb_samples,
                                44100,
                                m_audioCodecCtx->sample_rate,
                                AV_ROUND_UP
                            );

                            if (dst_samples <= 0) {
                                continue;
                            }

                            // 3. 分配输出缓冲区
                            uint8_t* output_buffer = nullptr;
                            int ret = av_samples_alloc(
                                &output_buffer, nullptr,
                                2,
                                dst_samples,
                                AV_SAMPLE_FMT_S16,
                                0
                            );
                            if (ret < 0) {
                                std::cerr << "av_samples_alloc failed" << std::endl;
                                continue;
                            }

                            // 4. 重采样
                            int converted_samples = swr_convert(
                                m_swrCtx,
                                &output_buffer,
                                dst_samples,
                                (const uint8_t**)m_frame->data,
                                m_frame->nb_samples
                            );

                            if (converted_samples > 0) {
                                int buffer_size = av_samples_get_buffer_size(
                                    nullptr, 2, converted_samples, AV_SAMPLE_FMT_S16, 1
                                );

                                // 5. 写入音频缓冲区
                                std::lock_guard<std::mutex> lock(m_audioMutex);
                                if (m_audioBuffer.size() + buffer_size <= 10 * 1024 * 1024) { // 硬上限 10MB
                                    size_t old_size = m_audioBuffer.size();
                                    m_audioBuffer.resize(old_size + buffer_size);
                                    memcpy(m_audioBuffer.data() + old_size, output_buffer, buffer_size);
                                }
                                // 如果超过 10MB，静默丢弃（避免 OOM）
                            }

                            // 6. 释放输出缓冲区（必须）
                            av_freep(&output_buffer);
                        }
                    }
                }
            }
            av_packet_unref(m_packet);
        } else {
            if (readRet == AVERROR_EOF) {
                {
                    std::lock_guard<std::mutex> lock(m_callbackMutex);
                    if(m_onEnd) m_onEnd();
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                continue;
            } else {
                // Handle other errors (e.g. timeout, network error)
                char errbuf[1024];
                av_strerror(readRet, errbuf, sizeof(errbuf));
                std::cerr << "av_read_frame error: " << errbuf << std::endl;
                
                // If it's a timeout or critical error, we might want to stop or reconnect
                // For now, just sleep to avoid busy loop
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                
                // If timeout detected by our callback, we should probably stop
                if (checkTimeout()) {
                     std::string errorMsg = "Connection timed out";
                     std::cerr << errorMsg << std::endl;
                     std::lock_guard<std::mutex> lock(m_callbackMutex);
                     if (m_onError) m_onError(errorMsg);
                     break; // Exit loop
                }
            }
        }
    }

    if (buffer) av_free(buffer);
    av_frame_free(&pFrameRGB);
}
