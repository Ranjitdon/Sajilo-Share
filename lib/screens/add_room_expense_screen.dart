import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/room.dart';
import '../models/room_expense.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/flatshare_app_bar.dart';
import '../widgets/user_avatar_name.dart';
import '../theme.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class _ExpenseItemModel {
  final TextEditingController nameController;
  final TextEditingController amountController;

  _ExpenseItemModel({required String name, required String amount})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class AddRoomExpenseScreen extends ConsumerStatefulWidget {
  final Room room;
  final RoomExpense? expenseToEdit;
  
  const AddRoomExpenseScreen({super.key, required this.room, this.expenseToEdit});

  @override
  ConsumerState<AddRoomExpenseScreen> createState() => _AddRoomExpenseScreenState();
}

class _AddRoomExpenseScreenState extends ConsumerState<AddRoomExpenseScreen> {
  final _titleController = TextEditingController();
  final List<_ExpenseItemModel> _items = [];
  List<String> _selectedMemberIds = [];
  
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  File? _receiptImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final exp = widget.expenseToEdit!;
      _titleController.text = exp.description;
      _selectedCategoryId = exp.categoryId;
      _selectedDate = exp.createdAt;
      _existingImageUrl = exp.imageUrl;
      
      if (exp.items.isNotEmpty) {
        for (var itemMap in exp.items) {
          _items.add(_ExpenseItemModel(
            name: itemMap['name'] ?? '', 
            amount: (itemMap['amount'] ?? 0.0).toString()
          ));
        }
      } else {
        _items.add(_ExpenseItemModel(name: 'Expense', amount: exp.amount.toString()));
      }
      _selectedMemberIds = List.from(exp.splitBetweenIds);
    } else {
      _items.add(_ExpenseItemModel(name: '', amount: ''));
      _selectedMemberIds = List.from(widget.room.memberIds);
    }

    for (var item in _items) {
      item.amountController.addListener(_onAmountChanged);
    }
  }

  void _onAmountChanged() {
    setState(() {}); // Rebuild to update total sum
  }

  double get _totalAmount {
    double total = 0;
    for (var item in _items) {
      final val = double.tryParse(item.amountController.text) ?? 0;
      total += val;
    }
    return total;
  }

  void _addItem() {
    setState(() {
      final newItem = _ExpenseItemModel(name: '', amount: '');
      newItem.amountController.addListener(_onAmountChanged);
      _items.add(newItem);
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        final item = _items.removeAt(index);
        item.amountController.removeListener(_onAmountChanged);
        item.dispose();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var item in _items) {
      item.amountController.removeListener(_onAmountChanged);
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedCategoryId == null) return;

    // Validate items
    bool hasValidItems = false;
    List<Map<String, dynamic>> finalItems = [];
    double finalTotal = 0;

    for (var item in _items) {
      final name = item.nameController.text.trim();
      final amt = double.tryParse(item.amountController.text) ?? 0;
      if (name.isNotEmpty && amt > 0) {
        hasValidItems = true;
        finalItems.add({'name': name, 'amount': amt});
        finalTotal += amt;
      }
    }

    if (!hasValidItems || finalTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid item with an amount.')),
      );
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member to split the expense with.')),
      );
      return;
    }

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      String? imageUrl = _existingImageUrl;
      if (_receiptImage != null) {
        final bytes = await _receiptImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'base64:$base64String';
      }

      if (widget.expenseToEdit != null) {
        await roomService.updateRoomExpense(
          widget.room.id,
          widget.expenseToEdit!.id,
          title,
          finalTotal,
          widget.expenseToEdit!.paidById, // keep original payer
          _selectedMemberIds,
          _selectedCategoryId!,
          _selectedDate,
          imageUrl,
          finalItems,
        );
      } else {
        await roomService.addRoomExpense(
          widget.room.id,
          title,
          finalTotal,
          user.uid,
          _selectedMemberIds,
          _selectedCategoryId!,
          _selectedDate,
          imageUrl,
          finalItems,
        );
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
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
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlatShareAppBar(
        showBackButton: true,
        title: Text(
          widget.expenseToEdit == null ? 'Add Room Expense' : 'Edit Expense',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expense Title Input
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
                      child: Icon(Icons.title, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelText: 'Expense Title',
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          hintText: 'e.g., Weekend Groceries',
                          hintStyle: theme.textTheme.bodySmall,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Itemized Breakdown Section
              Text(
                'ITEMIZED BREAKDOWN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: item.nameController,
                                decoration: InputDecoration(
                                  labelText: 'Item Name',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  hintText: 'e.g., Milk',
                                  isDense: true,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: item.amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  hintText: '0.00',
                                  isDense: true,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_items.length > 1)
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                                onPressed: () => _removeItem(index),
                                padding: const EdgeInsets.only(bottom: 4, left: 8),
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount', style: theme.textTheme.titleSmall),
                          Text(
                            '₹${_totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Picker
              if (categories.isNotEmpty) ...[
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
              ],
              
              // Date picker box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Image Picker Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt / Proof',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_receiptImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _receiptImage != null 
                              ? Image.file(
                                  _receiptImage!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : (_existingImageUrl!.startsWith('base64:') 
                                  ? Image.memory(base64Decode(_existingImageUrl!.substring(7)), height: 120, width: double.infinity, fit: BoxFit.cover)
                                  : Image.network(_existingImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _receiptImage = null;
                                _existingImageUrl = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
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
              
              // Split members selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPLIT BETWEEN',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.room.memberIds.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      itemBuilder: (context, index) {
                        final uid = widget.room.memberIds[index];
                        final isSelected = _selectedMemberIds.contains(uid);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!_selectedMemberIds.contains(uid)) _selectedMemberIds.add(uid);
                              } else {
                                _selectedMemberIds.remove(uid);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              UserAvatar(uid: uid, radius: 14),
                              const SizedBox(width: 12),
                              Expanded(child: UserNameText(uid: uid, style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          controlAffinity: ListTileControlAffinity.trailing,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        );
                      },
                    ),
                  ),
                ],
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
                          widget.expenseToEdit == null ? 'Save Room Expense' : 'Update Expense',
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
    );
  }
}
