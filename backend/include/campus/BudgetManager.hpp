#ifndef CAMPUS_BUDGET_MANAGER_HPP
#define CAMPUS_BUDGET_MANAGER_HPP

#include <map>
#include <string>
#include <vector>

#include "campus/Expense.hpp"

namespace campus {

class BudgetManager {
public:
    int addExpense(const Expense& expense);
    bool updateExpense(int id, const Expense& expense);
    bool deleteExpense(int id);

    std::vector<Expense> expenses() const;
    double totalSpent() const;
    double categoryTotal(const std::string& category) const;
    std::map<std::string, double> categoryTotals() const;
    std::string topCategory() const;

private:
    struct ExpenseRecord {
        int id;
        Expense expense;
    };

    int nextId_ = 1;
    std::vector<ExpenseRecord> expenses_;
};

}  // namespace campus

#endif
