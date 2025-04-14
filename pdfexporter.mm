#import "pdfexporter.h"
#import <UIKit/UIKit.h>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QCryptographicHash>
#include <QDateTime>

PdfExporter::PdfExporter(QObject *parent) : QObject(parent), m_imageProvider(nullptr), m_dbManager(nullptr)
{
}

void PdfExporter::setImageProvider(QRImageProvider *provider)
{
    m_imageProvider = provider;
}

void PdfExporter::setDatabaseManager(DatabaseManager *dbManager)
{
    m_dbManager = dbManager;
}

QString PdfExporter::savePDFToTempFile(const QVariantList &codes)
{
    if (codes.isEmpty()) {
        qDebug() << "Список кодов пуст, PDF не создан";
        return QString();
    }

    // Формируем имя файла с текущей датой и временем
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir dir(tempPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    QString filePath = tempPath + "/QRCodeApp_" + timestamp + ".pdf";
    qDebug() << "Создание PDF по пути:" << filePath;

    // Настройки страницы PDF (A4: 595 x 842 pt)
    CGRect pageRect = CGRectMake(0, 0, 595, 842);
    UIGraphicsBeginPDFContextToFile(filePath.toNSString(), pageRect, nil);

    CGFloat pageWidth = pageRect.size.width;
    CGFloat pageHeight = pageRect.size.height;

    const CGFloat textHeight = 40; // Высота области для текста
    const CGFloat textMargin = 5;  // Отступ между изображением и текстом

    for (const QVariant &codeVariant : codes) {
        // Добавляем новую страницу для каждого кода
        UIGraphicsBeginPDFPage();

        QVariantMap code = codeVariant.toMap();
        QString text = code["text"].toString();
        QString codeType = code["code_type"].toString();
        QString imageId = codeType.toLower() + "_" + QString(QCryptographicHash::hash(text.toUtf8(), QCryptographicHash::Md5).toHex());

        if (!m_imageProvider) {
            qDebug() << "Image provider не установлен, пропускаем код:" << text;
            continue;
        }

        // Получаем изображение
        QImage image = m_imageProvider->requestImage(imageId, nullptr, QSize());
        if (image.isNull()) {
            qDebug() << "Не удалось получить изображение для кода:" << text << ", imageId:" << imageId;
            continue;
        }

        // Масштабируем изображение
        CGFloat newWidth = 500;
        CGFloat newHeight = 500;
        if (image.size().width() != image.size().height()) {
            newHeight = (image.size().height() * newWidth) / image.size().width();
        }

        // Центрируем по горизонтали
        CGFloat currentX = (pageWidth - newWidth) / 2;

        // Центрируем по вертикали: середина страницы
        CGFloat centerY = pageHeight / 2;
        // Верхняя точка изображения: центр страницы минус половина высоты изображения
        CGFloat imageY = centerY - (newHeight / 2);

        // Конвертируем QImage в UIImage
        QImage imageCopy = image.convertToFormat(QImage::Format_ARGB32);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef provider = CGDataProviderCreateWithData(nullptr, imageCopy.bits(), imageCopy.sizeInBytes(), nullptr);
        CGImageRef imageRef = CGImageCreate(imageCopy.width(), imageCopy.height(), 8, 32, imageCopy.bytesPerLine(),
                                            colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host,
                                            provider, nullptr, false, kCGRenderingIntentDefault);
        UIImage *uiImage = [UIImage imageWithCGImage:imageRef];
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(imageRef);

        if (!uiImage) {
            qDebug() << "Не удалось конвертировать QImage в UIImage для кода:" << text;
            continue;
        }

        // Рисуем изображение
        CGRect imageRect = CGRectMake(currentX, imageY, newWidth, newHeight);
        [uiImage drawInRect:imageRect];

        // Рисуем текст под изображением
        NSString *textNSString = text.toNSString();
        UIFont *font = [UIFont systemFontOfSize:24];
        // Создаём стиль абзаца для центрирования текста
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
        NSDictionary *attributes = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: [UIColor blackColor],
            NSParagraphStyleAttributeName: paragraphStyle
        };
        // Текст начинается сразу после изображения с отступом
        CGRect textRect = CGRectMake(currentX, imageY + newHeight + textMargin, newWidth, textHeight);
        [textNSString drawInRect:textRect withAttributes:attributes];
    }

    UIGraphicsEndPDFContext();
    qDebug() << "PDF успешно создан по пути:" << filePath;
    return filePath;
}

void PdfExporter::exportSingleQRCode(const QString &text, const QString &codeType, const QString &imageId)
{
    QVariantList codes;
    QVariantMap code;
    code["text"] = text;
    code["code_type"] = codeType;
    codes.append(code);

    QString filePath = savePDFToTempFile(codes);
    if (!filePath.isEmpty()) {
        emit pdfGenerated(filePath);
    } else {
        emit errorOccurred("Не удалось создать PDF");
    }
}

void PdfExporter::exportAllQRCodes()
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager не установлен");
        return;
    }

    QVariantList codes = m_dbManager->getAllCodes();
    if (codes.isEmpty()) {
        emit errorOccurred("История пуста");
        return;
    }

    QString filePath = savePDFToTempFile(codes);
    if (!filePath.isEmpty()) {
        emit pdfGenerated(filePath);
    } else {
        emit errorOccurred("Не удалось создать PDF");
    }
}
