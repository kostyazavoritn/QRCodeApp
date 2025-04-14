#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "qrcodegenerator.h"
#include "barcodegenerator.h"
#include "databasemanager.h"
#include "qrimageprovider.h"
#include "filepicker.h"
#include "pdfexporter.h"
#include <QtCore>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    DatabaseManager dbManager;
    if (!dbManager.initialize()) {
        qWarning() << "Ошибка инициализации базы данных, приложение продолжит работу без базы";
    }

    QRImageProvider *imageProvider = new QRImageProvider;

    QrcodeGenerator qrCodeGenerator;
    qrCodeGenerator.setDatabaseManager(&dbManager);
    qrCodeGenerator.setImageProvider(imageProvider);

    BarcodeGenerator barcodeGenerator;
    barcodeGenerator.setDatabaseManager(&dbManager);
    barcodeGenerator.setImageProvider(imageProvider);

    FilePicker filePicker;

    PdfExporter pdfExporter;
    pdfExporter.setImageProvider(imageProvider);
    pdfExporter.setDatabaseManager(&dbManager);

    QQmlApplicationEngine engine;
    engine.addImageProvider("qrimageprovider", imageProvider);
    qDebug() << "ImageProvider registered:" << engine.imageProvider("qrimageprovider");

    engine.rootContext()->setContextProperty("qrCodeGenerator", &qrCodeGenerator);
    engine.rootContext()->setContextProperty("barcodeGenerator", &barcodeGenerator);
    engine.rootContext()->setContextProperty("databaseManager", &dbManager);
    engine.rootContext()->setContextProperty("filePicker", &filePicker);
    engine.rootContext()->setContextProperty("pdfExporter", &pdfExporter);

    const QUrl url(u"qrc:/qt/qml/QRCodeApp/Main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [&url](const QUrl &objUrl) {
        qWarning() << "Ошибка создания объекта для" << objUrl;
        QGuiApplication::exit(-1);
    });

    engine.load(url);

    return app.exec();
}
