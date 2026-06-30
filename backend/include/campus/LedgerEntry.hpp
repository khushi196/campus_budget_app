#ifndef CAMPUS_LEDGER_ENTRY_HPP
#define CAMPUS_LEDGER_ENTRY_HPP

#include <string>

namespace campus {

class LedgerEntry {
public:
    LedgerEntry(std::string friendName, double amount);

    const std::string& friendName() const;
    double amount() const;
    bool theyOweYou() const;

private:
    std::string friendName_;
    double amount_;
};

}  // namespace campus

#endif
