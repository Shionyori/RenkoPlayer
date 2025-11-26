#pragma once

#include <QQuickPaintedItem>
#include <QImage>
#include <QMutex>
#include "../player/VideoDecoder.h"

class VideoRenderItem : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)

public:
    VideoRenderItem(QQuickItem* parent = nullptr);
    ~VideoRenderItem();

    void paint(QPainter* painter) override;

    QString source() const;
    void setSource(const QString& source);

    Q_INVOKABLE void play();
    Q_INVOKABLE void stop();

signals:
    void sourceChanged();

private:
    void updateFrame(const VideoDecoder::Frame& frame);

    QString m_source;
    VideoDecoder m_decoder;
    QImage m_currentFrame;
    QMutex m_frameMutex;
};
