#pragma once

#include <QQuickPaintedItem>
#include <QImage>
#include <QMutex>
#include "../player/VideoDecoder.h"

class VideoRenderItem : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)

public:
    VideoRenderItem(QQuickItem* parent = nullptr);
    ~VideoRenderItem();

    void paint(QPainter* painter) override;

    QString source() const;
    void setSource(const QString& source);

    qint64 duration() const;
    qint64 position() const;
    void setPosition(qint64 position);

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause(); // Add pause
    Q_INVOKABLE void stop();

signals:
    void sourceChanged();
    void durationChanged();
    void positionChanged();
    void errorOccurred(QString message); // Add signal

private:
    void updateFrame(const VideoDecoder::Frame& frame);
    void handleError(const std::string& message); // Add handler

    QString m_source;
    VideoDecoder m_decoder;
    QImage m_currentFrame;
    QString m_lastError; // Add error storage
    qint64 m_duration = 0;
    qint64 m_position = 0;
    QMutex m_frameMutex;
    std::thread m_loadingThread; // Manage loading thread
};
