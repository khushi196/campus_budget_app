# C++ Backend Design

## Goal

Add a standalone C++ OOP backend module for the Campus Budget project so the app has a clear object-oriented core for expenses, ledgers, savings goals, and reports.

## Architecture

The backend lives in `backend/` and is independent from Flutter. It exposes focused C++ classes through headers in `backend/include/campus/` and implementations in `backend/src/`. The first version is a tested domain engine, not an HTTP server yet; that keeps the OOP project clean before connecting it to Flutter.

## Components

- `Expense`: value object for date, category, note, and amount.
- `BudgetManager`: owns expenses and supports add, update, delete, total spending, category spending, and category totals.
- `LedgerManager`: owns friend balances and computes net balance.
- `PiggybankManager`: owns savings goals and supports create, update, deposit, withdraw, delete.
- `ReportGenerator`: reads the managers and produces dashboard-style summary text.

## Data Flow

Flutter is not connected to this backend in this step. The C++ module is compiled and tested separately. Later, an API layer can wrap these classes and expose endpoints that Flutter calls.

## Testing

Use a simple C++ test executable with `assert` so it works without extra package downloads. CMake builds the test runner and registers it with CTest.
