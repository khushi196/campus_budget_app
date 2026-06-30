#ifndef CAMPUS_PIGGYBANK_MANAGER_HPP
#define CAMPUS_PIGGYBANK_MANAGER_HPP

#include <vector>

#include "campus/Piggybank.hpp"

namespace campus {

class PiggybankManager {
public:
    int addGoal(const Piggybank& piggybank);
    bool updateGoal(int id, const Piggybank& piggybank);
    bool deleteGoal(int id);
    bool deposit(int id, double amount);
    bool withdraw(int id, double amount);

    const Piggybank* findGoal(int id) const;
    std::vector<Piggybank> goals() const;

private:
    struct GoalRecord {
        int id;
        Piggybank piggybank;
    };

    GoalRecord* findRecord(int id);

    int nextId_ = 1;
    std::vector<GoalRecord> goals_;
};

}  // namespace campus

#endif
