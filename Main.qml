import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    title: "QR Code & Barcode Generator"
    visibility: Window.FullScreen

    readonly property int safeAreaTopMargin: 30 // Уменьшаем отступ сверху
    readonly property int safeAreaBottomMargin: 40

    property var batchCodes: [] // Список для хранения кодов из CSV
    property bool isQrCode: true // Для отслеживания типа кода (QR или Barcode)

    TabBar {
        id: tabBar
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: safeAreaTopMargin
        TabButton { text: "Генерация" }
        TabButton { text: "История" }
    }

    StackLayout {
        anchors.fill: parent
        anchors.topMargin: tabBar.height + safeAreaTopMargin
        anchors.bottomMargin: safeAreaBottomMargin
        currentIndex: tabBar.currentIndex

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    RowLayout {
                        TextField {
                            id: inputField
                            placeholderText: "Введите текст для кода"
                            Layout.fillWidth: true
                        }
                        Button {
                            text: "Очистить"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 100 // Минимальная ширина для кнопки
                            onClicked: {
                                inputField.text = "";
                                batchCodes = [];
                                codeImage.source = "";
                                codeImage.visible = false;
                            }
                        }
                    }

                    RowLayout {
                        ComboBox {
                            id: codeTypeCombo
                            model: ["QR", "Barcode"]
                            Layout.preferredWidth: 120 // Фиксированная ширина для ComboBox
                            onCurrentTextChanged: {
                                batchCodes = [];
                                codeImage.source = "";
                                codeImage.visible = false;
                                errorText.visible = false;
                                isQrCode = (currentText === "QR");
                                console.log("codeTypeCombo: isQrCode установлен в", isQrCode);
                            }
                        }
                        Button {
                            text: "Сгенерировать код"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150 // Увеличиваем минимальную ширину кнопки
                            implicitHeight: 40 // Устанавливаем высоту кнопки, чтобы избежать обрезки
                            onClicked: {
                                if (inputField.text.trim() === "") {
                                    console.log("Ошибка: текст пустой");
                                    errorText.text = "Текст не может быть пустым";
                                    errorText.visible = true;
                                    return;
                                }
                                console.log("Генерация кода для текста:", inputField.text, "Тип:", codeTypeCombo.currentText);
                                busyIndicator.visible = true;
                                codeImage.visible = false;
                                errorText.visible = false;
                                batchCodes = []; // Очищаем список при генерации одного кода
                                if (codeTypeCombo.currentText === "QR") {
                                    qrCodeGenerator.generateQrCode(inputField.text);
                                } else {
                                    barcodeGenerator.generateBarcode(inputField.text);
                                }
                            }
                        }
                    }

                    RowLayout {
                        ComboBox {
                            id: csvCodeTypeCombo
                            model: ["QR", "Barcode"]
                            Layout.preferredWidth: 120 // Фиксированная ширина для ComboBox
                            onCurrentTextChanged: {
                                isQrCode = (currentText === "QR");
                                console.log("csvCodeTypeCombo: isQrCode установлен в", isQrCode);
                            }
                        }
                        Button {
                            text: "Выбрать CSV"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150 // Увеличиваем минимальную ширину кнопки
                            implicitHeight: 40 // Устанавливаем высоту кнопки
                            onClicked: {
                                console.log("Запуск выбора CSV файла");
                                busyIndicator.visible = true;
                                codeImage.visible = false;
                                errorText.visible = false;
                                batchCodes = []; // Очищаем список перед генерацией из CSV
                                // Явно обновляем isQrCode перед генерацией
                                isQrCode = (csvCodeTypeCombo.currentText === "QR");
                                console.log("Перед генерацией из CSV: isQrCode =", isQrCode);
                                filePicker.pickCsvFile();
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollView {
                        anchors.fill: parent
                        clip: true

                        ListView {
                            id: codeListView
                            model: batchCodes
                            spacing: 20

                            delegate: Column {
                                width: parent.width
                                spacing: 10

                                Text {
                                    text: "Текст: " + modelData.text
                                    font.pixelSize: 16
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "black"
                                }

                                Image {
                                    id: batchCodeImage
                                    source: "image://qrimageprovider/" + modelData.text + "?" + Date.now()
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 350
                                    height: isQrCode ? 350 : 120
                                    fillMode: Image.PreserveAspectFit // Сохраняем пропорции
                                    cache: false
                                    onStatusChanged: {
                                        console.log("Статус batchCodeImage:", status, "source:", source, "isQrCode:", isQrCode);
                                        if (status === Image.Error) {
                                            console.log("Ошибка загрузки изображения для текста:", modelData.text);
                                            errorText.text = "Не удалось загрузить изображение";
                                            errorText.visible = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Image {
                        id: codeImage
                        anchors.centerIn: parent
                        width: 350
                        height: codeTypeCombo.currentText === "Barcode" ? 120 : 350
                        fillMode: Image.PreserveAspectFit // Сохраняем пропорции
                        cache: false
                        visible: false

                        onStatusChanged: {
                            console.log("Статус codeImage:", status, "source:", source);
                            if (status === Image.Ready) {
                                console.log("Изображение загружено");
                                codeImage.visible = true;
                            }
                            if (status === Image.Error) {
                                console.log("Ошибка загрузки изображения:", source);
                                errorText.text = "Не удалось загрузить изображение";
                                errorText.visible = true;
                            }
                        }
                    }

                    BusyIndicator {
                        id: busyIndicator
                        anchors.centerIn: parent
                        visible: false
                    }

                    Text {
                        id: errorText
                        anchors.centerIn: parent
                        color: "red"
                        visible: false
                    }
                }
            }
        }

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10

                RowLayout {
                    TextField {
                        id: filterTextField
                        placeholderText: "Фильтр по тексту"
                        Layout.fillWidth: true
                    }
                    TextField {
                        id: dateFilterField
                        placeholderText: "Фильтр по дате"
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "Фильтровать"
                        Layout.minimumWidth: 100 // Минимальная ширина для кнопки
                        implicitHeight: 40 // Устанавливаем высоту кнопки
                        onClicked: loadHistory()
                    }
                }

                Button {
                    text: "Очистить фильтры"
                    Layout.fillWidth: true
                    implicitHeight: 40 // Устанавливаем высоту кнопки
                    onClicked: {
                        filterTextField.text = "";
                        dateFilterField.text = "";
                        loadHistory();
                    }
                }

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: historyModel }
                    delegate: Item {
                        width: historyList.width
                        height: 120
                        Row {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 10

                            Image {
                                id: historyCodeImage
                                width: 80
                                height: model.code_type === "Barcode" ? 30 : 80
                                source: model.imageSource
                                cache: false
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        console.log("Ошибка загрузки изображения в истории:", source);
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Текст: " + model.text }
                                Text { text: "Тип: " + model.code_type }
                                Text { text: "Дата: " + model.created_at }
                            }
                        }
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "lightgray"
                            anchors.bottom: parent.bottom
                        }
                    }
                    clip: true
                }
            }
        }
    }

    function loadHistory() {
        console.log("Загрузка истории с фильтрами:", filterTextField.text, dateFilterField.text);
        var history = databaseManager.getAllCodes(filterTextField.text, dateFilterField.text);
        console.log("Получено кодов:", history.length);
        historyModel.clear();
        for (var i = 0; i < history.length; i++) {
            var code = history[i];
            console.log("Код", i, ": text =", code.text, "type =", code.code_type, "created_at =", code.created_at);
            var imageId = code.code_type.toLowerCase() + "_" + Qt.md5(code.text);
            var imageSource = "image://qrimageprovider/" + imageId + "?" + Date.now();
            historyModel.append({
                text: code.text,
                code_type: code.code_type,
                created_at: code.created_at,
                imageSource: imageSource
            });
            if (code.code_type === "QR") {
                qrCodeGenerator.generateQrCodeForHistory(code.text, imageId);
            } else if (code.code_type === "Barcode") {
                barcodeGenerator.generateBarcodeForHistory(code.text, imageId);
            }
        }
    }

    Connections {
        target: qrCodeGenerator
        function onQrCodeGenerated() {
            console.log("Сигнал qrCodeGenerated получен");
            busyIndicator.visible = false;
            errorText.visible = false;
            codeImage.source = "";
            codeImage.source = "image://qrimageprovider/qr?" + Date.now();
            console.log("codeImage.source установлен:", codeImage.source);
            loadHistory();
        }
        function onBatchQrCodesGenerated(codes) {
            console.log("Получены batch QR-коды:", codes);
            busyIndicator.visible = false;
            batchCodes = codes;
            // Принудительно обновляем ListView
            codeListView.forceLayout();
            loadHistory();
        }
        function onErrorOccurred(error) {
            console.log("Ошибка QR:", error);
            busyIndicator.visible = false;
            errorText.text = error;
            errorText.visible = true;
            codeImage.visible = false;
        }
    }

    Connections {
        target: barcodeGenerator
        function onBarcodeGenerated() {
            console.log("Сигнал barcodeGenerated получен");
            busyIndicator.visible = false;
            errorText.visible = false;
            codeImage.source = "";
            codeImage.source = "image://qrimageprovider/barcode?" + Date.now();
            console.log("codeImage.source установлен:", codeImage.source);
            loadHistory();
        }
        function onBatchBarcodesGenerated(barcodes) {
            console.log("Получены batch штрихкоды:", barcodes);
            busyIndicator.visible = false;
            batchCodes = barcodes;
            // Принудительно обновляем ListView
            codeListView.forceLayout();
            loadHistory();
        }
        function onErrorOccurred(error) {
            console.log("Ошибка Barcode:", error);
            busyIndicator.visible = false;
            errorText.text = error;
            errorText.visible = true;
            codeImage.visible = false;
        }
    }

    Connections {
        target: filePicker
        function onFilePicked(filePath) {
            console.log("Выбран файл CSV:", filePath);
            busyIndicator.visible = true;
            codeImage.visible = false;
            errorText.visible = false;
            if (csvCodeTypeCombo.currentText === "QR") {
                qrCodeGenerator.generateFromCsv(filePath);
            } else {
                barcodeGenerator.generateFromCsv(filePath);
            }
        }
        function onErrorOccurred(error) {
            console.log("Ошибка выбора файла:", error);
            busyIndicator.visible = false;
            errorText.text = error;
            errorText.visible = true;
            codeImage.visible = false;
        }
    }

    Component.onCompleted: loadHistory()
}
