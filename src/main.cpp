#include <QApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QQuickWindow>
#include "ui/VideoRenderItem.h"
#include "ui/PanoramaRenderItem.h"

int main(int argc, char *argv[]) {
    // Force OpenGL backend for QQuickFramebufferObject support
    // Windows defaults to Direct3D 11 in Qt 6, which breaks QOpenGL* classes
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    // Request OpenGL Compatibility Profile for wider shader support
    QSurfaceFormat format;
    format.setRenderableType(QSurfaceFormat::OpenGL);
    format.setProfile(QSurfaceFormat::CompatibilityProfile);
    format.setVersion(3, 2);
    QSurfaceFormat::setDefaultFormat(format);

    // Disable native dialogs to prevent COM/Shell errors with OpenGL backend on Windows
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs);

    QApplication app(argc, argv);

    // Updated path for Qt 6 Standard Policy (QTP0001)
    // Default prefix is /qt/qml/<URI>/...
    app.setWindowIcon(QIcon(":/qt/qml/RenkoPlayer/assets/icons/app.ico"));

    qmlRegisterType<VideoRenderItem>("RenkoPlayer", 1, 0, "VideoRenderItem");
    qmlRegisterType<PanoramaRenderItem>("RenkoPlayer", 1, 0, "PanoramaRenderItem");

    QQmlApplicationEngine engine;
    
    // Add local QML directory to import path
    // The build system copies QML modules to <build_dir>/qml, which is one level up from <build_dir>/Debug/RenkoPlayer.exe
    QString localQmlPath = QCoreApplication::applicationDirPath() + "/../qml";
    engine.addImportPath(localQmlPath);
    qDebug() << "Added local QML path:" << localQmlPath;

    // Debug: Print import paths
    qDebug() << "QML Import Paths:" << engine.importPathList();
    qDebug() << "QML2_IMPORT_PATH env:" << qgetenv("QML2_IMPORT_PATH");

    // Updated path for Qt 6 Standard Policy (QTP0001)
    const QUrl url(u"qrc:/qt/qml/RenkoPlayer/src/qml/main.qml"_qs);
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
