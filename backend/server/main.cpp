/**
 * Campus Budget C++ HTTP API Server
 *
 * Lightweight single-threaded HTTP/1.1 server using Winsock2 only.
 * No third-party headers required — works with MinGW GCC 6.3+.
 *
 * Wraps the OOP domain layer:
 *   - BudgetManager    -> /expenses
 *   - LedgerManager    -> /ledgers
 *   - PiggybankManager -> /piggybanks
 *   - ReportGenerator  -> /reports/summary
 *
 * Persistence: data/budget_data.json (JSON via nlohmann/json)
 * AI proxy: POST /ai/gemini forwards to Gemini using GEMINI_API_KEY env var
 *
 * Build (from project root):
 *   g++ -std=c++14 -I backend/include -I backend/server
 *       backend/server/main.cpp backend/src/*.cpp
 *       -o backend/campus_budget_server.exe -lws2_32 -lwininet
 *
 * Run (from project root):
 *   .\backend\campus_budget_server.exe
 *
 * API listens on http://localhost:8080
 */

#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <wininet.h>
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "wininet.lib")

#include "json.hpp"

#include "campus/BudgetManager.hpp"
#include "campus/LedgerManager.hpp"
#include "campus/PiggybankManager.hpp"
#include "campus/ReportGenerator.hpp"

#include <direct.h>
#include <io.h>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using json = nlohmann::json;

// ---------------------------------------------------------------------------
// Global state
// ---------------------------------------------------------------------------

campus::BudgetManager    gBudget;
campus::LedgerManager    gLedgers;
campus::PiggybankManager gPiggybanks;

static const std::string kDataPath = "backend/data/budget_data.json";

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

void saveData() {
    json root;

    json expenses = json::array();
    for (const auto& e : gBudget.expenses()) {
        expenses.push_back({
            {"date",     e.date()},
            {"category", e.category()},
            {"note",     e.note()},
            {"amount",   e.amount()}
        });
    }
    root["expenses"] = expenses;

    json ledgers = json::array();
    for (const auto& l : gLedgers.entries()) {
        ledgers.push_back({
            {"friendName", l.friendName()},
            {"amount",     l.amount()}
        });
    }
    root["ledgers"] = ledgers;

    json piggybanks = json::array();
    for (const auto& p : gPiggybanks.goals()) {
        piggybanks.push_back({
            {"name",        p.name()},
            {"goalAmount",  p.goalAmount()},
            {"savedAmount", p.savedAmount()},
            {"dueDate",     p.dueDate()}
        });
    }
    root["piggybanks"] = piggybanks;

    _mkdir("backend");
    _mkdir("backend/data");
    std::ofstream out(kDataPath);
    out << root.dump(2);
}

void loadData() {
    if (_access(kDataPath.c_str(), 0) != 0) {
        std::cout << "[info] No data file found, starting fresh.\n";
        return;
    }
    std::ifstream in(kDataPath);
    if (!in.is_open()) {
        std::cerr << "[warn] Could not open " << kDataPath << "\n";
        return;
    }
    json root;
    try {
        in >> root;
    } catch (const std::exception& ex) {
        std::cerr << "[warn] JSON parse error: " << ex.what() << "\n";
        return;
    }

    if (root.count("expenses") && root["expenses"].is_array()) {
        for (const auto& e : root["expenses"]) {
            gBudget.addExpense(campus::Expense(
                e.value("date", ""),
                e.value("category", ""),
                e.value("note", ""),
                e.value("amount", 0.0)));
        }
    }
    if (root.count("ledgers") && root["ledgers"].is_array()) {
        for (const auto& l : root["ledgers"]) {
            gLedgers.upsertBalance(l.value("friendName", ""), l.value("amount", 0.0));
        }
    }
    if (root.count("piggybanks") && root["piggybanks"].is_array()) {
        for (const auto& p : root["piggybanks"]) {
            gPiggybanks.addGoal(campus::Piggybank(
                p.value("name", ""),
                p.value("goalAmount", 0.0),
                p.value("savedAmount", 0.0),
                p.value("dueDate", "")));
        }
    }
    std::cout << "[info] Loaded data from " << kDataPath << "\n";
}

// ---------------------------------------------------------------------------
// Minimal HTTP request / response
// ---------------------------------------------------------------------------

struct HttpRequest {
    std::string method;
    std::string path;
    std::string body;
    std::map<std::string, std::string> params; // parsed from path template
};

struct HttpResponse {
    int status = 200;
    std::string body;
    std::string contentType = "application/json";
};

// Extract a path parameter from a path with a template.
// e.g. matchPath("/expenses/42", "/expenses/:id") -> params["id"] = "42"
bool matchPath(const std::string& actual, const std::string& tmpl,
               std::map<std::string, std::string>& out) {
    std::vector<std::string> aParts, tParts;
    auto split = [](const std::string& s) {
        std::vector<std::string> parts;
        std::istringstream ss(s);
        std::string token;
        while (std::getline(ss, token, '/')) {
            if (!token.empty()) parts.push_back(token);
        }
        return parts;
    };
    aParts = split(actual);
    tParts = split(tmpl);
    if (aParts.size() != tParts.size()) return false;
    for (size_t i = 0; i < tParts.size(); ++i) {
        if (tParts[i][0] == ':') {
            out[tParts[i].substr(1)] = aParts[i];
        } else if (tParts[i] != aParts[i]) {
            return false;
        }
    }
    return true;
}

// ---------------------------------------------------------------------------
// Route handlers
// ---------------------------------------------------------------------------

// Convenience: build a JSON error response
HttpResponse jsonError(int code, const std::string& msg) {
    HttpResponse res;
    res.status = code;
    res.body = json{{"error", msg}}.dump();
    return res;
}

HttpResponse jsonOk(const json& body) {
    HttpResponse res;
    res.body = body.dump();
    return res;
}

std::wstring widen(const std::string& value) {
    return std::wstring(value.begin(), value.end());
}

bool isSafeModelName(const std::string& model) {
    if (model.empty()) return false;
    for (char ch : model) {
        const bool ok =
            (ch >= 'a' && ch <= 'z') ||
            (ch >= 'A' && ch <= 'Z') ||
            (ch >= '0' && ch <= '9') ||
            ch == '.' || ch == '-' || ch == '_';
        if (!ok) return false;
    }
    return true;
}

HttpResponse postToGemini(const std::string& model, const std::string& body) {
    const char* apiKey = std::getenv("GEMINI_API_KEY");
    if (apiKey == nullptr || std::string(apiKey).empty()) {
        return jsonError(
            500,
            "GEMINI_API_KEY is not set. Set it before starting the C++ backend.");
    }

    if (!isSafeModelName(model)) {
        return jsonError(400, "Invalid Gemini model name");
    }

    const std::wstring path =
        L"/v1beta/models/" + widen(model) + L":generateContent";
    const std::string headerText =
        "Content-Type: application/json\r\nx-goog-api-key: " +
        std::string(apiKey) + "\r\n";
    const std::wstring headers = widen(headerText);

    HINTERNET session = InternetOpenA(
        "CampusBudget/1.0",
        INTERNET_OPEN_TYPE_PRECONFIG,
        nullptr,
        nullptr,
        0);
    if (!session) return jsonError(500, "WinINet session failed");

    HINTERNET connect = InternetConnectA(
        session,
        "generativelanguage.googleapis.com",
        INTERNET_DEFAULT_HTTPS_PORT,
        nullptr,
        nullptr,
        INTERNET_SERVICE_HTTP,
        0,
        0);
    if (!connect) {
        InternetCloseHandle(session);
        return jsonError(500, "WinINet connect failed");
    }

    const std::string narrowPath(path.begin(), path.end());
    HINTERNET request = HttpOpenRequestA(
        connect,
        "POST",
        narrowPath.c_str(),
        nullptr,
        nullptr,
        nullptr,
        INTERNET_FLAG_SECURE | INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE,
        0);
    if (!request) {
        InternetCloseHandle(connect);
        InternetCloseHandle(session);
        return jsonError(500, "WinINet request failed");
    }

    const BOOL sent = HttpSendRequestA(
        request,
        headerText.c_str(),
        static_cast<DWORD>(headerText.size()),
        const_cast<char*>(body.data()),
        static_cast<DWORD>(body.size()));
    if (!sent) {
        InternetCloseHandle(request);
        InternetCloseHandle(connect);
        InternetCloseHandle(session);
        return jsonError(502, "Could not reach Gemini API");
    }

    DWORD statusCode = 500;
    DWORD statusSize = sizeof(statusCode);
    HttpQueryInfoA(
        request,
        HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER,
        &statusCode,
        &statusSize,
        nullptr);

    std::string responseBody;
    char buffer[4096];
    while (true) {
        DWORD read = 0;
        if (!InternetReadFile(request, buffer, sizeof(buffer), &read) || read == 0) {
            break;
        }
        responseBody.append(buffer, read);
    }

    InternetCloseHandle(request);
    InternetCloseHandle(connect);
    InternetCloseHandle(session);

    HttpResponse response;
    response.status = static_cast<int>(statusCode);
    response.body = responseBody.empty()
        ? json{{"error", "Gemini returned an empty response"}}.dump()
        : responseBody;
    return response;
}

// GET /health
HttpResponse handleHealth(const HttpRequest&) {
    return jsonOk({{"status", "ok"}, {"service", "campus-budget-api"}});
}

// GET /expenses
HttpResponse handleGetExpenses(const HttpRequest&) {
    json arr = json::array();
    for (const auto& record : gBudget.expenseRecords()) {
        const auto& e = record.expense;
        arr.push_back({
            {"id",       record.id},
            {"date",     e.date()},
            {"category", e.category()},
            {"note",     e.note()},
            {"amount",   e.amount()}
        });
    }
    return jsonOk(arr);
}

// DELETE /expenses
HttpResponse handleClearExpenses(const HttpRequest&) {
    gBudget.clearExpenses();
    saveData();
    return jsonOk({{"cleared", "expenses"}});
}

// POST /expenses
HttpResponse handlePostExpense(const HttpRequest& req) {
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    const int id = gBudget.addExpense(campus::Expense(
        body.value("date", ""),
        body.value("category", ""),
        body.value("note", ""),
        body.value("amount", 0.0)));
    saveData();
    return jsonOk({{"id", id}});
}

// PUT /expenses/:id
HttpResponse handlePutExpense(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    if (!gBudget.updateExpense(id, campus::Expense(
            body.value("date", ""), body.value("category", ""),
            body.value("note", ""), body.value("amount", 0.0)))) {
        return jsonError(404, "Expense not found");
    }
    saveData();
    return jsonOk({{"updated", id}});
}

// DELETE /expenses/:id
HttpResponse handleDeleteExpense(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    if (!gBudget.deleteExpense(id)) return jsonError(404, "Expense not found");
    saveData();
    return jsonOk({{"deleted", id}});
}

// GET /ledgers
HttpResponse handleGetLedgers(const HttpRequest&) {
    json arr = json::array();
    for (const auto& l : gLedgers.entries()) {
        arr.push_back({{"friendName", l.friendName()}, {"amount", l.amount()}});
    }
    return jsonOk(arr);
}

// DELETE /ledgers
HttpResponse handleClearLedgers(const HttpRequest&) {
    gLedgers.clearBalances();
    saveData();
    return jsonOk({{"cleared", "ledgers"}});
}

// POST /ledgers
HttpResponse handlePostLedger(const HttpRequest& req) {
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    gLedgers.upsertBalance(body.value("friendName", ""), body.value("amount", 0.0));
    saveData();
    return jsonOk({{"ok", true}});
}

// DELETE /ledgers/:name
HttpResponse handleDeleteLedger(const HttpRequest& req) {
    const std::string name = req.params.at("name");
    if (!gLedgers.removeBalance(name)) return jsonError(404, "Ledger not found");
    saveData();
    return jsonOk({{"deleted", name}});
}

// GET /piggybanks
HttpResponse handleGetPiggybanks(const HttpRequest&) {
    json arr = json::array();
    for (const auto& record : gPiggybanks.goalRecords()) {
        const auto& p = record.piggybank;
        arr.push_back({
            {"id",          record.id},
            {"name",        p.name()},
            {"goalAmount",  p.goalAmount()},
            {"savedAmount", p.savedAmount()},
            {"dueDate",     p.dueDate()},
            {"progress",    p.progress()}
        });
    }
    return jsonOk(arr);
}

// DELETE /piggybanks
HttpResponse handleClearPiggybanks(const HttpRequest&) {
    gPiggybanks.clearGoals();
    saveData();
    return jsonOk({{"cleared", "piggybanks"}});
}

// POST /piggybanks
HttpResponse handlePostPiggybank(const HttpRequest& req) {
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    const int id = gPiggybanks.addGoal(campus::Piggybank(
        body.value("name", ""),
        body.value("goalAmount", 0.0),
        body.value("savedAmount", 0.0),
        body.value("dueDate", "")));
    saveData();
    return jsonOk({{"id", id}});
}

// PUT /piggybanks/:id
HttpResponse handlePutPiggybank(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    if (!gPiggybanks.updateGoal(id, campus::Piggybank(
            body.value("name", ""), body.value("goalAmount", 0.0),
            body.value("savedAmount", 0.0), body.value("dueDate", "")))) {
        return jsonError(404, "Piggybank not found");
    }
    saveData();
    return jsonOk({{"updated", id}});
}

// DELETE /piggybanks/:id
HttpResponse handleDeletePiggybank(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    if (!gPiggybanks.deleteGoal(id)) return jsonError(404, "Piggybank not found");
    saveData();
    return jsonOk({{"deleted", id}});
}

// POST /piggybanks/:id/deposit
HttpResponse handleDeposit(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    const double amount = body.value("amount", 0.0);
    if (!gPiggybanks.deposit(id, amount)) return jsonError(404, "Piggybank not found");
    saveData();
    return jsonOk({{"deposited", amount}});
}

// POST /piggybanks/:id/withdraw
HttpResponse handleWithdraw(const HttpRequest& req) {
    const int id = std::stoi(req.params.at("id"));
    json body;
    try { body = json::parse(req.body); } catch (...) { return jsonError(400, "Invalid JSON"); }
    const double amount = body.value("amount", 0.0);
    if (!gPiggybanks.withdraw(id, amount)) return jsonError(404, "Piggybank not found");
    saveData();
    return jsonOk({{"withdrawn", amount}});
}

// GET /reports/summary
HttpResponse handleGetSummary(const HttpRequest&) {
    campus::ReportGenerator gen;
    const std::string summary = gen.dashboardSummary(gBudget, gLedgers, gPiggybanks);
    json response;
    response["summary"]      = summary;
    response["totalSpent"]   = gBudget.totalSpent();
    response["topCategory"]  = gBudget.topCategory();
    response["netLedger"]    = gLedgers.netBalance();
    response["savingsGoals"] = static_cast<int>(gPiggybanks.goals().size());
    const auto cats = gBudget.categoryTotals();
    json catsJson = json::object();
    for (const auto& kv : cats) catsJson[kv.first] = kv.second;
    response["categoryTotals"] = catsJson;
    return jsonOk(response);
}

// POST /ai/gemini
HttpResponse handleGeminiProxy(const HttpRequest& req) {
    json body;
    try {
        body = json::parse(req.body);
    } catch (...) {
        return jsonError(400, "Invalid JSON");
    }

    const std::string model = body.value("model", "gemini-flash-lite-latest");
    json geminiBody;
    if (!body.count("contents")) {
        return jsonError(400, "Missing contents");
    }
    geminiBody["contents"] = body["contents"];
    if (body.count("generationConfig")) {
        geminiBody["generationConfig"] = body["generationConfig"];
    }

    return postToGemini(model, geminiBody.dump());
}

// ---------------------------------------------------------------------------
// Route table
// ---------------------------------------------------------------------------

using HandlerFn = std::function<HttpResponse(const HttpRequest&)>;

struct Route {
    std::string method;
    std::string pathTemplate;
    HandlerFn   handler;
};

std::vector<Route> gRoutes = {
    {"GET",    "/health",                   handleHealth},
    {"GET",    "/expenses",                 handleGetExpenses},
    {"DELETE", "/expenses",                 handleClearExpenses},
    {"POST",   "/expenses",                 handlePostExpense},
    {"PUT",    "/expenses/:id",             handlePutExpense},
    {"DELETE", "/expenses/:id",             handleDeleteExpense},
    {"GET",    "/ledgers",                  handleGetLedgers},
    {"DELETE", "/ledgers",                  handleClearLedgers},
    {"POST",   "/ledgers",                  handlePostLedger},
    {"DELETE", "/ledgers/:name",            handleDeleteLedger},
    {"GET",    "/piggybanks",               handleGetPiggybanks},
    {"DELETE", "/piggybanks",               handleClearPiggybanks},
    {"POST",   "/piggybanks",               handlePostPiggybank},
    {"PUT",    "/piggybanks/:id",           handlePutPiggybank},
    {"DELETE", "/piggybanks/:id",           handleDeletePiggybank},
    {"POST",   "/piggybanks/:id/deposit",   handleDeposit},
    {"POST",   "/piggybanks/:id/withdraw",  handleWithdraw},
    {"GET",    "/reports/summary",          handleGetSummary},
    {"POST",   "/ai/gemini",                 handleGeminiProxy},
};

// ---------------------------------------------------------------------------
// HTTP parsing and response sending
// ---------------------------------------------------------------------------

std::string buildResponse(const HttpResponse& res) {
    std::ostringstream out;
    out << "HTTP/1.1 " << res.status;
    if (res.status == 200)       out << " OK";
    else if (res.status == 201)  out << " Created";
    else if (res.status == 204)  out << " No Content";
    else if (res.status == 400)  out << " Bad Request";
    else if (res.status == 404)  out << " Not Found";
    else                         out << " Error";
    out << "\r\n";
    out << "Content-Type: " << res.contentType << "\r\n";
    out << "Content-Length: " << res.body.size() << "\r\n";
    out << "Access-Control-Allow-Origin: *\r\n";
    out << "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n";
    out << "Access-Control-Allow-Headers: Content-Type\r\n";
    out << "Connection: close\r\n";
    out << "\r\n";
    out << res.body;
    return out.str();
}

bool readRequest(SOCKET sock, HttpRequest& req) {
    std::string raw;
    char buf[4096];
    while (true) {
        int n = recv(sock, buf, sizeof(buf), 0);
        if (n <= 0) break;
        raw.append(buf, n);
        if (raw.find("\r\n\r\n") != std::string::npos) break;
    }
    if (raw.empty()) return false;

    // Parse request line
    size_t lineEnd = raw.find("\r\n");
    if (lineEnd == std::string::npos) return false;
    std::istringstream reqLine(raw.substr(0, lineEnd));
    std::string httpVersion;
    reqLine >> req.method >> req.path >> httpVersion;

    // Strip query string from path
    size_t q = req.path.find('?');
    if (q != std::string::npos) req.path = req.path.substr(0, q);

    // Find body
    size_t headerEnd = raw.find("\r\n\r\n");
    if (headerEnd != std::string::npos) {
        req.body = raw.substr(headerEnd + 4);
    }

    // Read remaining body if Content-Length says there's more
    size_t clPos = raw.find("Content-Length: ");
    if (clPos != std::string::npos && clPos < headerEnd) {
        size_t clEnd = raw.find("\r\n", clPos);
        int contentLength = std::stoi(raw.substr(clPos + 16, clEnd - clPos - 16));
        while ((int)req.body.size() < contentLength) {
            int n = recv(sock, buf, sizeof(buf), 0);
            if (n <= 0) break;
            req.body.append(buf, n);
        }
    }

    return true;
}

void handleConnection(SOCKET clientSock) {
    HttpRequest req;
    if (!readRequest(clientSock, req)) {
        closesocket(clientSock);
        return;
    }

    std::cout << req.method << " " << req.path << "\n";

    // CORS preflight
    if (req.method == "OPTIONS") {
        HttpResponse res;
        res.status = 204;
        res.body = "";
        const std::string raw = buildResponse(res);
        send(clientSock, raw.c_str(), (int)raw.size(), 0);
        closesocket(clientSock);
        return;
    }

    // Route matching
    HttpResponse response;
    bool matched = false;
    for (auto& route : gRoutes) {
        if (route.method != req.method) continue;
        std::map<std::string, std::string> params;
        if (matchPath(req.path, route.pathTemplate, params)) {
            req.params = params;
            try {
                response = route.handler(req);
            } catch (const std::exception& ex) {
                response = jsonError(500, std::string("Internal error: ") + ex.what());
            }
            matched = true;
            break;
        }
    }
    if (!matched) {
        response = jsonError(404, "Not found");
    }

    const std::string raw = buildResponse(response);
    send(clientSock, raw.c_str(), (int)raw.size(), 0);
    closesocket(clientSock);
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

int main() {
    // Init Winsock
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        std::cerr << "WSAStartup failed\n";
        return 1;
    }

    loadData();

    SOCKET serverSock = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSock == INVALID_SOCKET) {
        std::cerr << "socket() failed\n";
        return 1;
    }

    // Allow address reuse
    int opt = 1;
    setsockopt(serverSock, SOL_SOCKET, SO_REUSEADDR, (const char*)&opt, sizeof(opt));

    struct sockaddr_in addr;
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(8080);

    if (bind(serverSock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        std::cerr << "bind() failed\n";
        return 1;
    }
    if (listen(serverSock, SOMAXCONN) == SOCKET_ERROR) {
        std::cerr << "listen() failed\n";
        return 1;
    }

    std::cout << "Campus Budget API server running on http://localhost:8080\n";
    std::cout << "Endpoints: /health /expenses /ledgers /piggybanks /reports/summary\n";
    std::cout << "Press Ctrl+C to stop.\n";

    while (true) {
        SOCKET clientSock = accept(serverSock, nullptr, nullptr);
        if (clientSock == INVALID_SOCKET) continue;
        handleConnection(clientSock);
    }

    closesocket(serverSock);
    WSACleanup();
    return 0;
}
