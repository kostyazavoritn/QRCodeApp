import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    title: "QR Code & Barcode Generator"
    visibility: Window.FullScreen

    readonly property int safeAreaTopMargin: 20
    readonly property int safeAreaBottomMargin: 40

    property var batchCodes: []
    property bool isQrCode: true

    TabBar {
        id: tabBar
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: 10
        TabButton {
            text: "Генерация"
            implicitHeight: 60
            contentItem: Text {
                text: parent.text
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: palette.dark ? "#FFFFFF" : (parent.checked ? "black" : "gray")
            }
            background: Rectangle {
                color: palette.dark ? "#333333" : palette.button
                opacity: parent.checked ? 1.0 : 0.7
            }
        }
        TabButton {
            text: "История"
            implicitHeight: 60
            contentItem: Text {
                text: parent.text
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: palette.dark ? "#FFFFFF" : (parent.checked ? "black" : "gray")
            }
            background: Rectangle {
                color: palette.dark ? "#333333" : palette.button
                opacity: parent.checked ? 1.0 : 0.7
            }
        }
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
                            Layout.minimumWidth: 100
                            implicitHeight: 40
                            contentItem: Text {
                                text: parent.text
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }
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
                            Layout.preferredWidth: 120
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
                            Layout.minimumWidth: 150
                            implicitHeight: 40
                            contentItem: Text {
                                text: parent.text
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }
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
                                batchCodes = [];
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
                            Layout.preferredWidth: 120
                            onCurrentTextChanged: {
                                isQrCode = (currentText === "QR");
                                console.log("csvCodeTypeCombo: isQrCode установлен в", isQrCode);
                            }
                        }
                        Button {
                            text: "Выбрать CSV"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150
                            implicitHeight: 40
                            contentItem: Text {
                                text: parent.text
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "white"
                            }
                            onClicked: {
                                console.log("Запуск выбора CSV файла");
                                busyIndicator.visible = true;
                                codeImage.visible = false;
                                errorText.visible = false;
                                batchCodes = [];
                                isQrCode = (csvCodeTypeCombo.currentText === "QR");
                                console.log("Перед генерацией из CSV: isQrCode =", isQrCode);
                                filePicker.pickFile();
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
                                    color: palette.windowText
                                }

                                Image {
                                    id: batchCodeImage
                                    source: "image://qrimageprovider/" + modelData.text + "?" + Date.now()
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 350
                                    height: isQrCode ? 350 : 120
                                    fillMode: Image.PreserveAspectFit
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
                        fillMode: Image.PreserveAspectFit
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
                spacing: 10

                RowLayout {
                    spacing: 10
                    TextField {
                        id: filterTextField
                        placeholderText: "Фильтр по тексту"
                        Layout.fillWidth: true
                        implicitHeight: 40
                    }
                    TextField {
                        id: dateFilterField
                        placeholderText: "Фильтр по дате"
                        Layout.fillWidth: true
                        implicitHeight: 40
                    }
                    Button {
                        text: "Фильтровать"
                        Layout.minimumWidth: 100
                        Layout.preferredWidth: 120
                        implicitHeight: 40
                        contentItem: Text {
                            text: parent.text
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "white"
                        }
                        onClicked: loadHistory()
                    }
                }

                RowLayout {
                    spacing: 10
                    Button {
                        text: "Очистить фильтры"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 150
                        implicitHeight: 50
                        contentItem: Text {
                            text: parent.text
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "white"
                        }
                        onClicked: {
                            filterTextField.text = "";
                            dateFilterField.text = "";
                            loadHistory();
                        }
                    }
                    Button {
                        text: "Очистить историю"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 150
                        implicitHeight: 50
                        contentItem: Text {
                            text: parent.text
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "white"
                        }
                        onClicked: {
                            databaseManager.clearHistory();
                            loadHistory();
                        }
                    }
                    Button {
                        text: "Экспорт всей истории в PDF"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 180
                        implicitHeight: 50
                        contentItem: Text {
                            text: parent.text
                            wrapMode: Text.Wrap
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "white"
                        }
                        onClicked: {
                            busyIndicator.visible = true;
                            pdfExporter.exportAllQRCodes();
                        }
                    }
                }

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: historyModel }
                    delegate: Item {
                        width: historyList.width
                        implicitHeight: rowContent.implicitHeight + buttonRow.implicitHeight + 15

                        Column {
                            id: rowContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 5
                            spacing: 10

                            Row {
                                spacing: 10

                                Image {
                                    id: historyCodeImage
                                    width: 80
                                    height: model.code_type === "Barcode" ? 30 : 80
                                    source: model.imageSource
                                    fillMode: Image.PreserveAspectFit
                                    cache: false
                                    anchors.verticalCenter: textColumn.verticalCenter
                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            console.log("Ошибка загрузки изображения в истории:", source);
                                        }
                                    }
                                }

                                Column {
                                    id: textColumn
                                    width: parent.parent.width - historyCodeImage.width - 15
                                    spacing: 5
                                    Text { text: "Текст: " + model.text; wrapMode: Text.Wrap; color: palette.windowText }
                                    Text { text: "Тип: " + model.code_type; color: palette.windowText }
                                    Text { id: dateText; text: "Дата: " + model.created_at; color: palette.windowText }
                                }
                            }

                            Row {
                                id: buttonRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 10

                                Button {
                                    id: exportButton
                                    text: "Экспорт"
                                    implicitWidth: 80
                                    implicitHeight: 40
                                    contentItem: Text {
                                        text: parent.text
                                        wrapMode: Text.Wrap
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        color: "white"
                                    }
                                    onClicked: {
                                        busyIndicator.visible = true;
                                        var imageId = model.code_type.toLowerCase() + "_" + Qt.md5(model.text);
                                        pdfExporter.exportSingleQRCode(model.text, model.code_type, imageId);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: palette.mid
                            anchors.top: rowContent.bottom
                            anchors.topMargin: 5
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
        function onFileExported(filePath) {
            console.log("PDF экспортирован по пути:", filePath);
            busyIndicator.visible = false;
            errorText.text = "PDF успешно сохранён!";
            errorText.color = "green";
            errorText.visible = true;
        }
        function onErrorOccurred(error) {
            console.log("Ошибка выбора/экспорта файла:", error);
            busyIndicator.visible = false;
            errorText.text = error;
            errorText.color = "red";
            errorText.visible = true;
            codeImage.visible = false;
        }
    }

    Connections {
        target: pdfExporter
        function onPdfGenerated(filePath) {
            console.log("PDF сгенерирован, путь:", filePath);
            busyIndicator.visible = false;
            filePicker.exportFile(filePath);
        }
        function onErrorOccurred(error) {
            console.log("Ошибка экспорта PDF:", error);
            busyIndicator.visible = false;
            errorText.text = error;
            errorText.color = "red";
            errorText.visible = true;
        }
    }

    Component.onCompleted: loadHistory()
}

