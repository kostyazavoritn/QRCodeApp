#include "filepicker.h"
#include <QDebug>
#include <QStandardPaths>

#ifdef Q_OS_IOS
#include <UIKit/UIKit.h>
#include <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface DocumentPickerDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, assign) void* picker;
@property (nonatomic, assign) BOOL isExportMode;
@end

@implementation DocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    FilePicker* filePicker = static_cast<FilePicker*>(self.picker);
    if (self.isExportMode) {
        if (urls.count > 0) {
            NSURL *url = urls[0];
            qDebug() << "PDF сохранён по пути:" << QString::fromNSString([url absoluteString]);
            emit filePicker->fileExported(QString::fromNSString([url absoluteString]));
        } else {
            emit filePicker->errorOccurred("Место для сохранения PDF не выбрано");
        }
    } else {
        if (urls.count > 0) {
            NSURL *url = urls[0];
            qDebug() << "URL выбранного файла:" << QString::fromNSString([url absoluteString]);

            // Проверяем исходный путь
            NSString *originalPath = [url path];
            qDebug() << "Исходный путь файла:" << QString::fromNSString(originalPath);

            // Проверяем, существует ли файл по исходному пути
            BOOL originalFileExists = [[NSFileManager defaultManager] fileExistsAtPath:originalPath];
            qDebug() << "Файл существует по исходному пути:" << originalFileExists;

            if (!originalFileExists) {
                emit filePicker->errorOccurred("Файл не существует по исходному пути");
                return;
            }

            // Проверяем доступность файла
            BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:originalPath];
            qDebug() << "Файл доступен для чтения:" << isReadable;

            if (!isReadable) {
                emit filePicker->errorOccurred("Файл недоступен для чтения");
                return;
            }

            // Копируем файл в папку Documents приложения
            NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
            qDebug() << "Путь к папке Documents:" << QString::fromNSString(documentsPath);

            // Проверяем, существует ли папка Documents и доступна ли она
            BOOL documentsExists = [[NSFileManager defaultManager] fileExistsAtPath:documentsPath];
            qDebug() << "Папка Documents существует:" << documentsExists;

            BOOL documentsWritable = [[NSFileManager defaultManager] isWritableFileAtPath:documentsPath];
            qDebug() << "Папка Documents доступна для записи:" << documentsWritable;

            if (!documentsExists || !documentsWritable) {
                emit filePicker->errorOccurred("Папка Documents недоступна");
                return;
            }

            NSString *fileName = [url lastPathComponent];
            NSString *destinationPath = [documentsPath stringByAppendingPathComponent:fileName];
            qDebug() << "Путь для копирования файла:" << QString::fromNSString(destinationPath);

            // Удаляем существующий файл, если он есть
            if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
                NSError *removeError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&removeError];
                if (removeError) {
                    qDebug() << "Ошибка удаления существующего файла:" << QString::fromNSString([removeError localizedDescription]);
                } else {
                    qDebug() << "Существующий файл удалён перед копированием";
                }
            }

            // Копируем файл
            NSError *error = nil;
            BOOL copySuccess = [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:destinationPath] error:&error];
            if (!copySuccess || error) {
                qDebug() << "Ошибка копирования файла:" << QString::fromNSString([error localizedDescription]);
                emit filePicker->errorOccurred("Не удалось скопировать файл: " + QString::fromNSString([error localizedDescription]));
                return;
            }

            // Проверяем, существует ли скопированный файл
            BOOL copiedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:destinationPath];
            qDebug() << "Скопированный файл существует:" << copiedFileExists;

            if (!copiedFileExists) {
                emit filePicker->errorOccurred("Скопированный файл не найден");
                return;
            }

            // Проверяем, доступен ли скопированный файл для чтения
            BOOL copiedFileReadable = [[NSFileManager defaultManager] isReadableFileAtPath:destinationPath];
            qDebug() << "Скопированный файл доступен для чтения:" << copiedFileReadable;

            if (!copiedFileReadable) {
                emit filePicker->errorOccurred("Скопированный файл недоступен для чтения");
                return;
            }

            QString qtFilePath = QString::fromNSString(destinationPath);
            qDebug() << "Выбранный и скопированный файл, путь:" << qtFilePath;

            emit filePicker->filePicked(qtFilePath);
        } else {
            emit filePicker->errorOccurred("Файл не выбран");
        }
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    FilePicker* filePicker = static_cast<FilePicker*>(self.picker);
    if (self.isExportMode) {
        emit filePicker->errorOccurred("Сохранение PDF отменено");
    } else {
        emit filePicker->errorOccurred("Выбор файла отменён");
    }
}
@end

void FilePicker::pickFile() {
    UIWindowScene *scene = UIApplication.sharedApplication.windows.firstObject.windowScene;
    UIViewController *rootController = scene.windows.firstObject.rootViewController;

    NSArray *types = @[UTTypeCommaSeparatedText];
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    DocumentPickerDelegate *delegate = [[DocumentPickerDelegate alloc] init];
    delegate.picker = this;
    delegate.isExportMode = NO;
    documentPicker.delegate = delegate;
    [rootController presentViewController:documentPicker animated:YES completion:nil];
}

void FilePicker::exportFile(const QString &filePath) {
    UIWindowScene *scene = UIApplication.sharedApplication.windows.firstObject.windowScene;
    UIViewController *rootController = scene.windows.firstObject.rootViewController;

    NSURL *url = [NSURL fileURLWithPath:filePath.toNSString()];
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeExportToService];
    DocumentPickerDelegate *delegate = [[DocumentPickerDelegate alloc] init];
    delegate.picker = this;
    delegate.isExportMode = YES;
    documentPicker.delegate = delegate;
    [rootController presentViewController:documentPicker animated:YES completion:nil];
}
#else
void FilePicker::pickFile() {
    emit errorOccurred("Выбор файла поддерживается только на iOS");
}

void FilePicker::exportFile(const QString &filePath) {
    emit errorOccurred("Экспорт файла поддерживается только на iOS");
}
#endif
