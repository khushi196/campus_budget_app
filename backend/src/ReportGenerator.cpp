#include "campus/ReportGenerator.hpp"

#include <sstream>

namespace campus {

std::string ReportGenerator::dashboardSummary(
    const BudgetManager& budget,
    const LedgerManager& ledgers,
    const PiggybankManager& piggybanks) const {
    std::ostringstream output;
    output << "Total spent: " << budget.totalSpent()
           << " | Top category: " << budget.topCategory()
           << " | Net ledger: " << ledgers.netBalance()
           << " | Savings goals: " << piggybanks.goals().size();
    return output.str();
}

}  // namespace campus
