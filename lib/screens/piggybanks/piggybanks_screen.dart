import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/piggybank.dart';
import '../../services/expense_service.dart';

class PiggybanksScreen extends StatelessWidget {
  const PiggybanksScreen({
    super.key,
    required this.expenseService,
    required this.onDataChanged,
  });

  final ExpenseService expenseService;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Goals',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plan bigger campus expenses with piggybank goals.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showGoalDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Goal'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920 ? 2 : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.55,
                children: expenseService.piggybanks.asMap().entries.map((
                  entry,
                ) {
                  return _PiggybankCard(
                    piggybank: entry.value,
                    index: entry.key,
                    onEdit: () => _showGoalDialog(
                      context,
                      index: entry.key,
                      initialPiggybank: entry.value,
                    ),
                    onAddMoney: () => _showAmountDialog(
                      context,
                      title: 'Add money',
                      onSave: (amount) =>
                          expenseService.addToPiggybank(entry.key, amount),
                    ),
                    onWithdraw: () => _showAmountDialog(
                      context,
                      title: 'Withdraw money',
                      onSave: (amount) => expenseService.withdrawFromPiggybank(
                        entry.key,
                        amount,
                      ),
                    ),
                    onDelete: () {
                      expenseService.deletePiggybank(entry.key);
                      onDataChanged();
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalDialog(
    BuildContext context, {
    int? index,
    Piggybank? initialPiggybank,
  }) async {
    final piggybank = await showDialog<Piggybank>(
      context: context,
      builder: (context) => PiggybankDialog(initialPiggybank: initialPiggybank),
    );

    if (piggybank == null) {
      return;
    }

    if (index == null) {
      expenseService.addPiggybank(piggybank);
    } else {
      expenseService.updatePiggybank(index, piggybank);
    }
    onDataChanged();
  }

  Future<void> _showAmountDialog(
    BuildContext context, {
    required String title,
    required ValueChanged<double> onSave,
  }) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => PiggybankAmountDialog(title: title),
    );

    if (amount == null) {
      return;
    }

    onSave(amount);
    onDataChanged();
  }
}

class _PiggybankCard extends StatelessWidget {
  const _PiggybankCard({
    required this.piggybank,
    required this.index,
    required this.onEdit,
    required this.onAddMoney,
    required this.onWithdraw,
    required this.onDelete,
  });

  final Piggybank piggybank;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onAddMoney;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    piggybank.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  piggybank.dueDate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: piggybank.progress,
                minHeight: 10,
                color: AppColors.green,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rs. ${piggybank.savedAmount.toStringAsFixed(0)} saved of Rs. ${piggybank.goalAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                IconButton.filledTonal(
                  key: Key('add-piggybank-money-$index'),
                  tooltip: 'Add money',
                  onPressed: onAddMoney,
                  icon: const Icon(Icons.add_rounded),
                ),
                IconButton.filledTonal(
                  key: Key('withdraw-piggybank-money-$index'),
                  tooltip: 'Withdraw money',
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.remove_rounded),
                ),
                IconButton.filledTonal(
                  key: Key('edit-piggybank-$index'),
                  tooltip: 'Edit goal',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton.filledTonal(
                  key: Key('delete-piggybank-$index'),
                  tooltip: 'Delete goal',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PiggybankDialog extends StatefulWidget {
  const PiggybankDialog({super.key, this.initialPiggybank});

  final Piggybank? initialPiggybank;

  @override
  State<PiggybankDialog> createState() => _PiggybankDialogState();
}

class _PiggybankDialogState extends State<PiggybankDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;
  late final TextEditingController _savedController;
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    final piggybank = widget.initialPiggybank;
    _nameController = TextEditingController(text: piggybank?.name ?? '');
    _goalController = TextEditingController(
      text: piggybank == null ? '' : piggybank.goalAmount.toStringAsFixed(0),
    );
    _savedController = TextEditingController(
      text: piggybank == null ? '' : piggybank.savedAmount.toStringAsFixed(0),
    );
    _dateController = TextEditingController(text: piggybank?.dueDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _savedController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialPiggybank == null ? 'Add Goal' : 'Edit Goal'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('piggybank-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Goal name'),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('piggybank-goal-field'),
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Goal amount'),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('piggybank-saved-field'),
              controller: _savedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Saved amount'),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('piggybank-date-field'),
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Due date'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveGoal, child: const Text('Save Goal')),
      ],
    );
  }

  void _saveGoal() {
    final name = _nameController.text.trim();
    final goal = double.tryParse(_goalController.text.trim());
    final saved = double.tryParse(_savedController.text.trim());
    final date = _dateController.text.trim();
    if (name.isEmpty || date.isEmpty || goal == null || goal <= 0) {
      return;
    }

    Navigator.of(context).pop(
      Piggybank(
        name: name,
        goalAmount: goal,
        savedAmount: saved ?? 0,
        dueDate: date,
      ),
    );
  }
}

class PiggybankAmountDialog extends StatefulWidget {
  const PiggybankAmountDialog({super.key, required this.title});

  final String title;

  @override
  State<PiggybankAmountDialog> createState() => _PiggybankAmountDialogState();
}

class _PiggybankAmountDialogState extends State<PiggybankAmountDialog> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('piggybank-amount-field'),
        controller: _amountController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveAmount, child: const Text('Save Amount')),
      ],
    );
  }

  void _saveAmount() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }

    Navigator.of(context).pop(amount);
  }
}
