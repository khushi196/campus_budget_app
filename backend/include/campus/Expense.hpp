#ifndef CAMPUS_EXPENSE_HPP
#define CAMPUS_EXPENSE_HPP

#include <string>

namespace campus {

class Expense {
public:
    Expense(std::string date, std::string category, std::string note, double amount);

    const std::string& date() const;
    const std::string& category() const;
    const std::string& note() const;
    double amount() const;

private:
    std::string date_;
    std::string category_;
    std::string note_;
    double amount_;
};

}  // namespace campus

#endif
