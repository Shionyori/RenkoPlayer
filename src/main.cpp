#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "ui/VideoRenderItem.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    qmlRegisterType<VideoRenderItem>("RenkoPlayer", 1, 0, "VideoRenderItem");

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/RenkoPlayer/src/resources/qml/main.qml"_qs);
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
