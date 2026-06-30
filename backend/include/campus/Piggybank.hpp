#ifndef CAMPUS_PIGGYBANK_HPP
#define CAMPUS_PIGGYBANK_HPP

#include <string>

namespace campus {

class Piggybank {
public:
    Piggybank(std::string name, double goalAmount, double savedAmount, std::string dueDate);

    const std::string& name() const;
    double goalAmount() const;
    double savedAmount() const;
    const std::string& dueDate() const;
    double progress() const;

    void deposit(double amount);
    void withdraw(double amount);

private:
    std::string name_;
    double goalAmount_;
    double savedAmount_;
    std::string dueDate_;
};

}  // namespace campus

#endif
