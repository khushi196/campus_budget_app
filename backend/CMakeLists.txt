cmake_minimum_required(VERSION 3.16)
project(campus_budget_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ── Domain sources shared by both targets ───────────────────────────────────
set(DOMAIN_SOURCES
    src/BudgetManager.cpp
    src/Expense.cpp
    src/LedgerEntry.cpp
    src/LedgerManager.cpp
    src/Piggybank.cpp
    src/PiggybankManager.cpp
    src/ReportGenerator.cpp
)

# ── 1. Unit-test executable ──────────────────────────────────────────────────
add_executable(campus_budget_tests
    ${DOMAIN_SOURCES}
    tests/backend_tests.cpp
)

target_include_directories(campus_budget_tests PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

enable_testing()
add_test(NAME campus_budget_tests COMMAND campus_budget_tests)

# ── 2. HTTP API server executable ────────────────────────────────────────────
add_executable(campus_budget_server
    ${DOMAIN_SOURCES}
    server/main.cpp
)

target_include_directories(campus_budget_server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/server   # json.hpp
)

# Keep threading support available for future non-Windows server builds.
find_package(Threads REQUIRED)
target_link_libraries(campus_budget_server PRIVATE Threads::Threads)

# On Windows with MSVC, enable WIN32 socket support
if(WIN32)
    target_link_libraries(campus_budget_server PRIVATE ws2_32 wininet)
endif()
