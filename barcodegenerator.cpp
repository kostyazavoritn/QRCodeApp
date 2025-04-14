#include "barcodegenerator.h"
#include <ZXing/BarcodeFormat.h>
#include <ZXing/MultiFormatWriter.h>
#include <ZXing/BitMatrix.h>
#include <QImage>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QStringConverter>

BarcodeGenerator::BarcodeGenerator(QObject *parent) : QObject(parent), m_dbManager(nullptr), m_imageProvider(nullptr)
{
}

void BarcodeGenerator::setImageProvider(QRImageProvider *provider)
{
    m_imageProvider = provider;
}

void BarcodeGenerator::setDatabaseManager(DatabaseManager *dbManager)
{
    m_dbManager = dbManager;
}

void BarcodeGenerator::generateBarcode(const QString &text)
{
    try {
        if (text.isEmpty()) {
            emit errorOccurred("Текст не может быть пустым");
            return;
        }

        ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::Code128};
        auto matrix = writer.encode(text.toStdWString(), 350, 120);
        m_barcodeImage = QImage(350, 120, QImage::Format_RGB32);
        m_barcodeImage.fill(Qt::white);

        for (int y = 0; y < matrix.height(); ++y) {
            for (int x = 0; x < matrix.width(); ++x) {
                if (matrix.get(x, y)) {
                    m_barcodeImage.setPixel(x, y, qRgb(0, 0, 0));
                }
            }
        }

        qDebug() << "Штрихкод сгенерирован, размер:" << m_barcodeImage.size() << "isNull:" << m_barcodeImage.isNull();
        if (m_barcodeImage.isNull()) {
            emit errorOccurred("Не удалось создать штрихкод");
            return;
        }
        if (m_imageProvider) {
            m_imageProvider->setBarcodeImage(m_barcodeImage);
            qDebug() << "Штрихкод установлен в провайдер";
        } else {
            emit errorOccurred("Image provider не установлен");
            return;
        }

        if (m_dbManager) {
            m_dbManager->addCode(text, "Barcode");
        }

        emit barcodeGenerated();
    } catch (const std::exception &e) {
        qDebug() << "Исключение при генерации штрихкода:" << e.what();
        emit errorOccurred(QString("Ошибка генерации штрихкода: %1").arg(e.what()));
    }
}

void BarcodeGenerator::generateBarcodeForHistory(const QString &text, const QString &imageId)
{
    try {
        if (text.isEmpty()) {
            qDebug() << "generateBarcodeForHistory: Пустой текст";
            return;
        }

        ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::Code128};
        auto matrix = writer.encode(text.toStdWString(), 350, 120);
        QImage image(350, 120, QImage::Format_RGB32);
        image.fill(Qt::white);

        for (int y = 0; y < matrix.height(); ++y) {
            for (int x = 0; x < matrix.width(); ++x) {
                if (matrix.get(x, y)) {
                    image.setPixel(x, y, qRgb(0, 0, 0));
                }
            }
        }

        qDebug() << "Штрихкод для истории сгенерирован, imageId:" << imageId << "размер:" << image.size() << "isNull:" << image.isNull();
        if (image.isNull()) {
            qDebug() << "generateBarcodeForHistory: Не удалось создать изображение";
            return;
        }
        if (m_imageProvider) {
            m_imageProvider->setImageForId(imageId, image);
            qDebug() << "Штрихкод для imageId" << imageId << "установлен в провайдер";
        } else {
            qDebug() << "generateBarcodeForHistory: m_imageProvider не установлен";
        }
    } catch (const std::exception &e) {
        qDebug() << "Исключение при генерации штрихкода для истории:" << e.what();
    }
}

void BarcodeGenerator::generateFromCsv(const QString &filePath)
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

        m_batchBarcodes.clear();
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

            ZXing::MultiFormatWriter writer{ZXing::BarcodeFormat::Code128};
            auto matrix = writer.encode(text.toStdWString(), 350, 120);
            QImage image(350, 120, QImage::Format_RGB32);
            image.fill(Qt::white);

            for (int y = 0; y < matrix.height(); ++y) {
                for (int x = 0; x < matrix.width(); ++x) {
                    if (matrix.get(x, y)) {
                        image.setPixel(x, y, qRgb(0, 0, 0));
                    }
                }
            }
            m_batchBarcodes.append(qMakePair(text, image));
            qDebug() << "Добавлено в m_batchBarcodes: текст =" << text;

            if (m_dbManager) {
                m_dbManager->addCode(text, "Barcode");
            }
        }
        file.close();

        if (m_batchBarcodes.isEmpty()) {
            emit errorOccurred("В CSV файле нет валидных данных");
            return;
        }

        qDebug() << "Всего элементов в m_batchBarcodes:" << m_batchBarcodes.size();
        for (int i = 0; i < m_batchBarcodes.size(); ++i) {
            qDebug() << "m_batchBarcodes[" << i << "]: текст =" << m_batchBarcodes[i].first;
        }

        if (!m_imageProvider) {
            emit errorOccurred("Image provider не установлен");
            return;
        }

        m_imageProvider->setBatchImages(m_batchBarcodes);

        // Передаём список кодов в QML
        QVariantList barcodesList;
        for (int i = 0; i < m_batchBarcodes.size(); ++i) {
            QVariantMap barcodeEntry;
            barcodeEntry["text"] = m_batchBarcodes[i].first;
            barcodeEntry["index"] = i;
            barcodesList.append(barcodeEntry);
        }
        emit batchBarcodesGenerated(barcodesList);

    } catch (const std::exception &e) {
        emit errorOccurred(QString("Ошибка обработки CSV: %1").arg(e.what()));
    }
}

QImage BarcodeGenerator::getBarcodeImage() const
{
    return m_barcodeImage;
}
