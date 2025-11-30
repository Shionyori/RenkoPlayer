#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include "ui/VideoRenderItem.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    // Updated path for Qt 6 Standard Policy (QTP0001)
    // Default prefix is /qt/qml/<URI>/...
    app.setWindowIcon(QIcon(":/qt/qml/RenkoPlayer/src/resources/app_icon.png"));

    qmlRegisterType<VideoRenderItem>("RenkoPlayer", 1, 0, "VideoRenderItem");

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
    const QUrl url(u"qrc:/qt/qml/RenkoPlayer/src/resources/qml/main.qml"_qs);
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
