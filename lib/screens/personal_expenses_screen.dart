import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';
import '../utils/format_utils.dart';

class PersonalExpensesScreen extends ConsumerStatefulWidget {
  const PersonalExpensesScreen({super.key});

  @override
  ConsumerState<PersonalExpensesScreen> createState() => _PersonalExpensesScreenState();
}

class _PersonalExpensesScreenState extends ConsumerState<PersonalExpensesScreen> {
  String _selectedCategoryFilter = 'All';
  int _expenseLimit = 15;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(personalExpensesProvider);
    final categories = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const FlatShareAppBar(),
      body: expensesAsync.when(
        data: (expenses) {
          final totalSpent = expenses.fold<double>(0, (sum, exp) => sum + exp.amount);
          
          // Filter expenses if a specific category is selected
          final filteredExpenses = _selectedCategoryFilter == 'All'
              ? expenses
              : expenses.where((exp) {
                  final cat = categories.firstWhere(
                    (c) => c.id == exp.categoryId,
                    orElse: () => ExpenseCategory.defaultCategories.last,
                  );
                  return cat.name.toLowerCase() == _selectedCategoryFilter.toLowerCase();
                }).toList();

          // Limit expenses
          final hasMore = filteredExpenses.length > _expenseLimit;
          final displayedExpenses = filteredExpenses.take(_expenseLimit).toList();

          // Group expenses by day
          final groupedExpenses = _groupExpensesByDate(displayedExpenses, categories);

          return Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dashboard Summary Card
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THIS MONTH',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${formatMoney(totalSpent)}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Spend',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 36,
                        child: TextButton.icon(
                          onPressed: () => context.push('/analytics'),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.analytics, size: 18),
                          label: const Text('View Analytics'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Filter Quick Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Groceries'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Travel'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rent'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Grouped list
                if (filteredExpenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        'No expenses found.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      itemCount: groupedExpenses.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        if (index == groupedExpenses.length) {
                          return TextButton(
                            onPressed: () {
                              setState(() {
                                _expenseLimit += 15;
                              });
                            },
                            child: const Text('See more'),
                          );
                        }
                      final group = groupedExpenses[index];
                      final dateHeader = group.key;
                      final list = group.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                            child: Text(
                              dateHeader,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                              ),
                              itemBuilder: (context, itemIndex) {
                                final expense = list[itemIndex];
                                final category = categories.firstWhere(
                                  (c) => c.id == expense.categoryId,
                                  orElse: () => ExpenseCategory.defaultCategories.last,
                                );

                                final catColor = _hexToColor(category.color);

                                Widget tile = ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getIcon(category.icon),
                                      color: catColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    expense.note.isNotEmpty ? expense.note : category.name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat('hh:mm a').format(expense.date)} • ${expense.note.isNotEmpty ? category.name : (expense.roomId != null ? "Room" : "Personal")}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${formatMoney(expense.amount)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        expense.roomId != null ? 'Room Share' : 'Personal',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontSize: 10,
                                          color: expense.roomId != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (expense.roomId == null) {
                                  return Dismissible(
                                    key: Key(expense.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: theme.colorScheme.error,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20.0),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Expense'),
                                          content: const Text('Are you sure you want to delete this personal expense?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) async {
                                      final controller = ref.read(expenseControllerProvider);
                                      if (controller != null) {
                                        await controller.deletePersonalExpense(expense.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Expense deleted')),
                                          );
                                        }
                                      }
                                    },
                                    child: tile,
                                  );
                                }

                                return tile;
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_personal_expenses',
        onPressed: () {
          context.push('/add-personal-expense');
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategoryFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, List<dynamic>>> _groupExpensesByDate(List<dynamic> expenses, List<ExpenseCategory> categories) {
    final Map<String, List<dynamic>> groups = {};
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    for (final exp in expenses) {
      final expDateStr = DateFormat('yyyy-MM-dd').format(exp.date);
      String header;
      if (expDateStr == todayStr) {
        header = 'Today';
      } else if (expDateStr == yesterdayStr) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM d, yyyy').format(exp.date);
      }
      groups.putIfAbsent(header, () => []).add(exp);
    }
    
    // Sort groups so that Today/Yesterday comes first
    final list = groups.entries.toList();
    list.sort((a, b) {
      if (a.key == 'Today') return -1;
      if (b.key == 'Today') return 1;
      if (a.key == 'Yesterday') return -1;
      if (b.key == 'Yesterday') return 1;
      return b.value.first.date.compareTo(a.value.first.date);
    });

    return list;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'checkroom': return Icons.checkroom;
      case 'bolt': return Icons.bolt;
      case 'home': return Icons.home;
      case 'movie': return Icons.movie;
      default: return Icons.category;
    }
  }
}
