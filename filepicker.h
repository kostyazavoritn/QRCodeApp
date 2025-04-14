#ifndef FILEPICKER_H
#define FILEPICKER_H

#include <QObject>

class FilePicker : public QObject {
    Q_OBJECT
public:
    explicit FilePicker(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void pickFile(); // Для выбора CSV
    Q_INVOKABLE void exportFile(const QString &filePath); // Для экспорта PDF

signals:
    void filePicked(const QString &filePath);
    void fileExported(const QString &filePath);
    void errorOccurred(const QString &error);
};

#endif // FILEPICKER_H
