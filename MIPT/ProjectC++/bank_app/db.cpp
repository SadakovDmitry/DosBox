#include "db.hpp"

std::string Database::generate_user_id() {
    std::string id;
    do {
        id = "USER_" + std::to_string(dis(gen));
    } while (used_user_ids.count(id) > 0);

    used_user_ids.insert(id);
    return id;
}

std::string Database::generate_account_id() {
    std::string id;
    do {
        id = "ACCOUNT_" + std::to_string(dis(gen));
    } while (used_account_ids.count(id) > 0);

    used_account_ids.insert(id);
    return id;
}

bool Database::addUser(const std::string& first_name,
            const std::string& last_name,
            const std::string& address,
            const std::string& passport) {

    for (const auto& [id, user] : users) {
        if (user.passport == passport) {
            return false;
        }
    }

    User new_user{
        generate_user_id(),
        first_name,
        last_name,
        address,
        passport,
        {}
    };

    users[new_user.id] = new_user;
    return true;
}

User* Database::getUserById(const std::string& id) {
    auto it = users.find(id);
    return it != users.end() ? &it->second : nullptr;
}

User* Database::getUserByPassport(const std::string& passport) {
    for (auto& [id, user] : users) {
        if (user.passport == passport) {
            return &user;
        }
    }
    return nullptr;
}

Account* Database::getAccountById(const std::string& account_id) {
    auto it = accounts.find(account_id);
    return it != accounts.end() ? &it->second : nullptr;
}

User* Database::getUsersByName(const std::string& first_name,
                 const std::string& last_name) {
    User* result;
    for (auto& [id, user] : users) {
        if (user.first_name == first_name && user.last_name == last_name) {
            result = &user;
            break;
        }
    }
    return result;
}

bool Database::addAccount(const std::string& user_id, AccountType type, double initial_balance) {
    if (!users.count(user_id)) return false;
    Account new_account{
        generate_account_id(),
        type,
        initial_balance,
        user_id
    };
    accounts[new_account.id] = new_account;
    users[user_id].accounts.push_back(new_account);
    return true;
}

bool Database::addAccountToUser(const std::string& passport,
                         const std::string& first_name,
                         const std::string& last_name,
                         const std::string& address,
                         AccountType type,
                         double initial_balance) {

        User* user = getUserByPassport(passport);

        // Если пользователь не существует - создаем нового
        if (!user) {
            if (!addUser(first_name, last_name, address, passport)) {
                // Если паспорт уже существует, но пользователь не найден - ошибка
                user = getUserByPassport(passport);
                if (!user) return false;
            } else {
                user = getUserByPassport(passport);
            }
        }

        return addAccount(user->id, type, initial_balance);
    }

void Database::saveToFile(const std::string& filename) {
    std::ofstream file(filename);
    for (const auto& [id, user] : users) {
        file << "USER|" << user.id << "|" << user.first_name << "|"
             << user.last_name << "|" << user.address << "|"
             << user.passport << "\n";
    }
    for (const auto& [id, account] : accounts) {
        file << "ACCOUNT|" << account.id << "|" << account.type << "|"
             << account.balance << "|" << account.owner_id << "\n";
    }
    file.close();
}

bool Database::loadFromFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) return false;
    std::string line;
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string type;
        std::getline(ss, type, '|');
        if (type == "USER") {
            User user;
            std::getline(ss, user.id, '|');
            std::getline(ss, user.first_name, '|');
            std::getline(ss, user.last_name, '|');
            std::getline(ss, user.address, '|');
            std::getline(ss, user.passport, '|');
            users[user.id] = user;
        }
        else if (type == "ACCOUNT") {
            Account account;
            std::string type_str;
            std::getline(ss, account.id, '|');
            std::getline(ss, type_str, '|');
            account.type = static_cast<AccountType>(std::stoi(type_str));
            std::string balance_str;
            std::getline(ss, balance_str, '|');
            account.balance = std::stod(balance_str);
            std::getline(ss, account.owner_id, '|');
            accounts[account.id] = account;
            users[account.owner_id].accounts.push_back(account);
        }
    }
    file.close();
    return true;
}
