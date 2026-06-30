#include "campus/Piggybank.hpp"

#include <algorithm>
#include <stdexcept>
#include <utility>

namespace campus {

Piggybank::Piggybank(
    std::string name,
    double goalAmount,
    double savedAmount,
    std::string dueDate)
    : name_(std::move(name)),
      goalAmount_(goalAmount),
      savedAmount_(savedAmount),
      dueDate_(std::move(dueDate)) {
    if (name_.empty() || dueDate_.empty()) {
        throw std::invalid_argument("Piggybank name and due date cannot be empty");
    }
    if (goalAmount_ <= 0 || savedAmount_ < 0) {
        throw std::invalid_argument("Piggybank amounts are invalid");
    }
}

const std::string& Piggybank::name() const {
    return name_;
}

double Piggybank::goalAmount() const {
    return goalAmount_;
}

double Piggybank::savedAmount() const {
    return savedAmount_;
}

const std::string& Piggybank::dueDate() const {
    return dueDate_;
}

double Piggybank::progress() const {
    return std::min(savedAmount_ / goalAmount_, 1.0);
}

void Piggybank::deposit(double amount) {
    if (amount <= 0) {
        throw std::invalid_argument("Deposit amount must be positive");
    }
    savedAmount_ += amount;
}

void Piggybank::withdraw(double amount) {
    if (amount <= 0) {
        throw std::invalid_argument("Withdraw amount must be positive");
    }
    savedAmount_ = std::max(0.0, savedAmount_ - amount);
}

}  // namespace campus
