#include "campus/PiggybankManager.hpp"

#include <algorithm>

namespace campus {

int PiggybankManager::addGoal(const Piggybank& piggybank) {
    const int id = nextId_++;
    goals_.push_back({id, piggybank});
    return id;
}

bool PiggybankManager::updateGoal(int id, const Piggybank& piggybank) {
    GoalRecord* record = findRecord(id);
    if (record == nullptr) {
        return false;
    }

    record->piggybank = piggybank;
    return true;
}

bool PiggybankManager::deleteGoal(int id) {
    const auto originalSize = goals_.size();
    goals_.erase(
        std::remove_if(
            goals_.begin(),
            goals_.end(),
            [id](const GoalRecord& item) { return item.id == id; }),
        goals_.end());
    return goals_.size() != originalSize;
}

bool PiggybankManager::deposit(int id, double amount) {
    GoalRecord* record = findRecord(id);
    if (record == nullptr) {
        return false;
    }

    record->piggybank.deposit(amount);
    return true;
}

bool PiggybankManager::withdraw(int id, double amount) {
    GoalRecord* record = findRecord(id);
    if (record == nullptr) {
        return false;
    }

    record->piggybank.withdraw(amount);
    return true;
}

const Piggybank* PiggybankManager::findGoal(int id) const {
    const auto record = std::find_if(
        goals_.begin(),
        goals_.end(),
        [id](const GoalRecord& item) { return item.id == id; });
    return record == goals_.end() ? nullptr : &record->piggybank;
}

std::vector<Piggybank> PiggybankManager::goals() const {
    std::vector<Piggybank> result;
    result.reserve(goals_.size());
    for (const GoalRecord& record : goals_) {
        result.push_back(record.piggybank);
    }
    return result;
}

PiggybankManager::GoalRecord* PiggybankManager::findRecord(int id) {
    const auto record = std::find_if(
        goals_.begin(),
        goals_.end(),
        [id](const GoalRecord& item) { return item.id == id; });
    return record == goals_.end() ? nullptr : &(*record);
}

}  // namespace campus
