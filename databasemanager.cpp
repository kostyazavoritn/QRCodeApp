#include "databasemanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QStandardPaths>
#include <QDir>

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
}

bool DatabaseManager::initialize()
{
    initializeDatabase();
    if (!m_database.isOpen()) {
        qDebug() << "Не удалось открыть базу данных:" << m_database.lastError().text();
        return false;
    }
    return true;
}

void DatabaseManager::initializeDatabase()
{
    m_database = QSqlDatabase::addDatabase("QSQLITE");
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(appDataPath);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qDebug() << "Ошибка: не удалось создать директорию" << appDataPath;
        }
    }
    QString dbPath = appDataPath + "/qrcodes.db";
    m_database.setDatabaseName(dbPath);
    qDebug() << "Путь к базе данных:" << dbPath;

    if (!m_database.open()) {
        qDebug() << "Ошибка открытия базы данных:" << m_database.lastError().text();
        return;
    }

    // Создаём таблицу codes, если она не существует
    QSqlQuery query(m_database);
    bool success = query.exec("CREATE TABLE IF NOT EXISTS codes ("
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                              "text TEXT, "
                              "type TEXT, "
                              "created_at TEXT)");
    if (!success) {
        qDebug() << "Ошибка создания таблицы codes:" << query.lastError().text();
        m_database.close();
        return;
    }
    qDebug() << "Таблица codes успешно создана или уже существует";
}

bool DatabaseManager::verifyTableStructure()
{
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта при проверке структуры";
        return false;
    }

    QSqlQuery query(m_database);
    bool success = query.exec("PRAGMA table_info(codes)");
    if (!success) {
        qDebug() << "Ошибка проверки структуры таблицы:" << query.lastError().text();
        return false;
    }

    bool hasText = false, hasType = false, hasCreatedAt = false;
    while (query.next()) {
        QString columnName = query.value("name").toString();
        if (columnName == "text") hasText = true;
        if (columnName == "type") hasType = true;
        if (columnName == "created_at") hasCreatedAt = true;
    }

    if (!hasText || !hasType || !hasCreatedAt) {
        qDebug() << "Ошибка: таблица codes имеет некорректную структуру";
        qDebug() << "text:" << hasText << ", type:" << hasType << ", created_at:" << hasCreatedAt;
        return false;
    }

    qDebug() << "Структура таблицы codes корректна";
    return true;
}

bool DatabaseManager::migrateTable()
{
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта при миграции";
        return false;
    }

    QSqlQuery query(m_database);
    // Переименовываем старую таблицу
    bool success = query.exec("ALTER TABLE codes RENAME TO codes_old");
    if (!success) {
        qDebug() << "Ошибка переименования таблицы codes:" << query.lastError().text();
        return false;
    }

    // Создаём новую таблицу с правильной структурой
    success = query.exec("CREATE TABLE codes (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, type TEXT, created_at TEXT)");
    if (!success) {
        qDebug() << "Ошибка создания новой таблицы codes:" << query.lastError().text();
        return false;
    }

    // Копируем данные из старой таблицы (если они совместимы)
    success = query.exec("INSERT INTO codes (text, created_at) SELECT text, created_at FROM codes_old");
    if (!success) {
        qDebug() << "Ошибка копирования данных:" << query.lastError().text();
        // Продолжаем, так как отсутствие данных не критично
    }

    // Удаляем старую таблицу
    success = query.exec("DROP TABLE codes_old");
    if (!success) {
        qDebug() << "Ошибка удаления старой таблицы:" << query.lastError().text();
        return false;
    }

    qDebug() << "Миграция таблицы codes успешно завершена";
    return true;
}

void DatabaseManager::addCode(const QString &text, const QString &type)
{
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта";
        return;
    }

    QSqlQuery query(m_database);
    query.prepare("INSERT INTO codes (text, type, created_at) VALUES (?, ?, ?)");
    query.addBindValue(text);
    query.addBindValue(type);
    query.addBindValue(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"));

    qDebug() << "Попытка сохранить код: text =" << text << ", type =" << type;
    if (!query.exec()) {
        qDebug() << "Ошибка сохранения кода:" << query.lastError().text();
        qDebug() << "SQL запрос:" << query.lastQuery();
        qDebug() << "Привязанные значения:" << query.boundValues();
    } else {
        qDebug() << "Код успешно сохранён в базе данных";
    }
}

QVariantList DatabaseManager::getAllCodes(const QString &textFilter, const QString &dateFilter)
{
    QVariantList codes;
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта при получении кодов";
        return codes;
    }

    QString queryStr = "SELECT text, type, created_at FROM codes";
    QStringList conditions;

    if (!textFilter.isEmpty()) {
        conditions << "text LIKE '%" + textFilter + "%'";
    }
    if (!dateFilter.isEmpty()) {
        conditions << "created_at LIKE '%" + dateFilter + "%'";
    }

    if (!conditions.isEmpty()) {
        queryStr += " WHERE " + conditions.join(" AND ");
    }

    queryStr += " ORDER BY created_at DESC";

    QSqlQuery query(m_database);
    if (!query.exec(queryStr)) {
        qDebug() << "Ошибка выполнения запроса getAllCodes:" << query.lastError().text();
        qDebug() << "SQL запрос:" << queryStr;
        return codes;
    }

    while (query.next()) {
        QVariantMap code;
        code["text"] = query.value("text").toString();
        code["code_type"] = query.value("type").toString();
        code["created_at"] = query.value("created_at").toString();
        codes.append(code);
    }

    qDebug() << "Получено кодов из базы данных:" << codes.size();
    return codes;
}

QVariantList DatabaseManager::getCodesByType(const QString &type)
{
    QVariantList codes;
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта при получении кодов по типу";
        return codes;
    }

    QSqlQuery query(m_database);
    query.prepare("SELECT text, type, created_at FROM codes WHERE type = ?");
    query.addBindValue(type);
    if (!query.exec()) {
        qDebug() << "Ошибка получения кодов:" << query.lastError().text();
        return codes;
    }

    while (query.next()) {
        QVariantMap code;
        code["text"] = query.value("text").toString();
        code["code_type"] = query.value("type").toString();
        code["created_at"] = query.value("created_at").toString();
        codes.append(code);
    }
    qDebug() << "Получено кодов типа" << type << ":" << codes.size();
    return codes;
}

void DatabaseManager::clearHistory()
{
    if (!m_database.isOpen()) {
        qDebug() << "Ошибка: база данных не открыта при очистке истории";
        return;
    }

    QSqlQuery query(m_database);
    bool success = query.exec("DELETE FROM codes");
    if (!success) {
        qDebug() << "Ошибка очистки истории:" << query.lastError().text();
        return;
    }

    qDebug() << "История успешно очищена";
}
