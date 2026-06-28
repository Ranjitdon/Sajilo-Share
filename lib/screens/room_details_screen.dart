import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/room_expense.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/dues_provider.dart';
import '../widgets/flatshare_app_bar.dart';
import '../widgets/user_avatar_name.dart';
import '../utils/format_utils.dart';
import '../theme.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final Room room;
  const RoomDetailsScreen({super.key, required this.room});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  int _activeTab = 0; // 0: Expenses, 1: Dues, 2: Analytics, 3: Members
  int _expenseLimit = 15;
  int? _expandedExpenseIndex;
  DateTime? _filterMonth;

  String _getHeroImage(String roomName) {
    final lowerName = roomName.toLowerCase();
    if (lowerName.contains('beach')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80';
    } else if (lowerName.contains('loft') || lowerName.contains('old')) {
      return 'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&w=600&q=80';
    }
    return 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=600&q=80';
  }

  String _getRoomAddress(Room room) {
    if (room.location != null && room.location!.isNotEmpty) {
      return room.location!;
    }
    final lowerName = room.name.toLowerCase();
    if (lowerName.contains('beach')) {
      return 'Marine Drive, Sector 3';
    } else if (lowerName.contains('loft') || lowerName.contains('old')) {
      return 'Old Town Bazaar, Block B';
    }
    return 'Location not set';
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
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final expensesAsyncValue = ref.watch(roomExpensesProvider(widget.room.id));
    final duesAsyncValue = ref.watch(userDuesProvider);
    final categories = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: FlatShareAppBar(
        showBackButton: true,
        actions: [
          Builder(
            builder: (context) {
              final canDelete = user?.uid == widget.room.createdBy && widget.room.memberIds.length <= 1;
              if (!canDelete) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Room'),
                      content: const Text('Are you sure? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true), 
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref.read(roomServiceProvider).deleteRoom(widget.room.id);
                      if (context.mounted) {
                        context.pop(); // go back to rooms list
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(widget.room.name),
                    content: Text('Invite Code: ${widget.room.inviteCode}\nMembers: ${widget.room.memberIds.length}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: expensesAsyncValue.when(
        data: (expenses) {
          final availableMonths = expenses.map((e) => DateTime(e.createdAt.year, e.createdAt.month)).toSet().toList();
          availableMonths.sort((a, b) => b.compareTo(a));

          List<RoomExpense> filteredExpenses = expenses;
          if (_filterMonth != null) {
            filteredExpenses = expenses.where((e) => e.createdAt.year == _filterMonth!.year && e.createdAt.month == _filterMonth!.month).toList();
          }

          // Compute total spent and my balance
          double totalSpent = 0.0;
          for (var exp in filteredExpenses) {
            totalSpent += exp.amount;
          }

          double myBalance = 0.0;
          if (user != null && duesAsyncValue.hasValue) {
            final dues = duesAsyncValue.value ?? [];
            final roomDues = dues.where((d) => d.roomId == widget.room.id);
            for (final d in roomDues) {
              if (d.owedToId == user.uid) {
                myBalance += d.amount;
              } else if (d.owedById == user.uid) {
                myBalance -= d.amount;
              }
            }
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                // Room Hero Section
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _getHeroImage(widget.room.name),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.room.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  _getRoomAddress(widget.room),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Summary Stats Bento
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Spent',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${formatMoney(totalSpent)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: (myBalance >= 0
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.errorContainer)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Dues',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: myBalance >= 0
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              myBalance.abs() < 0.01 
                                  ? '₹0'
                                  : (myBalance > 0 
                                      ? '₹${formatMoney(myBalance.abs())}'
                                      : '-₹${formatMoney(myBalance.abs())}'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: myBalance >= 0
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Month Filter
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
                              _expandedExpenseIndex = null;
                              _expenseLimit = 15;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 48.0,
                    maxHeight: 48.0,
                    child: Container(
                      color: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTabButton(0, 'Expenses'),
                          const SizedBox(width: 8),
                          _buildTabButton(1, 'Dues'),
                          const SizedBox(width: 8),
                          _buildTabButton(2, 'Analytics'),
                          const SizedBox(width: 8),
                          _buildTabButton(3, 'Members'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: _buildActiveTabContent(filteredExpenses, categories, user?.uid, theme, duesAsyncValue.value ?? []),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_room_details',
        onPressed: () {
          context.push('/add-room-expense', extra: {'room': widget.room});
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

  Widget _buildTabButton(int index, String label) {
    final theme = Theme.of(context);
    final isActive = _activeTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(List<RoomExpense> expenses, List<ExpenseCategory> categories, String? myUid, ThemeData theme, List<Due> allDues) {
    if (_activeTab == 0) {
      // Expenses Tab
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: (expenses.length > _expenseLimit ? _expenseLimit + 1 : expenses.length),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _expenseLimit) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _expenseLimit += 15;
                      });
                    },
                    child: const Text('See more'),
                  );
                }
                final exp = expenses[index];
              final isMe = exp.paidById == myUid;
              
              final category = categories.firstWhere(
                (c) => c.id == exp.categoryId,
                orElse: () => ExpenseCategory.defaultCategories.last,
              );

              final catColor = _hexToColor(category.color);
              
              // Calculate user's specific debt statement
              String debtStatement = '';
              Color debtColor = theme.colorScheme.onSurfaceVariant;
              // allDues passed from arguments
              
              if (isMe) {
                double myShare = exp.splitBetweenIds.contains(myUid)
                    ? (exp.amount / exp.splitBetweenIds.length)
                    : 0.0;
                double owedToMe = exp.amount - myShare;
                if (owedToMe > 0) {
                  final stillOwedInRoom = allDues.where((d) => d.roomId == widget.room.id && d.owedToId == myUid).isNotEmpty;
                  if (stillOwedInRoom) {
                    debtStatement = 'Owed to you';
                    debtColor = theme.colorScheme.secondary;
                  } else {
                    debtStatement = 'Settled';
                    debtColor = theme.colorScheme.onSurfaceVariant;
                  }
                } else {
                  debtStatement = 'Personal';
                }
              } else {
                if (exp.splitBetweenIds.contains(myUid)) {
                  double share = exp.amount / exp.splitBetweenIds.length;
                  final stillOwesInRoom = allDues.where((d) => d.roomId == widget.room.id && d.owedById == myUid).isNotEmpty;
                  if (stillOwesInRoom) {
                    debtStatement = 'You owe ₹${formatMoney(share)}';
                    debtColor = theme.colorScheme.error;
                  } else {
                    debtStatement = 'Settled';
                    debtColor = theme.colorScheme.onSurfaceVariant;
                  }
                } else {
                  debtStatement = 'Not involved';
                }
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_expandedExpenseIndex == index) {
                      _expandedExpenseIndex = null;
                    } else {
                      _expandedExpenseIndex = index;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _expandedExpenseIndex == index
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getCategoryIcon(category.icon),
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
                                exp.description,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              isMe
                                  ? Text('Paid by You', style: theme.textTheme.bodySmall)
                                  : Row(
                                      children: [
                                        Text('Paid by ', style: theme.textTheme.bodySmall),
                                        Flexible(
                                          child: UserNameText(
                                            uid: exp.paidById,
                                            style: theme.textTheme.bodySmall,
                                            firstNameOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${formatMoney(exp.amount)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              debtStatement,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: debtColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Avatars stack
                          Row(
                            children: [
                              for (int i = 0; i < min(3, exp.splitBetweenIds.length); i++)
                                Align(
                                  widthFactor: 0.6,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              if (exp.splitBetweenIds.length > 3)
                                Align(
                                  widthFactor: 0.6,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                    child: Text(
                                      '+${exp.splitBetweenIds.length - 3}',
                                      style: TextStyle(
                                        fontSize: 7,
                                        color: theme.colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            DateFormat('MMM d, h:mm a').format(exp.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_expandedExpenseIndex == index) ...[
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Split Breakdown',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (exp.imageUrl != null && exp.imageUrl!.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    insetPadding: EdgeInsets.zero,
                                    backgroundColor: Colors.black,
                                    child: Stack(
                                      children: [
                                        InteractiveViewer(
                                          child: Center(
                                            child: exp.imageUrl!.startsWith('base64:') 
                                                ? Image.memory(base64Decode(exp.imageUrl!.substring(7)))
                                                : Image.network(exp.imageUrl!),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40,
                                          right: 20,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long, size: 14, color: theme.colorScheme.onPrimaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View Receipt',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (exp.items.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Items', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              ...exp.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name']?.toString() ?? '',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      Text(
                                        '₹${formatMoney(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}',
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('₹${formatMoney(exp.amount)}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!exp.splitBetweenIds.contains(exp.paidById)) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              UserAvatar(uid: exp.paidById, radius: 12),
                              const SizedBox(width: 8),
                              Expanded(child: UserNameText(uid: exp.paidById, style: theme.textTheme.bodySmall)),
                              Text(
                                'Paid ₹${formatMoney(exp.amount)} (Not in split)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ...exp.splitBetweenIds.map((uid) {
                        final isPayer = uid == exp.paidById;
                        final share = exp.amount / exp.splitBetweenIds.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              UserAvatar(uid: uid, radius: 12),
                              const SizedBox(width: 8),
                              Expanded(child: UserNameText(uid: uid, style: theme.textTheme.bodySmall)),
                              Text(
                                isPayer 
                                  ? 'Paid ₹${formatMoney(exp.amount)} (Share: ₹${formatMoney(share)})' 
                                  : 'Share: ₹${formatMoney(share)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isPayer ? theme.colorScheme.secondary : theme.colorScheme.error,
                                  fontWeight: isPayer ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (isMe) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                context.push('/add-room-expense', extra: {
                                  'room': widget.room,
                                  'expenseToEdit': exp,
                                });
                              },
                              icon: Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.primary),
                              label: Text('Edit Expense', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: () => _deleteExpense(context, ref, exp),
                              icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
                              label: Text('Delete Expense', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ]);
    } else if (_activeTab == 1) {
      // Dues Tab
      final duesAsync = ref.watch(userDuesProvider);
      return duesAsync.when(
        data: (allDues) {
          final roomDues = allDues.where((d) => d.roomId == widget.room.id).toList();
          
          if (roomDues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: theme.colorScheme.secondary),
                    const SizedBox(height: 16),
                    Text('All settled up in this room!', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.separated(
              itemCount: roomDues.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
              itemBuilder: (context, index) {
                final due = roomDues[index];
                final iOwe = due.owedById == myUid;
                final iAmOwed = due.owedToId == myUid;
                final involvesMe = iOwe || iAmOwed;
                final displayUid = involvesMe ? (iOwe ? due.owedToId : due.owedById) : due.owedById;

                Widget rowContent = Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      UserAvatar(uid: displayUid),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserNameText(
                              uid: displayUid,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (!involvesMe)
                              Row(
                                children: [
                                  Text('Owes ', style: theme.textTheme.bodySmall),
                                  UserNameText(uid: due.owedToId, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              )
                            else
                              Text('Room Expense Share', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${!involvesMe ? '' : (iOwe ? '-' : '+')}₹${formatMoney(due.amount)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: !involvesMe ? theme.colorScheme.primary : (iOwe ? theme.colorScheme.error : theme.colorScheme.secondary),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !involvesMe ? 'OWES' : (iOwe ? 'YOU OWE' : 'OWES YOU'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (involvesMe) {
                  return InkWell(
                    onTap: () {
                      context.push('/due-breakdown/${due.roomId}/$displayUid');
                    },
                    child: rowContent,
                  );
                }
                return rowContent;
              },
            ),
          );
        },
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
        error: (err, _) => Center(child: Text('Error: $err')),
      );
    } else if (_activeTab == 2) {
      // Analytics Tab - Inline Room Analytics
      if (expenses.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                Icon(Icons.analytics_outlined, size: 48, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'No expense data to analyze in this room.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 1. Calculate totals
      double totalRoomSpend = 0.0;
      final Map<String, double> categoryTotals = {};
      final Map<String, double> memberTotals = {};

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);

      double thisMonthSum = 0;
      double lastMonthSum = 0;

      // Group expenses by month dynamically (last 6 months)
      final List<DateTime> last6Months = List.generate(6, (i) {
        return DateTime(now.year, now.month - (5 - i), 1);
      });
      final Map<int, double> monthlySums = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      bool hasTrendData = false;

      for (final exp in expenses) {
        totalRoomSpend += exp.amount;
        categoryTotals[exp.categoryId] = (categoryTotals[exp.categoryId] ?? 0.0) + exp.amount;
        memberTotals[exp.paidById] = (memberTotals[exp.paidById] ?? 0.0) + exp.amount;

        // Sum this month vs last month
        if (exp.createdAt.isAfter(thisMonthStart.subtract(const Duration(seconds: 1)))) {
          thisMonthSum += exp.amount;
        } else if (exp.createdAt.isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) && exp.createdAt.isBefore(thisMonthStart)) {
          lastMonthSum += exp.amount;
        }

        // Sum for monthly trend
        for (int i = 0; i < 6; i++) {
          final mStart = last6Months[i];
          final mEnd = i < 5 ? last6Months[i + 1] : DateTime(now.year, now.month + 1, 1);
          if (exp.createdAt.isAfter(mStart.subtract(const Duration(seconds: 1))) && exp.createdAt.isBefore(mEnd)) {
            monthlySums[i] = (monthlySums[i] ?? 0.0) + exp.amount;
            if (exp.amount > 0) hasTrendData = true;
          }
        }
      }

      // 2. Who Paid How Much (Bar Chart calculation)
      double maxPaid = 1.0;
      for (final val in memberTotals.values) {
        if (val > maxPaid) maxPaid = val;
      }

      // 3. Trend Calculations
      String trendText = 'Trend data not available';
      IconData trendIcon = Icons.trending_flat;
      Color trendColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

      if (lastMonthSum > 0) {
        final diff = ((thisMonthSum - lastMonthSum) / lastMonthSum) * 100;
        if (diff > 0.01) {
          trendText = '${diff.toStringAsFixed(0)}% more than last month';
          trendIcon = Icons.trending_up;
          trendColor = theme.colorScheme.error;
        } else if (diff < -0.01) {
          trendText = '${diff.abs().toStringAsFixed(0)}% less than last month';
          trendIcon = Icons.trending_down;
          trendColor = theme.colorScheme.secondary;
        } else {
          trendText = 'Equal to last month';
          trendIcon = Icons.trending_flat;
          trendColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        }
      }

      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Summary Spent Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL ROOM SPEND',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${formatMoney(totalRoomSpend)}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_filterMonth == null) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      Icon(trendIcon, size: 14, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        trendText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 10,
                          color: trendColor,
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
          // Who Paid How Much Bar Chart Card
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
                  'Who Paid How Much',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Draw Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: widget.room.memberIds.map((memberId) {
                    final paid = memberTotals[memberId] ?? 0.0;
                    final barHeight = (paid / maxPaid) * 100.0;

                    return Column(
                      children: [
                        Text(
                          '₹${formatMoney(paid / 1000)}k',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: barHeight < 12.0 ? 12.0 : barHeight,
                          decoration: BoxDecoration(
                            color: paid > 0.0
                                ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        memberId == myUid
                            ? Text(
                                'You',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : UserNameText(
                                uid: memberId,
                                firstNameOnly: true,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Spending Trend Line Chart Card
          if (_filterMonth == null) ...[
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
                  'Monthly Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                hasTrendData
                    ? SizedBox(
                        height: 120,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(6, (i) => FlSpot(i.toDouble(), monthlySums[i]!)),
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            'Trend data not available.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final monthName = DateFormat('MMM').format(last6Months[i]);
                    return Text(
                      monthName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ],
          // Breakdown by Category Spending Progress Card
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
                  'Category Spending',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    final percentage = amount / totalRoomSpend;

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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(category.icon),
                                color: catColor,
                                size: 18,
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
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(0)}% of total',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${formatMoney(amount)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
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
                            minHeight: 4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ));
    } else {
      // Members Tab
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            'Room Members (${widget.room.memberIds.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.room.memberIds.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
              itemBuilder: (context, index) {
                final memId = widget.room.memberIds[index];
                final isCreator = memId == widget.room.createdBy;
                return ListTile(
                  leading: UserAvatar(uid: memId),
                  title: memId == myUid 
                    ? const Text('You (Roommate)', style: TextStyle(fontWeight: FontWeight.bold))
                    : UserNameText(uid: memId, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isCreator ? 'Owner / Creator' : 'Member'),
                  trailing: isCreator ? Icon(Icons.star, color: theme.colorScheme.secondary) : null,
                );
              },
            ),
          ),
        ],
      ));
    }
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, RoomExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense? This action cannot be undone and will affect everyone\'s balances in the room.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .collection('expenses')
            .doc(expense.id)
            .delete();
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense: $e')),
          );
        }
      }
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
