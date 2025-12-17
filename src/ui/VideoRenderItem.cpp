#include "VideoRenderItem.h"
#include <QPainter>
#include <QDebug>
#include <QUrl> // Add this

VideoRenderItem::VideoRenderItem(QQuickItem* parent) : QQuickPaintedItem(parent) {
    // Optimize for video
    // setRenderTarget(QQuickPaintedItem::FramebufferObject);
    
    m_decoder.setFrameCallback([this](const VideoDecoder::Frame& frame) {
        this->updateFrame(frame);
    });
    
    m_decoder.setErrorCallback([this](const std::string& msg) {
        this->handleError(msg);
    });

    m_audioTimer = new QTimer(this);
    m_audioTimer->setInterval(10);
    connect(m_audioTimer, &QTimer::timeout, this, &VideoRenderItem::updateAudio);
}

VideoRenderItem::~VideoRenderItem() {
    // Stop decoder first
    m_decoder.stop();
    
    if (m_audioSink) {
        m_audioSink->stop();
        delete m_audioSink;
    }
    
    // Wait for any loading thread to finish
    if (m_loadingThread.joinable()) {
        m_loadingThread.join();
    }
}

QString VideoRenderItem::source() const {
    return m_source;
}

void VideoRenderItem::setSource(const QString& source) {
    if (m_source == source) return;
    m_source = source;
    emit sourceChanged();

    // Clear previous error
    {
        QMutexLocker lock(&m_frameMutex);
        m_lastError.clear();
        m_currentFrame = QImage(); // Clear previous frame
        m_duration = 0;
        m_position = 0;
    }
    emit durationChanged();
    emit positionChanged();
    update(); // Trigger repaint to clear screen

    if (!m_source.isEmpty()) {
        // Handle file:// URLs
        QString path = m_source;
        QUrl url(m_source);
        if (url.isLocalFile()) {
            path = url.toLocalFile();
        }
        
        // Stop Audio
        if (m_audioSink) {
            m_audioSink->stop();
            delete m_audioSink;
            m_audioSink = nullptr;
        }
        m_audioTimer->stop();
        
        // Join previous thread if running
        if (m_loadingThread.joinable()) {
            m_loadingThread.join();
        }

        // Run in background to avoid blocking UI
        std::string stdPath = path.toStdString();
        m_loadingThread = std::thread([this, stdPath]() {
            if (m_decoder.open(stdPath)) {
                QMetaObject::invokeMethod(this, [this]() {
                    m_duration = m_decoder.getDuration() * 1000;
                    emit durationChanged();
                    
                    // Init Audio
                    if (m_decoder.hasAudio()) {
                        QAudioFormat format;
                        format.setSampleRate(44100);
                        format.setChannelConfig(QAudioFormat::ChannelConfigStereo);
                        format.setSampleFormat(QAudioFormat::Int16);
                        
                        QAudioDevice device = QMediaDevices::defaultAudioOutput();
                        if (!device.isFormatSupported(format)) {
                            qWarning() << "Default format not supported, trying to find nearest";
                            // format = device.preferredFormat(); // Qt6 might not have this exact method, check docs or assume standard
                        }
                        
                        m_audioSink = new QAudioSink(device, format, this);
                        m_audioSink->setVolume(m_volume);
                        m_audioOutputDevice = m_audioSink->start();
                        m_audioTimer->start();
                    }
                });
            }
        });
    }
}

qint64 VideoRenderItem::duration() const {
    return m_duration;
}

qint64 VideoRenderItem::position() const {
    return m_position;
}

void VideoRenderItem::setPosition(qint64 position) {
    if (m_position == position) return;
    // Don't update m_position here, let the decoder update it via callback
    // But we do need to tell decoder to seek
    m_decoder.seek(position / 1000.0);
}

void VideoRenderItem::play() {
    // If stopped, we need to re-open, which might block, so do it in thread if needed
    if (m_decoder.isStopped() && !m_source.isEmpty()) {
        QString path = m_source;
        QUrl url(m_source);
        if (url.isLocalFile()) {
            path = url.toLocalFile();
        }
        std::string stdPath = path.toStdString();

        // Join previous thread if running
        if (m_loadingThread.joinable()) {
            m_loadingThread.join();
        }

        m_loadingThread = std::thread([this, stdPath]() {
            if (m_decoder.open(stdPath)) {
                QMetaObject::invokeMethod(this, [this]() {
                    m_duration = m_decoder.getDuration() * 1000;
                    emit durationChanged();
                    
                    // Init Audio
                    if (m_decoder.hasAudio()) {
                        QAudioFormat format;
                        format.setSampleRate(44100);
                        format.setChannelConfig(QAudioFormat::ChannelConfigStereo);
                        format.setSampleFormat(QAudioFormat::Int16);
                        
                        QAudioDevice device = QMediaDevices::defaultAudioOutput();
                        if (!device.isFormatSupported(format)) {
                            qWarning() << "Default format not supported";
                        }
                        
                        if (m_audioSink) {
                            m_audioSink->stop();
                            delete m_audioSink;
                        }
                        
                        m_audioSink = new QAudioSink(device, format, this);
                        m_audioSink->setVolume(m_volume);
                        m_audioOutputDevice = m_audioSink->start();
                        m_audioTimer->start();
                    }

                    m_decoder.play();
                });
            }
        });
    } else {
        m_decoder.play();
        if (m_audioSink && m_audioSink->state() == QAudio::SuspendedState) {
            m_audioSink->resume();
        }
    }
}

void VideoRenderItem::pause() {
    m_decoder.pause();
    if (m_audioSink && m_audioSink->state() == QAudio::ActiveState) {
        m_audioSink->suspend();
    }
}

void VideoRenderItem::stop() {
    m_decoder.stop();
    if (m_audioSink) {
        m_audioSink->stop();
    }
}

void VideoRenderItem::setResolution(int width, int height) {
    m_decoder.setTargetResolution(width, height);
}

void VideoRenderItem::updateAudio() {
    if (!m_audioSink || !m_audioOutputDevice || m_audioSink->state() == QAudio::StoppedState) return;
    
    int chunks = m_audioSink->bytesFree();
    if (chunks > 0) {
        std::vector<uint8_t> buf(chunks);
        int read = m_decoder.getAudioData(buf.data(), chunks);
        if (read > 0) {
            m_audioOutputDevice->write((const char*)buf.data(), read);
        }
    }
}

qreal VideoRenderItem::volume() const { return m_volume; }
void VideoRenderItem::setVolume(qreal volume) {
    if (qFuzzyCompare(m_volume, volume)) return;
    m_volume = volume;
    if (m_audioSink) m_audioSink->setVolume(m_volume);
    emit volumeChanged();
}

void VideoRenderItem::updateFrame(const VideoDecoder::Frame& frame) {
    QMutexLocker lock(&m_frameMutex);
    // Deep copy the data to a QImage
    // Note: In a real high-perf player, you'd avoid this copy by using OpenGL textures directly
    m_currentFrame = QImage(frame.rgba.data(), frame.width, frame.height, frame.linesize, QImage::Format_RGBA8888).copy();
    m_lastError.clear(); // Clear error on successful frame
    
    m_position = frame.pts * 1000;
    
    // Schedule a redraw on the main thread
    QMetaObject::invokeMethod(this, "update", Qt::QueuedConnection);
    QMetaObject::invokeMethod(this, "positionChanged", Qt::QueuedConnection);
}

void VideoRenderItem::handleError(const std::string& message) {
    QMutexLocker lock(&m_frameMutex);
    m_lastError = QString::fromStdString(message);
    qDebug() << "Video Error:" << m_lastError;
    emit errorOccurred(m_lastError);
    
    // Schedule a redraw to show error
    QMetaObject::invokeMethod(this, "update", Qt::QueuedConnection);
}

void VideoRenderItem::paint(QPainter* painter) {
    QMutexLocker lock(&m_frameMutex);
    if (!m_currentFrame.isNull()) {
        // Scale to fit the item
        QRectF targetRect(0, 0, width(), height());
        painter->drawImage(targetRect, m_currentFrame);
    } else {
        painter->fillRect(0, 0, width(), height(), Qt::black);
        painter->setPen(Qt::white);
        
        if (!m_lastError.isEmpty()) {
            painter->setPen(Qt::red);
            painter->drawText(boundingRect(), Qt::AlignCenter, "Error:\n" + m_lastError);
        } else {
            painter->drawText(boundingRect(), Qt::AlignCenter, "No Signal / Loading...");
        }
    }
}
