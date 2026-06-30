#ifndef CAMPUS_REPORT_GENERATOR_HPP
#define CAMPUS_REPORT_GENERATOR_HPP

#include <string>

#include "campus/BudgetManager.hpp"
#include "campus/LedgerManager.hpp"
#include "campus/PiggybankManager.hpp"

namespace campus {

class ReportGenerator {
public:
    std::string dashboardSummary(
        const BudgetManager& budget,
        const LedgerManager& ledgers,
        const PiggybankManager& piggybanks) const;
};

}  // namespace campus

#endif
