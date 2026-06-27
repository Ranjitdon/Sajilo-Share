import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/dues_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';
import '../widgets/user_avatar_name.dart';
import '../utils/format_utils.dart';

class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key});

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  String? _selectedRoomName;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);
    final duesAsync = ref.watch(userDuesProvider);
    final pendingAsync = ref.watch(pendingSettlementsProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: const FlatShareAppBar(),
      body: duesAsync.when(
        data: (dues) {
          final pendingSettlements = pendingAsync.value ?? [];
          
          if (dues.isEmpty && pendingSettlements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline, size: 48, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'You are all settled up!',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not owe anyone, and nobody owes you.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          double totalOwedToMe = 0;
          double totalIOwe = 0;

          for (final due in dues) {
            if (due.owedToId == user?.uid) {
              totalOwedToMe += due.amount;
            } else if (due.owedById == user?.uid) {
              totalIOwe += due.amount;
            }
          }

          final netBalance = totalOwedToMe - totalIOwe;

          // Group dues by Room
          final Map<String, List<Due>> duesByRoom = {};
          for (final due in dues) {
            duesByRoom.putIfAbsent(due.roomId, () => []).add(due);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Banner Section
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
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
                            'NET BALANCE',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${formatMoney(netBalance.abs())}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: theme.colorScheme.secondaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                netBalance >= 0
                                    ? 'Overall, you are owed ₹${formatMoney(netBalance)}'
                                    : 'Overall, you owe ₹${formatMoney(netBalance.abs())}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Room Filter Quick Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedRoomName = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoomName == null
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'All Rooms',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _selectedRoomName == null
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: _selectedRoomName == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final roomName in duesByRoom.values.map((list) => list.first.roomName).toSet()) ...[
                        GestureDetector(
                          onTap: () => setState(() => _selectedRoomName = roomName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedRoomName == roomName
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              roomName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _selectedRoomName == roomName
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _selectedRoomName == roomName ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Pending Approvals Section
                if (pendingSettlements.isNotEmpty) ...[
                  Text(
                    'Pending Approvals',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingSettlements.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2)),
                      itemBuilder: (context, index) {
                        final stl = pendingSettlements[index];
                        final isReceiver = stl['toUid'] == user?.uid;
                        final amount = stl['amount'] as num;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(Icons.pending_actions, color: theme.colorScheme.onSecondaryContainer),
                          ),
                          title: Text(
                            isReceiver ? 'Someone paid you ₹${formatMoney(amount)}' : 'You paid ₹${formatMoney(amount)}',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isReceiver ? 'Waiting for your approval' : 'Waiting for their approval',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: isReceiver
                              ? TextButton(
                                  onPressed: () => _approveSettlement(context, stl['roomId'], stl['id']),
                                  style: TextButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Approve'),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Room Group Dues List
                Builder(
                  builder: (context) {
                    final filteredRooms = duesByRoom.keys
                        .where((roomId) => _selectedRoomName == null || duesByRoom[roomId]!.first.roomName == _selectedRoomName)
                        .toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final roomId = filteredRooms[index];
                        final roomDues = duesByRoom[roomId]!;
                        final roomName = roomDues.first.roomName;

                    // Calculate net balance for this room
                    double roomNetBalance = 0.0;
                    for (final d in roomDues) {
                      if (d.owedToId == user?.uid) {
                        roomNetBalance += d.amount;
                      } else if (d.owedById == user?.uid) {
                        roomNetBalance -= d.amount;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Room Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.apartment, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  roomName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (roomNetBalance >= 0
                                        ? theme.colorScheme.secondaryContainer
                                        : theme.colorScheme.errorContainer)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${roomNetBalance >= 0 ? '+' : '-'}₹${formatMoney(roomNetBalance.abs())}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: roomNetBalance >= 0
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Room Dues Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: roomDues.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (context, itemIndex) {
                              final due = roomDues[itemIndex];
                              final iOwe = due.owedById == user?.uid;
                              final otherUserId = iOwe ? due.owedToId : due.owedById;
                              final categoryDetail = 'Room Expense Share';

                              return InkWell(
                                onTap: () {
                                  context.push('/room/${due.roomId}/due-breakdown/$otherUserId');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                  children: [
                                    UserAvatar(uid: otherUserId),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          UserNameText(
                                            uid: otherUserId,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            categoryDetail,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${iOwe ? '-' : '+'}₹${formatMoney(due.amount)}',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: iOwe ? theme.colorScheme.error : theme.colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          iOwe ? 'YOU OWE' : 'OWES YOU',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }


  Future<void> _approveSettlement(BuildContext context, String roomId, String settlementId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('settlements')
          .doc(settlementId)
          .update({
        'status': 'confirmed',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement approved!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }
}
