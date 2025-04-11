#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <algorithm>
#include <unordered_map>
#include <random>
#include <unordered_set>

enum AccountType { DEBIT, CREDIT, SAVINGS };

struct Account {
    std::string id;
    AccountType type;
    double balance;
    std::string owner_id;
};

struct User {
    std::string id;
    std::string first_name;
    std::string last_name;
    std::string address;
    std::string passport;
    std::vector<Account> accounts;
};

class Database {
private:
    std::unordered_map<std::string, User> users;
    std::unordered_map<std::string, Account> accounts;
    std::unordered_set<std::string> used_user_ids;
    std::unordered_set<std::string> used_account_ids;

    std::random_device rd;
    std::mt19937 gen;
    std::uniform_int_distribution<> dis;

    std::string generate_user_id();
    std::string generate_account_id();

public:
    Database() : gen(rd()), dis(1000, 9999) {}

    bool addUser(const std::string& first_name,
                const std::string& last_name,
                const std::string& address,
                const std::string& passport);

    User* getUserById(const std::string& id);
    User* getUserByPassport(const std::string& passport);
    User* getUsersByName(const std::string& first_name,
                         const std::string& last_name);

    Account* getAccountById(const std::string& account_id);
    bool addAccount(const std::string& user_id, AccountType type, double initial_balance);
    bool addAccountToUser(const std::string& passport,
                         const std::string& first_name,
                         const std::string& last_name,
                         const std::string& address,
                         AccountType type,
                         double initial_balance = 0);

    void saveToFile(const std::string& filename);
    bool loadFromFile(const std::string& filename);
};
