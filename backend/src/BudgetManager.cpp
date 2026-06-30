#include "campus/BudgetManager.hpp"

#include <algorithm>
#include <numeric>

namespace campus {

int BudgetManager::addExpense(const Expense& expense) {
    const int id = nextId_++;
    expenses_.push_back({id, expense});
    return id;
}

bool BudgetManager::updateExpense(int id, const Expense& expense) {
    const auto record = std::find_if(
        expenses_.begin(),
        expenses_.end(),
        [id](const ExpenseRecord& item) { return item.id == id; });
    if (record == expenses_.end()) {
        return false;
    }

    record->expense = expense;
    return true;
}

bool BudgetManager::deleteExpense(int id) {
    const auto originalSize = expenses_.size();
    expenses_.erase(
        std::remove_if(
            expenses_.begin(),
            expenses_.end(),
            [id](const ExpenseRecord& item) { return item.id == id; }),
        expenses_.end());
    return expenses_.size() != originalSize;
}

std::vector<Expense> BudgetManager::expenses() const {
    std::vector<Expense> result;
    result.reserve(expenses_.size());
    for (const ExpenseRecord& record : expenses_) {
        result.push_back(record.expense);
    }
    return result;
}

double BudgetManager::totalSpent() const {
    return std::accumulate(
        expenses_.begin(),
        expenses_.end(),
        0.0,
        [](double total, const ExpenseRecord& record) {
            return total + record.expense.amount();
        });
}

double BudgetManager::categoryTotal(const std::string& category) const {
    double total = 0.0;
    for (const ExpenseRecord& record : expenses_) {
        if (record.expense.category() == category) {
            total += record.expense.amount();
        }
    }
    return total;
}

std::map<std::string, double> BudgetManager::categoryTotals() const {
    std::map<std::string, double> totals;
    for (const ExpenseRecord& record : expenses_) {
        totals[record.expense.category()] += record.expense.amount();
    }
    return totals;
}

std::string BudgetManager::topCategory() const {
    const auto totals = categoryTotals();
    if (totals.empty()) {
        return "None";
    }

    const auto top = std::max_element(
        totals.begin(),
        totals.end(),
        [](const auto& left, const auto& right) {
            return left.second < right.second;
        });
    return top->first;
}

}  // namespace campus
