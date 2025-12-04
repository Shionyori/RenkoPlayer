#pragma once

#include <QQuickFramebufferObject>
#include <QOpenGLTexture>
#include <QOpenGLShaderProgram>
#include <QOpenGLBuffer>
#include <QMutex>
#include <QImage>
#include "../player/VideoDecoder.h"

class PanoramaRenderItem : public QQuickFramebufferObject {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qreal yaw READ yaw WRITE setYaw NOTIFY yawChanged)
    Q_PROPERTY(qreal pitch READ pitch WRITE setPitch NOTIFY pitchChanged)
    Q_PROPERTY(qreal fov READ fov WRITE setFov NOTIFY fovChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)

public:
    PanoramaRenderItem(QQuickItem* parent = nullptr);
    ~PanoramaRenderItem();

    Renderer* createRenderer() const override;

    QString source() const { return m_source; }
    void setSource(const QString& source);

    qreal yaw() const { return m_yaw; }
    void setYaw(qreal yaw);

    qreal pitch() const { return m_pitch; }
    void setPitch(qreal pitch);

    qreal fov() const { return m_fov; }
    void setFov(qreal fov);

    qint64 duration() const { return m_duration; }
    qint64 position() const { return m_position; }
    void setPosition(qint64 position);

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();

    // Internal use for Renderer
    QImage getFrame();
    bool hasNewFrame() const { return m_newFrameAvailable; }

signals:
    void sourceChanged();
    void yawChanged();
    void pitchChanged();
    void fovChanged();
    void durationChanged();
    void positionChanged();
    void errorOccurred(QString message);

private:
    void updateFrame(const VideoDecoder::Frame& frame);
    void handleError(const std::string& message);

    QString m_source;
    qreal m_yaw = 0.0;
    qreal m_pitch = 0.0;
    qreal m_fov = 90.0;

    VideoDecoder m_decoder;
    QImage m_currentFrame;
    bool m_newFrameAvailable = false;
    
    qint64 m_duration = 0;
    qint64 m_position = 0;
    
    mutable QMutex m_frameMutex;
    std::thread m_loadingThread;
};
