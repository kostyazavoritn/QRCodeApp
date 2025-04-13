#ifndef BARCODEGENERATOR_H
#define BARCODEGENERATOR_H

#include <QObject>
#include <QImage>
#include "qrimageprovider.h"
#include "databasemanager.h"

class BarcodeGenerator : public QObject
{
    Q_OBJECT
public:
    explicit BarcodeGenerator(QObject *parent = nullptr);

    void setImageProvider(QRImageProvider *provider);
    void setDatabaseManager(DatabaseManager *dbManager);

    QImage getBarcodeImage() const;

public slots:
    void generateBarcode(const QString &text);
    void generateBarcodeForHistory(const QString &text, const QString &imageId);
    void generateFromCsv(const QString &filePath);

signals:
    void barcodeGenerated();
    void batchBarcodesGenerated(const QVariantList &barcodes);
    void errorOccurred(const QString &error);

private:
    QImage m_barcodeImage;
    QRImageProvider *m_imageProvider;
    DatabaseManager *m_dbManager;
    QList<QPair<QString, QImage>> m_batchBarcodes;
};

#endif // BARCODEGENERATOR_H
