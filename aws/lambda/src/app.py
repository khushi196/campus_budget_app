import json
import os
import urllib.error
import urllib.request
from decimal import Decimal


TABLE = None
_GEMINI_KEY = None


DEFAULT_SNAPSHOT = {
    "addedExpenses": [],
    "incomeEntries": [],
    "ledgers": [],
    "piggybanks": [],
    "dailyLimit": 0,
    "categoryLimits": {},
}


def _table():
    global TABLE
    if TABLE is None:
        import boto3

        TABLE = boto3.resource("dynamodb").Table(os.environ["BUDGET_TABLE"])
    return TABLE


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, default=_json_default),
    }


def _json_default(value):
    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)
        return float(value)
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def _user_id(event):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    return claims.get("sub")


def _path(event):
    return event.get("rawPath") or event.get("requestContext", {}).get("http", {}).get(
        "path", "/"
    )


def _method(event):
    return event.get("requestContext", {}).get("http", {}).get("method", "GET").upper()


def _body(event):
    raw_body = event.get("body")
    if not raw_body:
        return {}
    return json.loads(raw_body)


def _to_decimal(value):
    if isinstance(value, float):
        return Decimal(str(value))
    if isinstance(value, list):
        return [_to_decimal(item) for item in value]
    if isinstance(value, dict):
        return {key: _to_decimal(item) for key, item in value.items()}
    return value


def _clean_snapshot(snapshot):
    clean = dict(DEFAULT_SNAPSHOT)
    if isinstance(snapshot, dict):
        clean.update(snapshot)

    for key in ("addedExpenses", "incomeEntries", "ledgers", "piggybanks"):
        if not isinstance(clean.get(key), list):
            clean[key] = []

    if not isinstance(clean.get("categoryLimits"), dict):
        clean["categoryLimits"] = {}

    if not isinstance(clean.get("dailyLimit"), (int, float, Decimal)):
        clean["dailyLimit"] = 0

    return clean


def _load_snapshot(user_id):
    result = _table().get_item(Key={"pk": f"USER#{user_id}", "sk": "SNAPSHOT"})
    item = result.get("Item")
    if not item:
        return dict(DEFAULT_SNAPSHOT)
    return _clean_snapshot(item.get("snapshot", {}))


def _save_snapshot(user_id, snapshot):
    clean = _clean_snapshot(snapshot)
    _table().put_item(
        Item={
            "pk": f"USER#{user_id}",
            "sk": "SNAPSHOT",
            "snapshot": _to_decimal(clean),
        }
    )
    return clean


def _money_total(rows):
    total = Decimal("0")
    for row in rows:
        amount = row.get("amount", 0) if isinstance(row, dict) else 0
        if isinstance(amount, Decimal):
            total += amount
        elif isinstance(amount, (int, float)):
            total += Decimal(str(amount))
    return total


def _report_summary(snapshot):
    expenses = snapshot.get("addedExpenses", [])
    income = snapshot.get("incomeEntries", [])
    ledgers = snapshot.get("ledgers", [])
    piggybanks = snapshot.get("piggybanks", [])

    category_totals = {}
    for expense in expenses:
        if not isinstance(expense, dict):
            continue
        category = str(expense.get("category") or "Other")
        amount = expense.get("amount", 0)
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount)) if isinstance(amount, (int, float)) else Decimal("0")
        category_totals[category] = category_totals.get(category, Decimal("0")) + amount

    total_spent = _money_total(expenses)
    total_income = _money_total(income)
    top_category = "None"
    if category_totals:
        top_category = max(category_totals.items(), key=lambda item: item[1])[0]

    return {
        "totalSpent": total_spent,
        "totalIncome": total_income,
        "balanceLeft": total_income - total_spent,
        "topCategory": top_category,
        "ledgerBalance": _money_total(ledgers),
        "savingsGoals": len(piggybanks),
    }


def _gemini_api_key():
    global _GEMINI_KEY
    if _GEMINI_KEY:
        return _GEMINI_KEY

    env_key = os.environ.get("GEMINI_API_KEY")
    if env_key:
        _GEMINI_KEY = _clean_api_key(env_key)
        return _GEMINI_KEY

    parameter_name = os.environ.get("GEMINI_API_KEY_PARAM")
    if not parameter_name:
        return None

    import boto3

    response = boto3.client("ssm").get_parameter(
        Name=parameter_name,
        WithDecryption=True,
    )
    _GEMINI_KEY = _clean_api_key(response["Parameter"]["Value"])
    return _GEMINI_KEY


def _ask_gemini(payload):
    api_key = _gemini_api_key()
    if not api_key:
        return _response(503, {"error": "Gemini API key is not configured."})

    model = payload.get("model") or "gemini-flash-lite-latest"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    request = urllib.request.Request(
        url,
        data=json.dumps(_gemini_request_body(payload)).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": api_key,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = json.loads(response.read().decode("utf-8"))
            return _response(response.status, body)
    except urllib.error.HTTPError as error:
        error_body = error.read().decode("utf-8")
        try:
            return _response(error.code, json.loads(error_body))
        except json.JSONDecodeError:
            return _response(error.code, {"error": error_body})
    except urllib.error.URLError as error:
        return _response(502, {"error": str(error.reason)})


def _gemini_request_body(payload):
    return {key: value for key, value in payload.items() if key != "model"}


def _clean_api_key(value):
    return "".join(char for char in value.strip() if char.isprintable())


def handler(event, context):
    method = _method(event)
    path = _path(event).rstrip("/") or "/"

    if method == "OPTIONS":
        return _response(200, {"ok": True})

    if path == "/health":
        return _response(200, {"status": "ok"})

    user_id = _user_id(event)
    if not user_id:
        return _response(401, {"error": "Missing authenticated user."})

    try:
        if method == "GET" and path == "/snapshot":
            return _response(200, _load_snapshot(user_id))
        if method == "PUT" and path == "/snapshot":
            return _response(200, _save_snapshot(user_id, _body(event)))
        if method == "GET" and path == "/reports/summary":
            return _response(200, _report_summary(_load_snapshot(user_id)))
        if method == "POST" and path == "/ai/gemini":
            return _ask_gemini(_body(event))
    except json.JSONDecodeError:
        return _response(400, {"error": "Request body must be valid JSON."})
    except Exception as error:
        return _response(500, {"error": f"{type(error).__name__}: {error}"})

    return _response(404, {"error": "Route not found."})
