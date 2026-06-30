import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/income_entry.dart';

class AddIncomeDialog extends StatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _amountController = TextEditingController();
  String _source = 'Parents';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Money'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('income-amount-field'),
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '10000',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Source', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('income-source-field'),
              initialValue: _source,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              items:
                  const [
                        'Parents',
                        'Stipend',
                        'Scholarship',
                        'Part-time',
                        'Other',
                      ]
                      .map(
                        (source) => DropdownMenuItem(
                          value: source,
                          child: Text(source),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _source = value);
                }
              },
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
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Money'),
        ),
      ],
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }
    Navigator.of(
      context,
    ).pop(IncomeEntry(date: 'Today', source: _source, amount: amount));
  }
}

class EditLimitDialog extends StatefulWidget {
  const EditLimitDialog({
    super.key,
    required this.title,
    required this.initialLimit,
  });

  final String title;
  final double initialLimit;

  @override
  State<EditLimitDialog> createState() => _EditLimitDialogState();
}

class _EditLimitDialogState extends State<EditLimitDialog> {
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.initialLimit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: TextField(
          key: const Key('category-limit-field'),
          controller: _limitController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '1500',
            prefixIcon: Icon(Icons.tune_rounded),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Limit'),
        ),
      ],
    );
  }

  void _save() {
    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      return;
    }
    Navigator.of(context).pop(limit);
  }
}
