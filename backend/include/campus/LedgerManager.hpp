#ifndef CAMPUS_LEDGER_MANAGER_HPP
#define CAMPUS_LEDGER_MANAGER_HPP

#include <string>
#include <vector>

#include "campus/LedgerEntry.hpp"

namespace campus {

class LedgerManager {
public:
    void upsertBalance(const std::string& friendName, double amount);
    bool removeBalance(const std::string& friendName);

    double balanceFor(const std::string& friendName) const;
    double netBalance() const;
    std::vector<LedgerEntry> entries() const;

private:
    std::vector<LedgerEntry> entries_;
};

}  // namespace campus

#endif
