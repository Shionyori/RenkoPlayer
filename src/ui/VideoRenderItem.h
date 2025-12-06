#pragma once

#include <QQuickPaintedItem>
#include <QImage>
#include <QMutex>
#include <QAudioSink>
#include <QMediaDevices>
#include <QAudioDevice>
#include <QTimer>
#include "../player/VideoDecoder.h"

class VideoRenderItem : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)

public:
    VideoRenderItem(QQuickItem* parent = nullptr);
    ~VideoRenderItem();

    void paint(QPainter* painter) override;

    QString source() const;
    void setSource(const QString& source);

    qint64 duration() const;
    qint64 position() const;
    void setPosition(qint64 position);

    qreal volume() const;
    void setVolume(qreal volume);

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setResolution(int width, int height);

signals:
    void sourceChanged();
    void durationChanged();
    void positionChanged();
    void volumeChanged();
    void errorOccurred(QString message);

private:
    void updateFrame(const VideoDecoder::Frame& frame);
    void handleError(const std::string& message);
    void updateAudio();

    QString m_source;
    VideoDecoder m_decoder;
    QImage m_currentFrame;
    QString m_lastError;
    qint64 m_duration = 0;
    qint64 m_position = 0;
    qreal m_volume = 1.0;
    QMutex m_frameMutex;
    std::thread m_loadingThread;
    
    QAudioSink* m_audioSink = nullptr;
    QIODevice* m_audioOutputDevice = nullptr;
    QTimer* m_audioTimer = nullptr;
};
