import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/dues_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';
import 'dart:math';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final roomsAsyncValue = ref.watch(userRoomsProvider);
    final duesAsyncValue = ref.watch(userDuesProvider);

    IconData getRoomIcon(String iconName) {
      switch (iconName) {
        case 'home': return Icons.home;
        case 'apartment': return Icons.apartment;
        case 'cottage': return Icons.cottage;
        case 'weekend': return Icons.weekend;
        case 'domain': return Icons.domain;
        case 'bed': return Icons.bed;
        case 'kitchen': return Icons.kitchen;
        case 'deck': return Icons.deck;
        default: return Icons.home;
      }
    }

    Color hexToColor(String hexString) {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }

    return Scaffold(
      appBar: const FlatShareAppBar(),
      body: roomsAsyncValue.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 80,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'You are not in any rooms yet.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new room or join an existing one using an invite code.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.push('/create-room'),
                        child: const Text('Create a Room'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.push('/join-room'),
                        child: const Text('Join a Room'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section with Join Room
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME BACK',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Shared Spaces',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/join-room'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        'Join Room',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Room Cards List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    
                    // Assign icon and bg dynamically from room model fields
                    final iconData = getRoomIcon(room.icon);
                    final iconBg = hexToColor(room.color);

                    // Dues status badge calculation
                    Widget statusBadge = const SizedBox();
                    if (duesAsyncValue.hasValue) {
                      final dues = duesAsyncValue.value ?? [];
                      final roomDues = dues.where((d) => d.roomId == room.id);
                      
                      double netBalance = 0.0;
                      for (final d in roomDues) {
                        if (d.owedToId == user?.uid) {
                          netBalance += d.amount;
                        } else if (d.owedById == user?.uid) {
                          netBalance -= d.amount;
                        }
                      }

                      if (netBalance > 0.01) {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up, size: 14, color: theme.colorScheme.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '₹${formatMoney(netBalance)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (netBalance < -0.01) {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_down, size: 14, color: theme.colorScheme.onErrorContainer),
                              const SizedBox(width: 4),
                              Text(
                                '-₹${formatMoney(netBalance.abs())}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.done_all, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '₹0',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    // Watch last activity in room
                    final expensesAsync = ref.watch(roomExpensesProvider(room.id));
                    Widget historyWidget = const SizedBox();
                    if (expensesAsync.hasValue) {
                      final expenses = expensesAsync.value ?? [];
                      if (expenses.isNotEmpty) {
                        final lastExp = expenses.first;
                        final isMe = lastExp.paidById == user?.uid;
                        historyWidget = Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.only(top: 12.0),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: isMe ? 'You' : 'Someone',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ' added ${lastExp.description}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        historyWidget = Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.only(top: 12.0),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  'Room created. No expenses added yet.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push('/room-details', extra: room);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Avatars list representation
                                        Row(
                                          children: [
                                            for (int i = 0; i < min(3, room.memberIds.length); i++)
                                              Align(
                                                widthFactor: 0.6,
                                                child: CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: theme.colorScheme.primaryContainer,
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            if (room.memberIds.length > 3)
                                              Align(
                                                widthFactor: 0.6,
                                                child: CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                                  child: Text(
                                                    '+${room.memberIds.length - 3}',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: theme.colorScheme.onSecondaryContainer,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  statusBadge,
                                ],
                              ),
                              historyWidget,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100), // Spacing for FAB
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_rooms',
        onPressed: () {
          // Show bottom sheet to either Join or Create room
          _showAddRoomOptions(context);
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

  void _showAddRoomOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.surfaceContainerLowest,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_business, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    'Create a New Room',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Start a new flat group'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/create-room');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group_add, color: theme.colorScheme.secondary),
                  ),
                  title: Text(
                    'Join an Existing Room',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Enter an invite code'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/join-room');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
