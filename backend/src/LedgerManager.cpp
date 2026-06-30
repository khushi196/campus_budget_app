#include "campus/LedgerManager.hpp"

#include <algorithm>
#include <numeric>

namespace campus {

void LedgerManager::upsertBalance(const std::string& friendName, double amount) {
    const auto entry = std::find_if(
        entries_.begin(),
        entries_.end(),
        [&friendName](const LedgerEntry& item) {
            return item.friendName() == friendName;
        });

    if (entry == entries_.end()) {
        entries_.push_back(LedgerEntry(friendName, amount));
        return;
    }

    *entry = LedgerEntry(friendName, amount);
}

bool LedgerManager::removeBalance(const std::string& friendName) {
    const auto originalSize = entries_.size();
    entries_.erase(
        std::remove_if(
            entries_.begin(),
            entries_.end(),
            [&friendName](const LedgerEntry& item) {
                return item.friendName() == friendName;
            }),
        entries_.end());
    return entries_.size() != originalSize;
}

void LedgerManager::clearBalances() {
    entries_.clear();
}

double LedgerManager::balanceFor(const std::string& friendName) const {
    const auto entry = std::find_if(
        entries_.begin(),
        entries_.end(),
        [&friendName](const LedgerEntry& item) {
            return item.friendName() == friendName;
        });
    return entry == entries_.end() ? 0.0 : entry->amount();
}

double LedgerManager::netBalance() const {
    return std::accumulate(
        entries_.begin(),
        entries_.end(),
        0.0,
        [](double total, const LedgerEntry& entry) {
            return total + entry.amount();
        });
}

std::vector<LedgerEntry> LedgerManager::entries() const {
    return entries_;
}

}  // namespace campus
