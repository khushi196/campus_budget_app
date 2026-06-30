import '../models/ai_insight.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/ledger.dart';
import '../models/piggybank.dart';

class DemoData {
  const DemoData._();

  static const expenses = <Expense>[];

  static const categories = [
    CategoryBudget(name: 'Food', spent: 0, limit: 0),
    CategoryBudget(name: 'Stationery', spent: 0, limit: 0),
    CategoryBudget(name: 'Grocery', spent: 0, limit: 0),
    CategoryBudget(name: 'Clothes', spent: 0, limit: 0),
  ];

  static const ledgers = [
    Ledger(friendName: 'Khushi', amount: 0),
    Ledger(friendName: 'Aman', amount: 0),
    Ledger(friendName: 'Riya', amount: 0),
  ];

  static const piggybanks = [
    Piggybank(
      name: 'Semester Books',
      goalAmount: 0,
      savedAmount: 0,
      dueDate: '15 Jul',
    ),
    Piggybank(
      name: 'Trip Fund',
      goalAmount: 0,
      savedAmount: 0,
      dueDate: '05 Aug',
    ),
  ];

  static const insights = [
    AiInsight(
      title: 'Food spending is rising',
      body:
          'You used 62% of the food budget. Try keeping meals under Rs. 130 this week.',
      level: InsightLevel.warning,
    ),
    AiInsight(
      title: 'Savings pace looks healthy',
      body: 'Your Semester Books goal is 58% complete with two weeks left.',
      level: InsightLevel.positive,
    ),
    AiInsight(
      title: 'Suggested category',
      body: '"I spent 120 on lunch today" can be recorded under Food.',
      level: InsightLevel.neutral,
    ),
  ];
}
