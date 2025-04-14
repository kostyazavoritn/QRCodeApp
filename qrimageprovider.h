#ifndef QRIMAGEPROVIDER_H
#define QRIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>
#include <QList>
#include <QPair>
#include <QMap>

class QRImageProvider : public QQuickImageProvider
{
public:
    QRImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

    void setQrImage(const QImage &image);
    void setBarcodeImage(const QImage &image);
    void setBatchImages(const QList<QPair<QString, QImage>> &images);
    void setImageForId(const QString &imageId, const QImage &image);
    QImage getQrImage() const;

private:
    QImage m_qrImage;
    QImage m_barcodeImage;
    QList<QPair<QString, QImage>> m_batchImages;
    QMap<QString, QImage> m_historyImages;
};

#endif // QRIMAGEPROVIDER_H
