#include "db.hpp"

int main(int argc, char* argv[]) {
    Database db;
    db.loadFromFile("database.txt");

    if (argc < 2) {
        std::cerr << "Недостаточно аргументов\n";
        return 1;
    }

    std::string command = argv[1];

    try {
        if (command == "create_user") {
            db.addUser(argv[2], argv[3], argv[4], argv[5]);
            std::cout << "Пользователь создан\n";
        }
        else if (command == "create_account") {
            AccountType type = static_cast<AccountType>(std::stoi(argv[3]));
            db.addAccountToUser(argv[2], "", "", "", type, std::stod(argv[4]));
            std::cout << "Счёт создан\n";
        }
        else if (command == "transfer") {
            // TODO: переводы
        }
        else if (command == "check_user") {
            User* user = db.getUserByPassport(argv[2]);
            std::cout << (user ? "Пользователь найден" : "Пользователь не найден") << "\n";
        }
        else if (command == "find_user") {
            auto user = db.getUsersByName(argv[2], argv[3]);
                std::cout << "USER|" << user->id << "|" << user->first_name
                          << "|" << user->last_name << "\n";
                for (auto& acc : user->accounts) {
                    std::cout << "ACCOUNT|" << acc.id << "|" << acc.type
                              << "|" << acc.balance << "\n";
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Ошибка: " << e.what() << "\n";
        return 1;
    }

    db.saveToFile("database.txt");
    return 0;
}
