#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    bool initialize();
    Q_INVOKABLE void addCode(const QString &text, const QString &type);
    Q_INVOKABLE QVariantList getAllCodes(const QString &textFilter = "", const QString &dateFilter = "");
    Q_INVOKABLE QVariantList getCodesByType(const QString &type);
    Q_INVOKABLE void clearHistory(); // Новый метод для очистки истории

private:
    void initializeDatabase();
    bool verifyTableStructure();
    bool migrateTable();

    QSqlDatabase m_database;
};

#endif // DATABASEMANAGER_H
