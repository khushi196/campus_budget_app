#include "campus/Expense.hpp"

#include <stdexcept>
#include <utility>

namespace campus {

Expense::Expense(std::string date, std::string category, std::string note, double amount)
    : date_(std::move(date)),
      category_(std::move(category)),
      note_(std::move(note)),
      amount_(amount) {
    if (date_.empty() || category_.empty() || note_.empty()) {
        throw std::invalid_argument("Expense fields cannot be empty");
    }
    if (amount_ < 0) {
        throw std::invalid_argument("Expense amount cannot be negative");
    }
}

const std::string& Expense::date() const {
    return date_;
}

const std::string& Expense::category() const {
    return category_;
}

const std::string& Expense::note() const {
    return note_;
}

double Expense::amount() const {
    return amount_;
}

}  // namespace campus
