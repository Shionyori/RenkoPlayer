#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqml.h>

class FileSystemHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit FileSystemHelper(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList getDrives();
};
