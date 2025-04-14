#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

#include <QObject>
#include <QImage>

class PdfExporter : public QObject
{
    Q_OBJECT
public:
    explicit PdfExporter(QObject *parent = nullptr);

    Q_INVOKABLE void exportSingleQRCode(const QString &text, const QString &codeType);
    Q_INVOKABLE void exportAllQRCodes();

private:
    QImage generateQRCode(const QString &text, const QString &codeType);
    QString savePDFToTempFile(const QList<QPair<QString, QImage>> &qrCodes);
    void presentDocumentPicker(const QString &filePath);
};

#endif // PDFEXPORTER_H
