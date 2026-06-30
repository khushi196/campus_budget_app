# C++ Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone C++ OOP backend module for Campus Budget with tested expense, ledger, piggybank, and report logic.

**Architecture:** The backend is a small CMake project under `backend/`. Headers expose domain classes in the `campus` namespace, source files implement behavior, and a single assert-based test executable verifies the OOP logic.

**Tech Stack:** C++17, CMake, CTest, standard library containers and algorithms.

---

### Task 1: Test Harness

**Files:**
- Create: `backend/CMakeLists.txt`
- Create: `backend/tests/backend_tests.cpp`

- [ ] **Step 1: Write the failing test**

Create tests that include the desired headers and exercise expense totals, category totals, ledgers, piggybanks, and report text.

- [ ] **Step 2: Run test to verify it fails**

Run: `cmake -S backend -B backend/build && cmake --build backend/build`
Expected: build fails because the C++ backend headers do not exist yet.

### Task 2: Domain Models

**Files:**
- Create: `backend/include/campus/Expense.hpp`
- Create: `backend/include/campus/LedgerEntry.hpp`
- Create: `backend/include/campus/Piggybank.hpp`
- Create: `backend/src/Expense.cpp`
- Create: `backend/src/Piggybank.cpp`

- [ ] **Step 1: Implement value objects**

Add small classes with constructor validation and getters for their fields.

- [ ] **Step 2: Run test**

Run: `cmake --build backend/build`
Expected: build moves past model includes and fails until managers exist.

### Task 3: Managers and Reports

**Files:**
- Create: `backend/include/campus/BudgetManager.hpp`
- Create: `backend/include/campus/LedgerManager.hpp`
- Create: `backend/include/campus/PiggybankManager.hpp`
- Create: `backend/include/campus/ReportGenerator.hpp`
- Create: `backend/src/BudgetManager.cpp`
- Create: `backend/src/LedgerManager.cpp`
- Create: `backend/src/PiggybankManager.cpp`
- Create: `backend/src/ReportGenerator.cpp`
- Modify: `backend/CMakeLists.txt`

- [ ] **Step 1: Implement managers**

Add collection-owning classes with add, update, delete, total, and summary methods.

- [ ] **Step 2: Run test**

Run: `ctest --test-dir backend/build --output-on-failure`
Expected: all backend tests pass.

### Task 4: Documentation and Regression Checks

**Files:**
- Create: `backend/README.md`

- [ ] **Step 1: Document build commands**

Add commands for configuring, building, and testing the backend.

- [ ] **Step 2: Run full verification**

Run backend tests and Flutter tests/analyzer to confirm the new backend did not break the app.
