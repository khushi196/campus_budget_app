import json
import os
import sys
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
sys.path.insert(0, ROOT)

import app


class FakeTable:
    def __init__(self):
        self.items = {}

    def put_item(self, Item):
        self.items[(Item["pk"], Item["sk"])] = dict(Item)

    def get_item(self, Key):
        item = self.items.get((Key["pk"], Key["sk"]))
        return {"Item": dict(item)} if item else {}

    def query(self, KeyConditionExpression=None, ExpressionAttributeValues=None):
        if KeyConditionExpression is None:
            raise ValueError("DynamoDB query requires KeyConditionExpression")
        pk = ExpressionAttributeValues[":pk"]
        rows = [item for (item_pk, _), item in self.items.items() if item_pk == pk]
        return {"Items": sorted(rows, key=lambda item: item["sk"])}

    def delete_item(self, Key):
        self.items.pop((Key["pk"], Key["sk"]), None)

    def batch_writer(self):
        return self

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


class LambdaApiTest(unittest.TestCase):
    def setUp(self):
        self.table = FakeTable()
        app.TABLE = self.table

    def event(self, method, path, body=None):
        return {
            "requestContext": {
                "http": {"method": method, "path": path},
                "authorizer": {"jwt": {"claims": {"sub": "student-1"}}},
            },
            "body": json.dumps(body) if body is not None else None,
        }

    def body(self, response):
        self.assertEqual(response["statusCode"], 200, response)
        return json.loads(response["body"])

    def test_snapshot_round_trip_is_user_scoped(self):
        snapshot = {
            "addedExpenses": [
                {"date": "Today", "category": "Food", "note": "Tea", "amount": 25}
            ],
            "incomeEntries": [
                {"date": "Today", "source": "Parents", "amount": 1000}
            ],
            "ledgers": [{"friendName": "Neha", "amount": 100}],
            "piggybanks": [
                {
                    "name": "Laptop",
                    "goalAmount": 60000,
                    "savedAmount": 5000,
                    "dueDate": "20 Aug",
                }
            ],
            "dailyLimit": 300,
            "categoryLimits": {"Food": 1500},
        }

        save_response = app.handler(self.event("PUT", "/snapshot", snapshot), None)
        self.assertEqual(save_response["statusCode"], 200)

        loaded = self.body(app.handler(self.event("GET", "/snapshot"), None))

        self.assertEqual(loaded["addedExpenses"][0]["note"], "Tea")
        self.assertEqual(loaded["incomeEntries"][0]["source"], "Parents")
        self.assertEqual(loaded["ledgers"][0]["friendName"], "Neha")
        self.assertEqual(loaded["piggybanks"][0]["name"], "Laptop")
        self.assertEqual(loaded["dailyLimit"], 300)
        self.assertEqual(loaded["categoryLimits"]["Food"], 1500)

    def test_report_summary_uses_snapshot_totals(self):
        app.handler(
            self.event(
                "PUT",
                "/snapshot",
                {
                    "addedExpenses": [
                        {
                            "date": "Today",
                            "category": "Food",
                            "note": "Tea",
                            "amount": 25,
                        },
                        {
                            "date": "Today",
                            "category": "Stationery",
                            "note": "Pen",
                            "amount": 10,
                        },
                    ],
                    "incomeEntries": [
                        {"date": "Today", "source": "Parents", "amount": 1000}
                    ],
                    "ledgers": [{"friendName": "Neha", "amount": 100}],
                    "piggybanks": [],
                    "dailyLimit": 300,
                    "categoryLimits": {},
                },
            ),
            None,
        )

        summary = self.body(app.handler(self.event("GET", "/reports/summary"), None))

        self.assertEqual(summary["totalSpent"], 35)
        self.assertEqual(summary["totalIncome"], 1000)
        self.assertEqual(summary["balanceLeft"], 965)
        self.assertEqual(summary["topCategory"], "Food")

    def test_missing_auth_is_rejected(self):
        response = app.handler(
            {"requestContext": {"http": {"method": "GET", "path": "/snapshot"}}},
            None,
        )

        self.assertEqual(response["statusCode"], 401)

    def test_gemini_body_removes_model_before_proxy(self):
        payload = {
            "model": "gemini-flash-lite-latest",
            "contents": [{"role": "user", "parts": [{"text": "hello"}]}],
        }

        self.assertEqual(
            app._gemini_request_body(payload),
            {"contents": [{"role": "user", "parts": [{"text": "hello"}]}]},
        )

    def test_gemini_key_is_trimmed_before_header_use(self):
        self.assertEqual(app._clean_api_key("  ab\rc\n123\u0016"), "abc123")


if __name__ == "__main__":
    unittest.main()
