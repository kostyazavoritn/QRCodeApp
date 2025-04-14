#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

#include <QObject>
#include <QList>
#include <QPair>
#include <QImage>
#include "qrimageprovider.h"
#include "databasemanager.h"

class PdfExporter : public QObject
{
    Q_OBJECT
public:
    explicit PdfExporter(QObject *parent = nullptr);

    void setImageProvider(QRImageProvider *provider);
    void setDatabaseManager(DatabaseManager *dbManager);

    Q_INVOKABLE void exportSingleQRCode(const QString &text, const QString &codeType, const QString &imageId);
    Q_INVOKABLE void exportAllQRCodes();

private:
    QString savePDFToTempFile(const QVariantList &codes);

    QRImageProvider *m_imageProvider;
    DatabaseManager *m_dbManager;

signals:
    void pdfGenerated(const QString &filePath);
    void errorOccurred(const QString &error);
};

#endif // PDFEXPORTER_H
