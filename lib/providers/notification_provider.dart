import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format_utils.dart';
import 'auth_provider.dart';
import 'room_provider.dart';
import 'dues_provider.dart';
import 'user_provider.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  final IconData icon;
  final String roomId;
  final String? settlementId;
  final bool isActionable;

  AppNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.icon,
    required this.roomId,
    this.settlementId,
    this.isActionable = false,
  });
}


final notificationsProvider = Provider.autoDispose<AsyncValue<List<AppNotification>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const AsyncValue.data([]);

  final roomsAsync = ref.watch(userRoomsProvider);
  return roomsAsync.when(
    data: (rooms) {
      if (rooms.isEmpty) return const AsyncValue.data([]);

      List<AppNotification> allNotifications = [];
      bool isLoading = false;

      for (final room in rooms) {
        final expensesAsync = ref.watch(roomExpensesProvider(room.id));
        final settlementsAsync = ref.watch(roomSettlementsProvider(room.id));

        if (expensesAsync is AsyncLoading || settlementsAsync is AsyncLoading) {
          isLoading = true;
          continue;
        }

        final expenses = expensesAsync.value ?? [];
        final settlements = settlementsAsync.value ?? [];

        // Map expenses to notifications
        for (final exp in expenses) {
          String payerName = 'Someone';
          if (exp.paidById == user.uid) {
            payerName = 'You';
          } else {
            final userAsync = ref.watch(userProfileProvider(exp.paidById));
            if (userAsync.hasValue && userAsync.value != null && userAsync.value!.displayName.isNotEmpty) {
              payerName = userAsync.value!.displayName;
            }
          }
          
          allNotifications.add(AppNotification(
            title: 'New Expense in ${room.name}',
            body: '$payerName added "${exp.description}" of ₹${formatMoney(exp.amount)}.',
            timestamp: exp.createdAt,
            icon: Icons.receipt_long,
            roomId: room.id,
          ));
        }

        // Map settlements to notifications
        for (final stl in settlements) {
          final fromUid = stl['fromUid'] as String?;
          final toUid = stl['toUid'] as String?;
          final settlementId = stl['id'] as String?;
          if (fromUid == null || toUid == null || settlementId == null) continue;

          String fromName = 'Someone';
          if (fromUid == user.uid) {
            fromName = 'You';
          } else {
            final fromUserAsync = ref.watch(userProfileProvider(fromUid));
            if (fromUserAsync.hasValue && fromUserAsync.value != null && fromUserAsync.value!.displayName.isNotEmpty) {
              fromName = fromUserAsync.value!.displayName;
            }
          }

          String toName = 'someone';
          if (toUid == user.uid) {
            toName = 'you';
          } else {
            final toUserAsync = ref.watch(userProfileProvider(toUid));
            if (toUserAsync.hasValue && toUserAsync.value != null && toUserAsync.value!.displayName.isNotEmpty) {
              toName = toUserAsync.value!.displayName;
            }
          }
          final amount = (stl['amount'] ?? 0.0) as num;
          final status = stl['status'] as String? ?? 'pending';
          final createdAt = stl['createdAt'] != null ? (stl['createdAt'] as dynamic).toDate() : DateTime.now();

          // Only notify if involving this user
          if (fromUid == user.uid || toUid == user.uid) {
            final isActionable = (status == 'pending' && toUid == user.uid);
            allNotifications.add(AppNotification(
              title: status == 'pending'
                  ? (isActionable ? 'Payment Received (Pending Approval)' : 'Payment Sent (Pending Approval)')
                  : 'Settlement Confirmed',
              body: '$fromName paid $toName ₹${formatMoney(amount)}.',
              timestamp: createdAt,
              icon: Icons.handshake,
              roomId: room.id,
              settlementId: settlementId,
              isActionable: isActionable,
            ));
          }
        }
      }

      // Sort descending by timestamp
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (isLoading && allNotifications.isEmpty) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(allNotifications);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  final prefsAsync = ref.watch(sharedPrefsProvider);
  
  if (!notifsAsync.hasValue || !prefsAsync.hasValue) return false;
  final notifs = notifsAsync.value!;
  if (notifs.isEmpty) return false;
  
  final prefs = prefsAsync.value!;
  final lastViewedTimestamp = prefs.getInt('last_notification_view_time') ?? 0;
  
  for (final notif in notifs) {
    if (notif.timestamp.millisecondsSinceEpoch > lastViewedTimestamp) {
      return true;
    }
  }
  return false;
});

final markNotificationsAsReadProvider = Provider((ref) {
  return () async {
    final prefsAsync = ref.read(sharedPrefsProvider);
    if (prefsAsync.hasValue) {
      final prefs = prefsAsync.value!;
      await prefs.setInt('last_notification_view_time', DateTime.now().millisecondsSinceEpoch);
      ref.invalidate(sharedPrefsProvider);
    }
  };
});
