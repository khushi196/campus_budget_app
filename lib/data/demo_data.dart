import '../models/ai_insight.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/ledger.dart';
import '../models/piggybank.dart';

class DemoData {
  const DemoData._();

  static const expenses = [
    Expense(
      date: '30 Jun',
      category: 'Food',
      note: 'Lunch near campus',
      amount: 120,
    ),
    Expense(
      date: '30 Jun',
      category: 'Stationery',
      note: 'Notebook set',
      amount: 85,
    ),
    Expense(
      date: '29 Jun',
      category: 'Grocery',
      note: 'Hostel snacks',
      amount: 260,
    ),
    Expense(
      date: '28 Jun',
      category: 'Clothes',
      note: 'Laundry basics',
      amount: 450,
    ),
  ];

  static const categories = [
    CategoryBudget(name: 'Food', spent: 620, limit: 1000),
    CategoryBudget(name: 'Stationery', spent: 280, limit: 1000),
    CategoryBudget(name: 'Grocery', spent: 760, limit: 1000),
    CategoryBudget(name: 'Clothes', spent: 450, limit: 1000),
  ];

  static const ledgers = [
    Ledger(friendName: 'Khushi', amount: 60),
    Ledger(friendName: 'Aman', amount: -120),
    Ledger(friendName: 'Riya', amount: 240),
  ];

  static const piggybanks = [
    Piggybank(
      name: 'Semester Books',
      goalAmount: 2500,
      savedAmount: 1450,
      dueDate: '15 Jul',
    ),
    Piggybank(
      name: 'Trip Fund',
      goalAmount: 5000,
      savedAmount: 2100,
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
