#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "ui/VideoRenderItem.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    qmlRegisterType<VideoRenderItem>("RenkoPlayer", 1, 0, "VideoRenderItem");

    QQmlApplicationEngine engine;
    // Load via the module system. The path depends on how qt_add_qml_module handles the file structure.
    // Usually it mirrors the source tree relative to the CMakeLists.txt if not aliased.
    const QUrl url(u"qrc:/qt/qml/RenkoPlayer/src/resources/qml/main.qml"_qs);
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
