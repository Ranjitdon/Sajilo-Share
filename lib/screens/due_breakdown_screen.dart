import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../utils/format_utils.dart';
import '../providers/dues_provider.dart';
import '../models/room_expense.dart';

class DueBreakdownScreen extends ConsumerWidget {
  final String roomId;
  final String otherUserId;

  const DueBreakdownScreen({
    super.key,
    required this.roomId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final expensesAsync = ref.watch(roomExpensesProvider(roomId));
    final settlementsAsync = ref.watch(roomSettlementsProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Breakdown'),
      ),
      body: (expensesAsync is AsyncLoading || settlementsAsync is AsyncLoading)
          ? const Center(child: CircularProgressIndicator())
          : (expensesAsync.hasError)
              ? Center(child: Text('Error: ${expensesAsync.error}'))
              : _buildLedger(context, theme, user.uid, expensesAsync.value ?? [], settlementsAsync.value ?? []),
    );
  }

  Widget _buildLedger(BuildContext context, ThemeData theme, String myUid, List<RoomExpense> expenses, List<Map<String, dynamic>> settlements) {
    // Combine relevant expenses and settlements into a single chronological list
    List<Map<String, dynamic>> ledger = [];

    // Filter and format expenses
    for (final exp in expenses) {
      if (exp.splitBetweenIds.isEmpty) continue;
      
      double splitAmount = exp.amount / exp.splitBetweenIds.length;
      
      if (exp.paidById == myUid && exp.splitBetweenIds.contains(otherUserId)) {
        ledger.add({
          'type': 'expense',
          'date': exp.createdAt,
          'description': exp.description,
          'amount': splitAmount, // otherUser owes me this part
          'isCredit': true, // true if it increases the amount they owe me (or decreases what I owe them)
        });
      } else if (exp.paidById == otherUserId && exp.splitBetweenIds.contains(myUid)) {
        ledger.add({
          'type': 'expense',
          'date': exp.createdAt,
          'description': exp.description,
          'amount': splitAmount, // I owe otherUser this part
          'isCredit': false,
        });
      }
    }

    // Filter and format settlements
    for (final stl in settlements) {
      final fromUid = stl['fromUid'] as String?;
      final toUid = stl['toUid'] as String?;
      final amount = (stl['amount'] ?? 0.0) as num;
      final createdAt = stl['createdAt'] != null ? (stl['createdAt'] as dynamic).toDate() : DateTime.now();
      final status = stl['status'] as String?;

      if (fromUid == myUid && toUid == otherUserId) {
        ledger.add({
          'type': 'settlement',
          'date': createdAt,
          'description': status == 'pending' ? 'You paid them (Pending)' : 'You paid them',
          'amount': amount.toDouble(),
          'isCredit': true, 
          'isPending': status == 'pending',
        });
      } else if (fromUid == otherUserId && toUid == myUid) {
        ledger.add({
          'type': 'settlement',
          'date': createdAt,
          'description': status == 'pending' ? 'They paid you (Pending)' : 'They paid you',
          'amount': amount.toDouble(),
          'isCredit': false,
          'isPending': status == 'pending',
        });
      }
    }

    // Sort descending by date
    ledger.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (ledger.isEmpty) {
      return const Center(child: Text('No transaction history found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ledger.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = ledger[index];
            final isExpense = item['type'] == 'expense';
            final isCredit = item['isCredit'] as bool;
            final isPending = item['isPending'] == true;
            final amount = item['amount'] as double;
            final date = item['date'] as DateTime;
            final desc = item['description'] as String;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isExpense 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : (isPending ? Colors.orange[100] : Colors.green[100]),
                child: Icon(
                  isExpense ? Icons.receipt_long : (isPending ? Icons.pending_actions : Icons.handshake),
                  color: isExpense ? theme.colorScheme.primary : (isPending ? Colors.orange[800] : Colors.green[700]),
                ),
              ),
              title: Text(
                desc,
                style: TextStyle(
                  color: isPending ? theme.colorScheme.onSurfaceVariant : null,
                  fontStyle: isPending ? FontStyle.italic : null,
                ),
              ),
              subtitle: Text(DateFormat('MMM d, yyyy • h:mm a').format(date)),
              trailing: Text(
                '${isCredit ? '+' : '-'}₹${formatMoney(amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isCredit 
                      ? (isPending ? Colors.orange[700] : Colors.green[700]) 
                      : (isPending ? Colors.orange[700] : theme.colorScheme.error),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
