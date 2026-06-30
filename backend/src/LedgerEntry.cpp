#include "campus/LedgerEntry.hpp"

#include <stdexcept>
#include <utility>

namespace campus {

LedgerEntry::LedgerEntry(std::string friendName, double amount)
    : friendName_(std::move(friendName)), amount_(amount) {
    if (friendName_.empty()) {
        throw std::invalid_argument("Friend name cannot be empty");
    }
}

const std::string& LedgerEntry::friendName() const {
    return friendName_;
}

double LedgerEntry::amount() const {
    return amount_;
}

bool LedgerEntry::theyOweYou() const {
    return amount_ >= 0;
}

}  // namespace campus
