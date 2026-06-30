import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/ledger.dart';
import '../../services/expense_service.dart';

class LedgersScreen extends StatelessWidget {
  const LedgersScreen({
    super.key,
    required this.expenseService,
    required this.onDataChanged,
  });

  final ExpenseService expenseService;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    final netBalance = expenseService.ledgerBalance;

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
                      'Friend Ledgers',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track money owed between friends and classmates.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showLedgerDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Ledger'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Net ledger balance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    _formatCurrency(netBalance),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: expenseService.ledgers.asMap().entries.map((entry) {
                  return _LedgerTile(
                    ledger: entry.value,
                    index: entry.key,
                    onEdit: () => _showLedgerDialog(
                      context,
                      index: entry.key,
                      initialLedger: entry.value,
                    ),
                    onDelete: () {
                      expenseService.deleteLedger(entry.key);
                      onDataChanged();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLedgerDialog(
    BuildContext context, {
    int? index,
    Ledger? initialLedger,
  }) async {
    final ledger = await showDialog<Ledger>(
      context: context,
      builder: (context) => LedgerDialog(initialLedger: initialLedger),
    );

    if (ledger == null) {
      return;
    }

    if (index == null) {
      expenseService.addLedger(ledger);
    } else {
      expenseService.updateLedger(index, ledger);
    }
    onDataChanged();
  }

  String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.ledger,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Ledger ledger;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = ledger.theyOweYou ? AppColors.green : AppColors.red;
    final label = ledger.theyOweYou ? 'Owes you' : 'You owe';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.13),
            child: Text(
              ledger.friendName.substring(0, 1).toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ledger.friendName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            'Rs. ${ledger.amount.abs().toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: Key('edit-ledger-$index'),
            tooltip: 'Edit ledger',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
          ),
          IconButton(
            key: Key('delete-ledger-$index'),
            tooltip: 'Delete ledger',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class LedgerDialog extends StatefulWidget {
  const LedgerDialog({super.key, this.initialLedger});

  final Ledger? initialLedger;

  @override
  State<LedgerDialog> createState() => _LedgerDialogState();
}

class _LedgerDialogState extends State<LedgerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final ledger = widget.initialLedger;
    _nameController = TextEditingController(text: ledger?.friendName ?? '');
    _amountController = TextEditingController(
      text: ledger == null ? '' : ledger.amount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLedger == null ? 'Add Ledger' : 'Edit Ledger'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('ledger-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Friend name'),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('ledger-amount-field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                helperText:
                    'Positive means they owe you, negative means you owe.',
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
        FilledButton(onPressed: _saveLedger, child: const Text('Save Ledger')),
      ],
    );
  }

  void _saveLedger() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null) {
      return;
    }

    Navigator.of(context).pop(Ledger(friendName: name, amount: amount));
  }
}
