#include "qrimageprovider.h"
#include <QDebug>

QRImageProvider::QRImageProvider() : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage QRImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString cleanId = id.split('?')[0];
    qDebug() << "Запрос изображения с id:" << cleanId;

    if (cleanId == "qr") {
        qDebug() << "Возвращается QR-изображение, isNull:" << m_qrImage.isNull() << "размер:" << m_qrImage.size();
        if (size) *size = m_qrImage.size();
        if (m_qrImage.isNull()) {
            qDebug() << "QR-изображение пустое, возвращается заглушка";
            QImage defaultImage(350, 350, QImage::Format_RGB32); // Соответствует новому размеру
            defaultImage.fill(Qt::white);
            return defaultImage;
        }
        return m_qrImage;
    } else if (cleanId == "barcode") {
        qDebug() << "Возвращается штрихкод, isNull:" << m_barcodeImage.isNull() << "размер:" << m_barcodeImage.size();
        if (size) *size = m_barcodeImage.size();
        if (m_barcodeImage.isNull()) {
            qDebug() << "Штрихкод пустой, возвращается заглушка";
            QImage defaultImage(350, 120, QImage::Format_RGB32); // Соответствует новому размеру
            defaultImage.fill(Qt::white);
            return defaultImage;
        }
        return m_barcodeImage;
    } else if (m_historyImages.contains(cleanId)) {
        QImage image = m_historyImages[cleanId];
        qDebug() << "Возвращается изображение истории, id:" << cleanId << "isNull:" << image.isNull() << "размер:" << image.size();
        if (size) *size = image.size();
        if (image.isNull()) {
            qDebug() << "Изображение истории пустое, возвращается заглушка";
            QImage defaultImage(80, 80, QImage::Format_RGB32);
            defaultImage.fill(Qt::white);
            return defaultImage;
        }
        return image;
    } else {
        // Проверяем m_batchImages для генерации из CSV
        for (const auto &pair : m_batchImages) {
            if (pair.first == cleanId) {
                QImage image = pair.second;
                qDebug() << "Возвращается изображение из m_batchImages, id:" << cleanId << "isNull:" << image.isNull() << "размер:" << image.size();
                if (size) *size = image.size();
                if (image.isNull()) {
                    qDebug() << "Изображение из m_batchImages пустое, возвращается заглушка";
                    QImage defaultImage(350, 350, QImage::Format_RGB32); // Соответствует новому размеру
                    defaultImage.fill(Qt::white);
                    return defaultImage;
                }
                return image;
            }
        }
    }

    qDebug() << "Возвращается пустое изображение для id:" << cleanId;
    QImage defaultImage(350, 350, QImage::Format_RGB32); // Соответствует новому размеру
    defaultImage.fill(Qt::white);
    return defaultImage;
}

void QRImageProvider::setQrImage(const QImage &image)
{
    qDebug() << "Установка QR-кода, размер:" << image.size() << "isNull:" << image.isNull();
    m_qrImage = image;
}

void QRImageProvider::setBarcodeImage(const QImage &image)
{
    qDebug() << "Установка штрихкода, размер:" << image.size() << "isNull:" << image.isNull();
    m_barcodeImage = image;
}

void QRImageProvider::setBatchImages(const QList<QPair<QString, QImage>> &images)
{
    qDebug() << "Установлены batch изображения, размер:" << images.size();
    m_batchImages = images;
}

void QRImageProvider::setImageForId(const QString &imageId, const QImage &image)
{
    qDebug() << "Установка изображения для id:" << imageId << "размер:" << image.size() << "isNull:" << image.isNull();
    m_historyImages[imageId] = image;
}
