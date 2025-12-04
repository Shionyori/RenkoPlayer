#include "PanoramaRenderItem.h"
#include <QOpenGLFunctions>
#include <QOpenGLFramebufferObject>
#include <QQuickWindow>
#include <cmath>
#include <QUrl>
#include <QDebug>

class PanoramaRenderer : public QQuickFramebufferObject::Renderer, protected QOpenGLFunctions {
public:
    PanoramaRenderer() {
        initializeOpenGLFunctions();
        initShaders();
        initGeometry();
    }

    ~PanoramaRenderer() {
        if (m_texture) delete m_texture;
        if (m_program) delete m_program;
    }

    void render() override {
        // Clear with transparency to blend with QML background if needed, 
        // but usually we want black for video.
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Disable depth test and culling for simple 2D quad rendering
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_CULL_FACE);

        if (!m_texture) return;

        m_program->bind();
        
        // Bind texture to unit 0
        glActiveTexture(GL_TEXTURE0);
        m_texture->bind();
        m_program->setUniformValue("texture", 0);
        
        m_program->setUniformValue("yaw", (float)m_yaw);
        m_program->setUniformValue("pitch", (float)m_pitch);
        m_program->setUniformValue("fov", (float)m_fov);
        
        // Calculate aspect ratio from viewport
        GLint viewport[4];
        glGetIntegerv(GL_VIEWPORT, viewport);
        float aspect = (float)viewport[2] / (float)viewport[3];
        m_program->setUniformValue("aspect", aspect);

        m_vbo.bind();
        int vertexLocation = m_program->attributeLocation("vertices");
        m_program->enableAttributeArray(vertexLocation);
        m_program->setAttributeBuffer(vertexLocation, GL_FLOAT, 0, 2);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        m_program->disableAttributeArray(vertexLocation);
        m_vbo.release();
        m_texture->release();
        m_program->release();
    }

    QOpenGLFramebufferObject* createFramebufferObject(const QSize &size) override {
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        return new QOpenGLFramebufferObject(size, format);
    }

    void synchronize(QQuickFramebufferObject *item) override {
        PanoramaRenderItem *pItem = static_cast<PanoramaRenderItem*>(item);
        
        m_yaw = pItem->yaw();
        m_pitch = pItem->pitch();
        m_fov = pItem->fov();

        if (pItem->hasNewFrame()) {
            QImage img = pItem->getFrame();
            if (!img.isNull()) {
                if (!m_texture) {
                    m_texture = new QOpenGLTexture(QOpenGLTexture::Target2D);
                    m_texture->setSize(img.width(), img.height());
                    m_texture->setFormat(QOpenGLTexture::RGBA8_UNorm);
                    m_texture->allocateStorage();
                    m_texture->setMinificationFilter(QOpenGLTexture::Linear);
                    m_texture->setMagnificationFilter(QOpenGLTexture::Linear);
                    m_texture->setWrapMode(QOpenGLTexture::Repeat);
                    m_texture->setData(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8, img.constBits());
                } else {
                    // Recreate if size changed, otherwise update
                    if (m_texture->width() != img.width() || m_texture->height() != img.height()) {
                        delete m_texture;
                        m_texture = new QOpenGLTexture(QOpenGLTexture::Target2D);
                        m_texture->setSize(img.width(), img.height());
                        m_texture->setFormat(QOpenGLTexture::RGBA8_UNorm);
                        m_texture->allocateStorage();
                        m_texture->setMinificationFilter(QOpenGLTexture::Linear);
                        m_texture->setMagnificationFilter(QOpenGLTexture::Linear);
                        m_texture->setWrapMode(QOpenGLTexture::Repeat);
                        m_texture->setData(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8, img.constBits());
                    } else {
                        m_texture->setData(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8, img.constBits());
                    }
                }
            }
        }
        
        // Force update if texture exists but no new frame (e.g. camera rotation)
        if (m_texture) {
            // No explicit update needed for QQuickFramebufferObject, 
            // but we need to ensure the window knows we want to draw.
            // The update() call in PanoramaRenderItem handles this.
        }
    }

private:
    void initShaders() {
        m_program = new QOpenGLShaderProgram();
        
        // Vertex Shader
        // Use standard GLSL 1.10 which is widely supported in Compatibility Profile
        if (!m_program->addShaderFromSourceCode(QOpenGLShader::Vertex,
            "#version 110\n"
            "attribute vec4 vertices;"
            "varying vec2 coords;"
            "void main() {"
            "    gl_Position = vertices;"
            "    coords = vertices.xy;"
            "}")) {
            qDebug() << "Vertex Shader Error:" << m_program->log();
        }

        // Fragment Shader
        if (!m_program->addShaderFromSourceCode(QOpenGLShader::Fragment,
            "#version 110\n"
            "uniform sampler2D texture;"
            "uniform float yaw;"
            "uniform float pitch;"
            "uniform float fov;"
            "uniform float aspect;"
            "varying vec2 coords;"
            "const float PI = 3.14159265359;"
            "void main() {"
            "    float tanHalfFov = tan(radians(fov) / 2.0);"
            "    vec3 ray = vec3(coords.x * aspect * tanHalfFov, coords.y * tanHalfFov, -1.0);"
            "    ray = normalize(ray);"
            "    float cp = cos(radians(pitch));"
            "    float sp = sin(radians(pitch));"
            "    vec3 r1 = vec3(ray.x, ray.y * cp - ray.z * sp, ray.y * sp + ray.z * cp);"
            "    float cy = cos(radians(yaw));"
            "    float sy = sin(radians(yaw));"
            "    vec3 r2 = vec3(r1.x * cy + r1.z * sy, r1.y, -r1.x * sy + r1.z * cy);"
            "    vec3 dir = normalize(r2);"
            "    float u = 0.5 + atan(dir.z, dir.x) / (2.0 * PI);"
            "    float v = 0.5 - asin(dir.y) / PI;"
            "    gl_FragColor = texture2D(texture, vec2(u, 1.0 - v));"
            "}")) {
            qDebug() << "Fragment Shader Error:" << m_program->log();
        }

        if (!m_program->link()) {
            qDebug() << "Shader Link Error:" << m_program->log();
        }
    }

    void initGeometry() {
        float vertices[] = {
            -1.0f, -1.0f,
             1.0f, -1.0f,
            -1.0f,  1.0f,
             1.0f,  1.0f
        };
        m_vbo.create();
        m_vbo.bind();
        m_vbo.allocate(vertices, sizeof(vertices));
        m_vbo.release();
    }

    QOpenGLShaderProgram* m_program = nullptr;
    QOpenGLTexture* m_texture = nullptr;
    QOpenGLBuffer m_vbo;
    
    qreal m_yaw = 0;
    qreal m_pitch = 0;
    qreal m_fov = 90;
};

// --- PanoramaRenderItem Implementation ---

PanoramaRenderItem::PanoramaRenderItem(QQuickItem* parent) : QQuickFramebufferObject(parent) {
    m_decoder.setFrameCallback([this](const VideoDecoder::Frame& frame) {
        this->updateFrame(frame);
    });
    
    m_decoder.setErrorCallback([this](const std::string& msg) {
        this->handleError(msg);
    });

    m_audioTimer = new QTimer(this);
    m_audioTimer->setInterval(10);
    connect(m_audioTimer, &QTimer::timeout, this, &PanoramaRenderItem::updateAudio);
}

PanoramaRenderItem::~PanoramaRenderItem() {
    m_decoder.stop();
    if (m_audioSink) {
        m_audioSink->stop();
        delete m_audioSink;
    }
    if (m_loadingThread.joinable()) {
        m_loadingThread.join();
    }
}

QQuickFramebufferObject::Renderer* PanoramaRenderItem::createRenderer() const {
    return new PanoramaRenderer();
}

void PanoramaRenderItem::setSource(const QString& source) {
    if (m_source == source) return;
    m_source = source;
    emit sourceChanged();

    {
        QMutexLocker lock(&m_frameMutex);
        m_currentFrame = QImage();
        m_newFrameAvailable = false;
    }
    
    if (!m_source.isEmpty()) {
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
        
        if (m_loadingThread.joinable()) {
            m_loadingThread.join();
        }

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
                            qWarning() << "Default format not supported";
                        }
                        
                        m_audioSink = new QAudioSink(device, format, this);
                        m_audioSink->setVolume(m_volume);
                        m_audioOutputDevice = m_audioSink->start();
                        m_audioTimer->start();
                    }
                    
                    play(); // Auto play
                });
            }
        });
    }
}

void PanoramaRenderItem::setYaw(qreal yaw) {
    if (qFuzzyCompare(m_yaw, yaw)) return;
    m_yaw = yaw;
    emit yawChanged();
    update();
}

void PanoramaRenderItem::setPitch(qreal pitch) {
    if (qFuzzyCompare(m_pitch, pitch)) return;
    m_pitch = pitch;
    emit pitchChanged();
    update();
}

void PanoramaRenderItem::setFov(qreal fov) {
    if (qFuzzyCompare(m_fov, fov)) return;
    m_fov = fov;
    emit fovChanged();
    update();
}

void PanoramaRenderItem::setPosition(qint64 position) {
    if (m_position == position) return;
    m_decoder.seek(position / 1000.0);
}

void PanoramaRenderItem::play() {
    if (m_decoder.isStopped() && !m_source.isEmpty()) {
        QString path = m_source;
        QUrl url(m_source);
        if (url.isLocalFile()) {
            path = url.toLocalFile();
        }
        std::string stdPath = path.toStdString();

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

void PanoramaRenderItem::pause() {
    m_decoder.pause();
    if (m_audioSink && m_audioSink->state() == QAudio::ActiveState) {
        m_audioSink->suspend();
    }
}

void PanoramaRenderItem::stop() {
    m_decoder.stop();
    if (m_audioSink) {
        m_audioSink->stop();
    }
}

void PanoramaRenderItem::updateAudio() {
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

void PanoramaRenderItem::setVolume(qreal volume) {
    if (qFuzzyCompare(m_volume, volume)) return;
    m_volume = volume;
    if (m_audioSink) m_audioSink->setVolume(m_volume);
    emit volumeChanged();
}

void PanoramaRenderItem::updateFrame(const VideoDecoder::Frame& frame) {
    QImage img(frame.data[0], frame.width, frame.height, frame.linesize[0], QImage::Format_RGBA8888);
    // Deep copy because buffer is reused by decoder
    QImage copy = img.copy(); 
    
    {
        QMutexLocker lock(&m_frameMutex);
        m_currentFrame = copy;
        m_newFrameAvailable = true;
        m_position = frame.pts * 1000;
    }
    
    QMetaObject::invokeMethod(this, [this]() {
        emit positionChanged();
        update(); // Trigger render
    });
}

QImage PanoramaRenderItem::getFrame() {
    QMutexLocker lock(&m_frameMutex);
    m_newFrameAvailable = false;
    return m_currentFrame;
}

void PanoramaRenderItem::handleError(const std::string& message) {
    emit errorOccurred(QString::fromStdString(message));
}
