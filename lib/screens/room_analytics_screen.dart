import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/room_provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../utils/format_utils.dart';

class RoomAnalyticsScreen extends ConsumerWidget {
  final String roomId;
  final String roomName;

  const RoomAnalyticsScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(roomExpensesProvider(roomId));
    final categories = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$roomName Analytics'),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('No expense data to analyze.'));
          }

          // Aggregate expenses by category
          final Map<String, double> categoryTotals = {};
          double totalSpending = 0;

          for (final exp in expenses) {
            categoryTotals[exp.categoryId] = (categoryTotals[exp.categoryId] ?? 0) + exp.amount;
            totalSpending += exp.amount;
          }

          // Sort by highest spending
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Generate pie chart sections
          List<PieChartSectionData> pieSections = [];
          
          for (int i = 0; i < sortedCategories.length; i++) {
            final entry = sortedCategories[i];
            final catId = entry.key;
            final amount = entry.value;
            final percentage = (amount / totalSpending) * 100;
            
            final category = categories.firstWhere(
              (c) => c.id == catId,
              orElse: () => ExpenseCategory.defaultCategories.last,
            );

            pieSections.add(
              PieChartSectionData(
                color: _hexToColor(category.color),
                value: amount,
                title: '${percentage.toStringAsFixed(0)}%',
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Text(
                  'Group Total Spent: ₹${formatMoney(totalSpending)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: pieSections,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Group Spending by Category',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: sortedCategories.map((entry) {
                      final catId = entry.key;
                      final amount = entry.value;
                      final category = categories.firstWhere(
                        (c) => c.id == catId,
                        orElse: () => ExpenseCategory.defaultCategories.last,
                      );
                      
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _hexToColor(category.color).withValues(alpha: 0.2),
                              child: Text(category.icon),
                            ),
                            title: Text(category.name),
                            trailing: Text(
                              '₹${formatMoney(amount)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (entry.key != sortedCategories.last.key)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
