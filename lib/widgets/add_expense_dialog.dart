import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/demo_data.dart';
import '../models/expense.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key, this.initialExpense});

  final Expense? initialExpense;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = DemoData.categories.first.name;

  @override
  void initState() {
    super.initState();
    final initialExpense = widget.initialExpense;
    if (initialExpense != null) {
      _amountController.text = initialExpense.amount.toStringAsFixed(0);
      _noteController.text = initialExpense.note;
      _category = initialExpense.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialExpense == null ? 'Add Expense' : 'Edit Expense',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('expense-amount-field'),
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '150',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: DemoData.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.name,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Note', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('expense-note-field'),
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Campus coffee',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Expense'),
        ),
      ],
    );
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();

    if (amount == null || amount <= 0 || note.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      Expense(
        date: widget.initialExpense?.date ?? 'Today',
        category: _category,
        note: note,
        amount: amount,
      ),
    );
  }
}
