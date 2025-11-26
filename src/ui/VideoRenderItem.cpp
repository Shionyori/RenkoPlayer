#include "VideoRenderItem.h"
#include <QPainter>
#include <QDebug>

VideoRenderItem::VideoRenderItem(QQuickItem* parent) : QQuickPaintedItem(parent) {
    // Optimize for video
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
    
    m_decoder.setFrameCallback([this](const VideoDecoder::Frame& frame) {
        this->updateFrame(frame);
    });
}

VideoRenderItem::~VideoRenderItem() {
    m_decoder.stop();
}

QString VideoRenderItem::source() const {
    return m_source;
}

void VideoRenderItem::setSource(const QString& source) {
    if (m_source == source) return;
    m_source = source;
    emit sourceChanged();

    if (!m_source.isEmpty()) {
        // Run in background to avoid blocking UI
        std::thread([this]() {
            m_decoder.open(m_source.toStdString());
        }).detach();
    }
}

void VideoRenderItem::play() {
    m_decoder.play();
}

void VideoRenderItem::stop() {
    m_decoder.stop();
}

void VideoRenderItem::updateFrame(const VideoDecoder::Frame& frame) {
    QMutexLocker lock(&m_frameMutex);
    // Deep copy the data to a QImage
    // Note: In a real high-perf player, you'd avoid this copy by using OpenGL textures directly
    m_currentFrame = QImage(frame.data[0], frame.width, frame.height, frame.linesize[0], QImage::Format_RGBA8888).copy();
    
    // Schedule a redraw on the main thread
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
        painter->drawText(boundingRect(), Qt::AlignCenter, "No Signal / Loading...");
    }
}
