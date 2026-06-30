# Campus Budget C++ Backend

This folder contains the object-oriented C++ domain backend for the Campus Budget app.

## What It Contains

- `Expense`: spending entry value object.
- `BudgetManager`: add, edit, delete, total, and category spending logic.
- `LedgerManager`: friend balance and net ledger logic.
- `PiggybankManager`: savings goal, deposit, withdraw, and delete logic.
- `ReportGenerator`: dashboard summary text built from the managers.

## Build With g++

```powershell
g++ -std=c++17 -I backend/include backend/tests/backend_tests.cpp backend/src/*.cpp -o backend/campus_budget_tests.exe
.\backend\campus_budget_tests.exe
```

## Build With CMake

If CMake is installed:

```powershell
cmake -S backend -B backend/build
cmake --build backend/build
ctest --test-dir backend/build --output-on-failure
```

## Next Step

Wrap these classes with a small HTTP API so the Flutter frontend can call the C++ OOP backend.
