# Campus Budget — C++ OOP Backend

This folder contains the **object-oriented C++ domain backend** and **HTTP API server**
for the Campus Budget app.

---

## Domain Classes

| Class | File | Responsibility |
|-------|------|---------------|
| `Expense` | `src/Expense.cpp` | Value object: date, category, note, amount |
| `BudgetManager` | `src/BudgetManager.cpp` | Add/update/delete expenses; totals; category breakdown |
| `LedgerEntry` | `src/LedgerEntry.cpp` | Value object: friend name and signed balance |
| `LedgerManager` | `src/LedgerManager.cpp` | Upsert/remove balances; net balance |
| `Piggybank` | `src/Piggybank.cpp` | Savings goal with deposit/withdraw and progress |
| `PiggybankManager` | `src/PiggybankManager.cpp` | CRUD for savings goals; delegate deposit/withdraw |
| `ReportGenerator` | `src/ReportGenerator.cpp` | Cross-manager text summary |

---

## HTTP API Server

The server (`server/main.cpp`) wraps the domain classes behind a REST API
using a custom lightweight Winsock2 HTTP server and
[nlohmann/json](https://github.com/nlohmann/json) — no other dependencies required.
Builds cleanly with MinGW GCC 6.3+.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check — `{"status":"ok"}` |
| `GET` | `/expenses` | List all expenses |
| `DELETE` | `/expenses` | Clear all expenses |
| `POST` | `/expenses` | Add expense — body: `{date, category, note, amount}` |
| `PUT` | `/expenses/:id` | Update expense by ID |
| `DELETE` | `/expenses/:id` | Delete expense by ID |
| `GET` | `/ledgers` | List all ledger entries |
| `DELETE` | `/ledgers` | Clear all ledger entries |
| `POST` | `/ledgers` | Upsert friend balance — body: `{friendName, amount}` |
| `DELETE` | `/ledgers/:name` | Remove ledger entry |
| `GET` | `/piggybanks` | List all savings goals |
| `DELETE` | `/piggybanks` | Clear all savings goals |
| `POST` | `/piggybanks` | Add goal — body: `{name, goalAmount, savedAmount, dueDate}` |
| `PUT` | `/piggybanks/:id` | Update savings goal |
| `DELETE` | `/piggybanks/:id` | Delete savings goal |
| `POST` | `/piggybanks/:id/deposit` | Deposit — body: `{amount}` |
| `POST` | `/piggybanks/:id/withdraw` | Withdraw — body: `{amount}` |
| `GET` | `/reports/summary` | Summary JSON + plain text |

---

## Build & Run

### Prerequisites

Download the nlohmann/json single-header (only needed once):

```powershell
Invoke-WebRequest https://github.com/nlohmann/json/releases/download/v3.10.5/json.hpp `
  -OutFile backend/server/json.hpp
```

### Build API Server with g++

```powershell
g++ -std=c++14 -I backend/include -I backend/server `
    backend/server/main.cpp backend/src/*.cpp `
    -o backend/campus_budget_server.exe -lws2_32 -lwininet

$env:GEMINI_API_KEY="YOUR_KEY_HERE"
.\backend\campus_budget_server.exe
```

### Build & Run Domain Tests with g++

```powershell
g++ -std=c++17 -I backend/include `
    backend/tests/backend_tests.cpp backend/src/*.cpp `
    -o backend/campus_budget_tests.exe

.\backend\campus_budget_tests.exe
```

### Build with CMake

```powershell
cmake -S backend -B backend/build
cmake --build backend/build

# Run tests
.\backend\build\campus_budget_tests.exe

# Run server
.\backend\build\campus_budget_server.exe
```

---

## Quick Test with PowerShell

```powershell
# Health check
Invoke-RestMethod http://localhost:8080/health

# List expenses
Invoke-RestMethod http://localhost:8080/expenses

# Clear expenses
Invoke-RestMethod http://localhost:8080/expenses -Method DELETE

# Add an expense
Invoke-RestMethod http://localhost:8080/expenses -Method POST `
  -ContentType "application/json" `
  -Body '{"date":"30 Jun","category":"Food","note":"Lunch","amount":120}'

# Get report summary
Invoke-RestMethod http://localhost:8080/reports/summary
```

---

## File Layout

```
backend/
├── include/campus/        ← Public header files
├── src/                   ← Class implementations
├── server/
│   ├── main.cpp           ← HTTP API server
│   └── json.hpp           ← nlohmann/json (gitignored, download above)
├── tests/
│   └── backend_tests.cpp  ← 4 assertion-based test suites
├── data/
│   └── budget_data.json   ← Runtime JSON persistence (gitignored)
└── CMakeLists.txt
```
