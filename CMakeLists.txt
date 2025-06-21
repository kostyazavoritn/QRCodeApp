cmake_minimum_required(VERSION 3.16)

project(QRCodeApp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_NO_PRIVATE_MODULE_WARNING ON)

list(APPEND CMA35KE_PREFIX_PATH "/Users/kostyazavoritn/Qt/6.9.0/ios")
find_package(Qt6 REQUIRED COMPONENTS Quick Sql Qml QuickDialogs2)

set(ZXing_DIR "/usr/local/lib/cmake/ZXing")
find_package(ZXing REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(QRCodeApp
    main.cpp
    qrcodegenerator.cpp
    qrimageprovider.cpp
    databasemanager.cpp
    barcodegenerator.cpp
)

qt_add_qml_module(QRCodeApp
    URI QRCodeApp
    VERSION 1.0
    QML_FILES
        Main.qml
    SOURCES
        qrcodegenerator.h
        qrimageprovider.h
        databasemanager.h
        barcodegenerator.h
        filepicker.h
        filepicker.mm
        SOURCES pdfexporter.h pdfexporter.mm
)



if (CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(CMAKE_OSX_ARCHITECTURES "arm64")

    set(CMAKE_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk")

    set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "18.2")

    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer")
    set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "YQ93D99ALG") # Замените на ваш Team ID
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic")

    set(CMAKE_XCODE_ATTRIBUTE_INFOPLIST_FILE "${CMAKE_SOURCE_DIR}/Info.plist")

    target_link_libraries(QRCodeApp PRIVATE "-framework UIKit" "-framework UniformTypeIdentifiers")

    set_target_properties(QRCodeApp PROPERTIES
            BUILD_WITH_INSTALL_RPATH TRUE
            INSTALL_RPATH "@executable_path/Frameworks"
    )
endif()

set_target_properties(QRCodeApp PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist
    MACOSX_BUNDLE_BUNDLE_NAME "QRCodeApp"
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(QRCodeApp PRIVATE
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickDialogs2
    Qt6::Sql
    ZXing::ZXing

)

target_include_directories(QRCodeApp PRIVATE
    /usr/local/include/ZXing
)

include(GNUInstallDirs)
install(TARGETS QRCodeApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
