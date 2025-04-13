#ifndef QRCODEGENERATOR_H
#define QRCODEGENERATOR_H

#include <QObject>
#include <QImage>
#include "qrimageprovider.h"
#include "databasemanager.h"

class QrcodeGenerator : public QObject
{
    Q_OBJECT
public:
    explicit QrcodeGenerator(QObject *parent = nullptr);

    void setImageProvider(QRImageProvider *provider);
    void setDatabaseManager(DatabaseManager *dbManager);

    QImage getQrImage() const;

public slots:
    void generateQrCode(const QString &text);
    void generateQrCodeForHistory(const QString &text, const QString &imageId);
    void generateFromCsv(const QString &filePath);

signals:
    void qrCodeGenerated();
    void batchQrCodesGenerated(const QVariantList &codes);
    void errorOccurred(const QString &error);

private:
    QImage m_qrImage;
    QRImageProvider *m_imageProvider;
    DatabaseManager *m_dbManager;
    QList<QPair<QString, QImage>> m_batchCodes;
};

#endif // QRCODEGENERATOR_H
