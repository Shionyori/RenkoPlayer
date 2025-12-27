#include "FileSystemHelper.h"
#include <QDir>
#include <QStorageInfo>

FileSystemHelper::FileSystemHelper(QObject *parent)
    : QObject(parent) {}

QVariantList FileSystemHelper::getDrives()
{
    QVariantList drivesList;
    const QFileInfoList drives = QDir::drives();

    for (const QFileInfo &drive : drives) {
        QVariantMap driveMap;
        QString path = drive.absoluteFilePath();
        QString name = path;
        
        QStorageInfo storage(path);
        if (storage.isValid() && !storage.name().isEmpty()) {
            name = QString("%1 (%2)").arg(storage.name(), path);
        }

        driveMap["fileName"] = name;
        driveMap["filePath"] = "file:///" + path;
        driveMap["fileIsDir"] = true;
        driveMap["fileSize"] = 0;
        driveMap["fileModified"] = QDateTime::currentDateTime(); // Dummy
        
        drivesList.append(driveMap);
    }

    return drivesList;
}
