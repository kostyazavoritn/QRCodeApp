# QRCodeApp
Приложение для генерации QR-кодов и штрихкодов.
Используется библиотека zxing, установленная для устройства ios на архитектуре arm64
После клонирования репозитория https://github.com/zxing-cpp/zxing-cpp, собирается с помощью:
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
sudo cmake --install .
