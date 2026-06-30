cmake_minimum_required(VERSION 3.16)
project(campus_budget_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(campus_budget_tests
    src/BudgetManager.cpp
    src/Expense.cpp
    src/LedgerEntry.cpp
    src/LedgerManager.cpp
    src/Piggybank.cpp
    src/PiggybankManager.cpp
    src/ReportGenerator.cpp
    tests/backend_tests.cpp
)

target_include_directories(campus_budget_tests PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

enable_testing()
add_test(NAME campus_budget_tests COMMAND campus_budget_tests)
