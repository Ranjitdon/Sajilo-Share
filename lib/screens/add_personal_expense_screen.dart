import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';

class AddPersonalExpenseScreen extends ConsumerStatefulWidget {
  const AddPersonalExpenseScreen({super.key});

  @override
  ConsumerState<AddPersonalExpenseScreen> createState() => _AddPersonalExpenseScreenState();
}

class _AddPersonalExpenseScreenState extends ConsumerState<AddPersonalExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategoryId = 'food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final expenseController = ref.read(expenseControllerProvider);
    if (expenseController == null) return;

    setState(() => _isLoading = true);

    try {
      final expense = Expense(
        id: const Uuid().v4(),
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      await expenseController.addPersonalExpense(expense);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _getCategoryIcon(String iconName) {
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlatShareAppBar(
        showBackButton: true,
        title: Text(
          'Add Expense',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Input Section (Large & Centered)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _amountController,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: '0',
                                hintStyle: theme.textTheme.displayLarge?.copyWith(
                                  color: theme.colorScheme.outlineVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter an amount';
                                if (double.tryParse(val) == null) return 'Enter a valid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT CATEGORY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSel = _selectedCategoryId == cat.id;
                          final catColor = _hexToColor(cat.color);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                              });
                            },
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSel ? catColor : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: catColor.withValues(alpha: 0.3),
                                              offset: const Offset(0, 4),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(cat.icon),
                                    color: isSel ? Colors.white : catColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.name,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontSize: 11,
                                    color: isSel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Form Fields
                // Date Input Card
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM d, yyyy').format(_selectedDate),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_calendar, color: theme.colorScheme.outlineVariant, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description (Note) Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Icon(Icons.description, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            labelText: 'Description',
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            hintText: 'What was this for?',
                            hintStyle: theme.textTheme.bodySmall,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Floating Save Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check, color: Colors.white, size: 22),
                          label: Text(
                            'Save Expense',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
