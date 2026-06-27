import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';
import '../utils/format_utils.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime? _filterMonth;

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(personalExpensesProvider);
    final categories = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: FlatShareAppBar(
        showBackButton: true,
        title: Text(
          'Personal Analytics',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 72,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expense data to analyze.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter the expenses
          final availableMonths = expenses.map((e) => DateTime(e.date.year, e.date.month)).toSet().toList();
          availableMonths.sort((a, b) => b.compareTo(a));

          final filteredExpenses = _filterMonth == null
              ? expenses
              : expenses.where((e) => e.date.year == _filterMonth!.year && e.date.month == _filterMonth!.month).toList();

          // 1. Calculate this month and last month sums
          final now = DateTime.now();
          final thisMonthStart = DateTime(now.year, now.month, 1);
          final lastMonthStart = DateTime(now.year, now.month - 1, 1);

          double thisMonthSum = 0;
          double lastMonthSum = 0;
          final Map<String, double> categoryTotals = {};
          double totalSpending = 0;

          for (final exp in filteredExpenses) {
            categoryTotals[exp.categoryId] = (categoryTotals[exp.categoryId] ?? 0) + exp.amount;
            totalSpending += exp.amount;
          }

          // For trends, we still need to iterate ALL expenses (unfiltered)
          for (final exp in expenses) {
            if (exp.date.isAfter(thisMonthStart.subtract(const Duration(seconds: 1)))) {
              thisMonthSum += exp.amount;
            } else if (exp.date.isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) && exp.date.isBefore(thisMonthStart)) {
              lastMonthSum += exp.amount;
            }
          }

          // 2. Trend Calculations
          String trendText = 'Trend data not available';
          IconData trendIcon = Icons.trending_flat;
          Color trendColor = Colors.white.withValues(alpha: 0.7);

          if (lastMonthSum > 0) {
            final diff = ((thisMonthSum - lastMonthSum) / lastMonthSum) * 100;
            if (diff > 0.01) {
              trendText = '${diff.toStringAsFixed(0)}% more than last month';
              trendIcon = Icons.trending_up;
              trendColor = theme.colorScheme.errorContainer;
            } else if (diff < -0.01) {
              trendText = '${diff.abs().toStringAsFixed(0)}% less than last month';
              trendIcon = Icons.trending_down;
              trendColor = theme.colorScheme.secondaryContainer;
            } else {
              trendText = 'Equal to last month';
              trendIcon = Icons.trending_flat;
              trendColor = Colors.white70;
            }
          }

          // 3. Sort by highest spending
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // 4. Generate pie chart sections
          List<PieChartSectionData> pieSections = [];
          for (int i = 0; i < sortedCategories.length; i++) {
            final entry = sortedCategories[i];
            final catId = entry.key;
            final amount = entry.value;
            
            final category = categories.firstWhere(
              (c) => c.id == catId,
              orElse: () => ExpenseCategory.defaultCategories.last,
            );

            pieSections.add(
              PieChartSectionData(
                color: _hexToColor(category.color),
                value: amount,
                showTitle: false,
                radius: 20,
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by Month', style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime?>(
                          value: _filterMonth,
                          hint: const Text('All Time'),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Time')),
                            ...availableMonths.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM yyyy').format(m)),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterMonth = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -32,
                        top: -32,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _filterMonth == null ? 'TOTAL SPENT (ALL TIME)' : 'SPENT IN ${DateFormat('MMM yyyy').format(_filterMonth!).toUpperCase()}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${formatMoney(totalSpending)}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_filterMonth == null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  trendIcon,
                                  color: trendColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  trendText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: trendColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Spend Distribution Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spend Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 70,
                                  sections: pieSections,
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹${formatMoney(totalSpending / 1000)}k',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Categories List Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = sortedCategories[index];
                          final catId = entry.key;
                          final amount = entry.value;
                          final percentage = amount / totalSpending;
                          
                          final category = categories.firstWhere(
                            (c) => c.id == catId,
                            orElse: () => ExpenseCategory.defaultCategories.last,
                          );
                          final catColor = _hexToColor(category.color);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: catColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${(percentage * 100).toStringAsFixed(0)}% of total',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${formatMoney(amount)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Spending Tip
                if (totalSpending > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spending Tip',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Track categories with the highest progress bar ratios to identify where you can optimize your personal budget.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
