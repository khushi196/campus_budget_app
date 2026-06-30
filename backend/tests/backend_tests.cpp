#include <cassert>
#include <cmath>
#include <string>

#include "campus/BudgetManager.hpp"
#include "campus/Expense.hpp"
#include "campus/LedgerManager.hpp"
#include "campus/PiggybankManager.hpp"
#include "campus/ReportGenerator.hpp"

namespace {

bool closeTo(double actual, double expected) {
    return std::fabs(actual - expected) < 0.001;
}

void testBudgetManagerTracksExpenses() {
    campus::BudgetManager manager;

    const int lunchId = manager.addExpense(
        campus::Expense("30 Jun", "Food", "Lunch near campus", 120.0));
    manager.addExpense(campus::Expense("30 Jun", "Stationery", "Notebook set", 85.0));
    manager.updateExpense(
        lunchId,
        campus::Expense("30 Jun", "Food", "Lunch and juice", 150.0));

    assert(closeTo(manager.totalSpent(), 235.0));
    assert(closeTo(manager.categoryTotal("Food"), 150.0));
    assert(closeTo(manager.categoryTotal("Stationery"), 85.0));
    assert(manager.expenses().size() == 2);
    assert(manager.expenseRecords().size() == 2);
    assert(manager.expenseRecords()[0].id == lunchId);

    manager.deleteExpense(lunchId);

    assert(closeTo(manager.totalSpent(), 85.0));
    assert(closeTo(manager.categoryTotal("Food"), 0.0));

    manager.clearExpenses();

    assert(manager.expenses().empty());
    assert(closeTo(manager.totalSpent(), 0.0));
}

void testLedgerManagerTracksFriendBalances() {
    campus::LedgerManager manager;

    manager.upsertBalance("Khushi", 60.0);
    manager.upsertBalance("Aman", -120.0);
    manager.upsertBalance("Riya", 240.0);
    manager.upsertBalance("Aman", -50.0);

    assert(closeTo(manager.netBalance(), 250.0));
    assert(closeTo(manager.balanceFor("Aman"), -50.0));

    manager.removeBalance("Khushi");

    assert(closeTo(manager.netBalance(), 190.0));
    assert(manager.entries().size() == 2);

    manager.clearBalances();

    assert(manager.entries().empty());
    assert(closeTo(manager.netBalance(), 0.0));
}

void testPiggybankManagerTracksGoals() {
    campus::PiggybankManager manager;

    const int laptopId = manager.addGoal(
        campus::Piggybank("Laptop Fund", 60000.0, 5000.0, "20 Aug"));
    manager.deposit(laptopId, 2000.0);
    manager.withdraw(laptopId, 1000.0);

    const campus::Piggybank* laptop = manager.findGoal(laptopId);
    assert(laptop != nullptr);
    assert(manager.goalRecords().size() == 1);
    assert(manager.goalRecords()[0].id == laptopId);
    assert(closeTo(laptop->savedAmount(), 6000.0));
    assert(closeTo(laptop->progress(), 0.1));

    manager.updateGoal(
        laptopId,
        campus::Piggybank("Laptop Fund", 65000.0, 6000.0, "25 Aug"));

    laptop = manager.findGoal(laptopId);
    assert(laptop != nullptr);
    assert(closeTo(laptop->goalAmount(), 65000.0));
    assert(laptop->dueDate() == "25 Aug");

    manager.deleteGoal(laptopId);
    assert(manager.findGoal(laptopId) == nullptr);

    manager.addGoal(campus::Piggybank("Trip Fund", 5000.0, 2100.0, "05 Aug"));
    manager.clearGoals();

    assert(manager.goals().empty());
}

void testReportGeneratorSummarizesManagers() {
    campus::BudgetManager budget;
    campus::LedgerManager ledgers;
    campus::PiggybankManager piggybanks;

    budget.addExpense(campus::Expense("30 Jun", "Food", "Lunch", 120.0));
    budget.addExpense(campus::Expense("30 Jun", "Stationery", "Notebook", 80.0));
    ledgers.upsertBalance("Riya", 240.0);
    piggybanks.addGoal(campus::Piggybank("Trip Fund", 5000.0, 2100.0, "05 Aug"));

    campus::ReportGenerator reportGenerator;
    const std::string summary =
        reportGenerator.dashboardSummary(budget, ledgers, piggybanks);

    assert(summary.find("Total spent: 200") != std::string::npos);
    assert(summary.find("Top category: Food") != std::string::npos);
    assert(summary.find("Net ledger: 240") != std::string::npos);
    assert(summary.find("Savings goals: 1") != std::string::npos);
}

}  // namespace

int main() {
    testBudgetManagerTracksExpenses();
    testLedgerManagerTracksFriendBalances();
    testPiggybankManagerTracksGoals();
    testReportGeneratorSummarizesManagers();
    return 0;
}
