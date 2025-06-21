# QRCodeApp
Приложение для генерации QR-кодов и штрихкодов.

## Системные требования
- iOS 18.2 или выше (тестировалось на iPhone 13 с iOS 18.4)
- Qt 6.5+
- CMake 3.22+
- Xcode 16.2+
- Библиотеки:
  - ZXing-C++ (для генерации QR-кодов и штрихкодов)
  - SQLite (для локального хранения данных, обычно предустановлен на macOS)

# Установка Zxing и сборка
После клонирования репозитория https://github.com/zxing-cpp/zxing-cpp, собирается с параметрами:
cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_INCLUDEDIR=include
cmake --build . --config Release
cmake --install .

# Примеры использования
Генерация QR-кода: Введите URL (например, https://ya.ru) во вкладке "Генерация", выберите "QR" и нажмите "Сгенерировать код".
Пакетная обработка: Загрузите CSV-файл через Document Picker для создания нескольких кодов (см. пример CSV в docs/sample.csv).
Экспорт в PDF: Перейдите во вкладку "История" и нажмите "Экспорт всей истории в PDF" или нажмите "Экспорт" около конкретного кода. 

# Диаграммы
Диаграмма C4 Container: Показывает контейнеры системы: iOS-приложение (QML UI и C++ логика), SQLite, ZXing. Иллюстрирует взаимодействие через сигналы/слоты и потоки данных.

![C4 Container Diagram](https://github.com/kostyazavoritn/QRCodeApp/blob/main/C4_container.jpg)

Диаграммма URL Class Diagram: Показывает классы (QrcodeGenerator, BarcodeGenerator, DatabaseManager, QRImageProvider, PdfExporter, FilePicker), их атрибуты, методы и связи (композиция, зависимость). Упрощает понимание структуры кода.

![URL Class Diagram](https://github.com/kostyazavoritn/QRCodeApp/blob/main/UML_Class_Diagram.jpg)

Диаграмма URL Sequence Diagram: Иллюстрирует взаимодействие объектов (QML Interface, QrcodeGenerator, DatabaseManager, QRImageProvider) при генерации кода. Показывает вызовы методов, сигналы и обработку ошибок.

![URL Sequence Diagram](https://github.com/kostyazavoritn/QRCodeApp/blob/main/UML_Sequence_Diagram.jpg)

Диаграмма Deployment Digramm: Описывает архитектуру развертывания приложения на устройстве iOS.
![Deployment Diagram](https://github.com/kostyazavoritn/QRCodeApp/blob/main/Deployment_Diagram.jpg)

