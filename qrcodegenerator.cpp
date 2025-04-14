#include "qrcodegenerator.h"
#include <ZXing/BarcodeFormat.h>
#include <ZXing/MultiFormatWriter.h>
#include <ZXing/BitMatrix.h>
#include <QImage>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QStringConverter>

QrcodeGenerator::QrcodeGenerator(QObject *parent) : QObject(parent), m_dbManager(nullptr), m_imageProvider(nullptr)
{
}

void QrcodeGenerator::setImageProvider(QRImageProvider *provider)
{
    m_imageProvider = provider;
}

void QrcodeGenerator::setDatabaseManager(DatabaseManager *dbManager)
{
    m_dbManager = dbManager;
}

void QrcodeGenerator::generateQrCode(const QString &text)
{
    try {
        if (text.isEmpty()) {
            emit errorOccurred("Текст не может быть пустым");
            return;
        }
        ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::QRCode};
        auto matrix = writer.encode(text.toStdWString(), 350, 350);
        m_qrImage = QImage(350, 350, QImage::Format_RGB32);
        m_qrImage.fill(Qt::white);

        for (int y = 0; y < matrix.height(); ++y) {
            for (int x = 0; x < matrix.width(); ++x) {
                if (matrix.get(x, y)) {
                    m_qrImage.setPixel(x, y, qRgb(0, 0, 0));
                }
            }
        }
        qDebug() << "QR-код сгенерирован, размер:" << m_qrImage.size() << "isNull:" << m_qrImage.isNull();
        if (m_qrImage.isNull()) {
            emit errorOccurred("Не удалось создать QR-изображение");
            return;
        }
        if (m_imageProvider) {
            m_imageProvider->setQrImage(m_qrImage);
            qDebug() << "QR-изображение установлено в провайдер";
        } else {
            emit errorOccurred("Image provider не установлен");
            return;
        }

        if (m_dbManager) {
            m_dbManager->addCode(text, "QR");
        }

        emit qrCodeGenerated();
    } catch (const std::exception &e) {
        qDebug() << "Исключение при генерации QR-кода:" << e.what();
        emit errorOccurred(QString("Ошибка генерации QR-кода: %1").arg(e.what()));
    }
}

void QrcodeGenerator::generateQrCodeForHistory(const QString &text, const QString &imageId)
{
    try {
        if (text.isEmpty()) {
            qDebug() << "generateQrCodeForHistory: Пустой текст";
            return;
        }

        // Проверяем, есть ли изображение в m_qrImage или m_batchCodes
        if (m_imageProvider) {
            QImage existingImage = m_imageProvider->getQrImage();
            if (!existingImage.isNull() && existingImage.size() == QSize(350, 350)) {
                qDebug() << "Изображение для текста" << text << "уже есть в m_qrImage, пропускаем генерацию";
                m_imageProvider->setImageForId(imageId, existingImage);
                return;
            }

            for (const auto &pair : m_batchCodes) {
                if (pair.first == text) {
                    qDebug() << "Изображение для текста" << text << "найдено в m_batchCodes, пропускаем генерацию";
                    m_imageProvider->setImageForId(imageId, pair.second);
                    return;
                }
            }
        }

        // Генерируем изображение в оригинальном размере 350x350
        ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::QRCode};
        auto matrix = writer.encode(text.toStdWString(), 350, 350);
        QImage image(350, 350, QImage::Format_RGB32);
        image.fill(Qt::white);

        for (int y = 0; y < matrix.height(); ++y) {
            for (int x = 0; x < matrix.width(); ++x) {
                if (matrix.get(x, y)) {
                    image.setPixel(x, y, qRgb(0, 0, 0));
                }
            }
        }
        qDebug() << "QR-код для истории сгенерирован, imageId:" << imageId << "размер:" << image.size() << "isNull:" << image.isNull();
        if (image.isNull()) {
            qDebug() << "generateQrCodeForHistory: Не удалось создать изображение";
            return;
        }
        if (m_imageProvider) {
            m_imageProvider->setImageForId(imageId, image);
            qDebug() << "QR-изображение для imageId" << imageId << "установлено в провайдер";
        } else {
            qDebug() << "generateQrCodeForHistory: m_imageProvider не установлен";
        }
    } catch (const std::exception &e) {
        qDebug() << "Исключение при генерации QR-кода для истории:" << e.what();
    }
}

void QrcodeGenerator::generateFromCsv(const QString &filePath)
{
    try {
        qDebug() << "Получен путь к файлу:" << filePath;

        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            emit errorOccurred(QString("Не удалось открыть CSV файл: %1").arg(file.errorString()));
            return;
        }

        QByteArray fileContent = file.readAll();
        qDebug() << "Сырое содержимое файла:" << fileContent;
        file.seek(0);

        m_batchCodes.clear();
        QTextStream in(&file);
        in.setEncoding(QStringConverter::Utf8);
        int lineNumber = 0;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            lineNumber++;
            qDebug() << "Линия" << lineNumber << "прочитана из CSV:" << line;
            if (line.isEmpty()) {
                qDebug() << "Линия" << lineNumber << "пуста, пропускаем";
                continue;
            }

            QString text = line.trimmed();
            if (text.isEmpty()) {
                qDebug() << "Линия" << lineNumber << "пуста после обрезки, пропускаем";
                continue;
            }

            qDebug() << "Обработка текста из CSV:" << text;

            ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::QRCode};
            auto matrix = writer.encode(text.toStdWString(), 350, 350);
            QImage image(350, 350, QImage::Format_RGB32);
            image.fill(Qt::white);

            for (int y = 0; y < matrix.height(); ++y) {
                for (int x = 0; x < matrix.width(); ++x) {
                    if (matrix.get(x, y)) {
                        image.setPixel(x, y, qRgb(0, 0, 0));
                    }
                }
            }
            m_batchCodes.append(qMakePair(text, image));
            qDebug() << "Добавлено в m_batchCodes: текст =" << text;

            if (m_dbManager) {
                m_dbManager->addCode(text, "QR");
            }
        }
        file.close();

        if (m_batchCodes.isEmpty()) {
            emit errorOccurred("В CSV файле нет валидных данных");
            return;
        }

        qDebug() << "Всего элементов в m_batchCodes:" << m_batchCodes.size();
        for (int i = 0; i < m_batchCodes.size(); ++i) {
            qDebug() << "m_batchCodes[" << i << "]: текст =" << m_batchCodes[i].first;
        }

        if (!m_imageProvider) {
            emit errorOccurred("Image provider не установлен");
            return;
        }

        m_imageProvider->setBatchImages(m_batchCodes);

        // Передаём список кодов в QML
        QVariantList codesList;
        for (int i = 0; i < m_batchCodes.size(); ++i) {
            QVariantMap codeEntry;
            codeEntry["text"] = m_batchCodes[i].first;
            codeEntry["index"] = i;
            codesList.append(codeEntry);
        }
        emit batchQrCodesGenerated(codesList);

    } catch (const std::exception &e) {
        emit errorOccurred(QString("Ошибка обработки CSV: %1").arg(e.what()));
    }
}

QImage QrcodeGenerator::getQrImage() const
{
    return m_qrImage;
}
