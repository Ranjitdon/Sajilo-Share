import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import 'room_provider.dart';

class Due {
  final String owedToId; // Who receives the money
  final String owedById; // Who owes the money
  final double amount;
  final String roomId;
  final String roomName;

  Due({
    required this.owedToId,
    required this.owedById,
    required this.amount,
    required this.roomId,
    required this.roomName,
  });
}

final roomSettlementsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('settlements')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final userDuesProvider = Provider.autoDispose<AsyncValue<List<Due>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const AsyncValue.data([]);

  final roomsAsync = ref.watch(userRoomsProvider);
  
  return roomsAsync.when(
    data: (rooms) {
      if (rooms.isEmpty) return const AsyncValue.data([]);

      List<Due> allDues = [];
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

        // Calculate net balances for this room
        Map<String, double> balances = {};

        // 1. Process Expenses
        for (final exp in expenses) {
          if (exp.splitBetweenIds.isEmpty) continue;
          
          double splitAmount = exp.amount / exp.splitBetweenIds.length;
          
          balances[exp.paidById] = (balances[exp.paidById] ?? 0) + exp.amount;
          for (final splitId in exp.splitBetweenIds) {
            balances[splitId] = (balances[splitId] ?? 0) - splitAmount;
          }
        }

        // 2. Process Settlements
        for (final stl in settlements) {
          final status = stl['status'] as String?;
          if (status != 'confirmed') continue; // Only confirmed settlements affect balances

          final fromUid = stl['fromUid'] as String?;
          final toUid = stl['toUid'] as String?;
          final amount = (stl['amount'] ?? 0.0) as num;
          
          if (fromUid != null && toUid != null) {
            balances[fromUid] = (balances[fromUid] ?? 0) + amount.toDouble();
            balances[toUid] = (balances[toUid] ?? 0) - amount.toDouble();
          }
        }

        // 3. Resolve Debt Graph (Greedy Algorithm)
        List<MapEntry<String, double>> debtors = [];
        List<MapEntry<String, double>> creditors = [];

        balances.forEach((uid, balance) {
          if (balance < -0.01) {
            debtors.add(MapEntry(uid, balance.abs()));
          } else if (balance > 0.01) {
            creditors.add(MapEntry(uid, balance));
          }
        });

        debtors.sort((a, b) => b.value.compareTo(a.value));
        creditors.sort((a, b) => b.value.compareTo(a.value));

        int i = 0;
        int j = 0;

        while (i < debtors.length && j < creditors.length) {
          final debtorId = debtors[i].key;
          final creditorId = creditors[j].key;
          
          final amount = debtors[i].value < creditors[j].value ? debtors[i].value : creditors[j].value;
          
          // Only add to list if it involves the current user
          if (debtorId == user.uid || creditorId == user.uid) {
            allDues.add(Due(
              owedToId: creditorId,
              owedById: debtorId,
              amount: amount,
              roomId: room.id,
              roomName: room.name,
            ));
          }

          debtors[i] = MapEntry(debtorId, debtors[i].value - amount);
          creditors[j] = MapEntry(creditorId, creditors[j].value - amount);

          if (debtors[i].value < 0.01) i++;
          if (creditors[j].value < 0.01) j++;
        }
      }

      if (isLoading && allDues.isEmpty) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(allDues);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// A provider to aggregate all pending settlements for the current user
final pendingSettlementsProvider = Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const AsyncValue.data([]);

  final roomsAsync = ref.watch(userRoomsProvider);
  
  return roomsAsync.when(
    data: (rooms) {
      if (rooms.isEmpty) return const AsyncValue.data([]);

      List<Map<String, dynamic>> allPending = [];
      bool isLoading = false;

      for (final room in rooms) {
        final settlementsAsync = ref.watch(roomSettlementsProvider(room.id));
        
        if (settlementsAsync is AsyncLoading) {
          isLoading = true;
          continue;
        }

        final settlements = settlementsAsync.value ?? [];
        for (final stl in settlements) {
          final status = stl['status'] as String?;
          if (status == 'pending') {
            final fromUid = stl['fromUid'] as String?;
            final toUid = stl['toUid'] as String?;
            if (fromUid == user.uid || toUid == user.uid) {
              allPending.add({
                ...stl,
                'roomId': room.id,
                'roomName': room.name,
              });
            }
          }
        }
      }

      if (isLoading && allPending.isEmpty) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(allPending);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final roomAllDuesProvider = Provider.family.autoDispose<AsyncValue<List<Due>>, String>((ref, roomId) {
  final expensesAsync = ref.watch(roomExpensesProvider(roomId));
  final settlementsAsync = ref.watch(roomSettlementsProvider(roomId));
  
  if (expensesAsync is AsyncLoading || settlementsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  if (settlementsAsync.hasError) return AsyncValue.error(settlementsAsync.error!, settlementsAsync.stackTrace!);
  
  final expenses = expensesAsync.value ?? [];
  final settlements = settlementsAsync.value ?? [];

  Map<String, double> balances = {};

  for (final exp in expenses) {
    if (exp.splitBetweenIds.isEmpty) continue;
    double splitAmount = exp.amount / exp.splitBetweenIds.length;
    balances[exp.paidById] = (balances[exp.paidById] ?? 0) + exp.amount;
    for (final splitId in exp.splitBetweenIds) {
      balances[splitId] = (balances[splitId] ?? 0) - splitAmount;
    }
  }

  for (final stl in settlements) {
    final status = stl['status'] as String?;
    if (status != 'confirmed') continue;
    final fromUid = stl['fromUid'] as String?;
    final toUid = stl['toUid'] as String?;
    final amount = (stl['amount'] ?? 0.0) as num;
    if (fromUid != null && toUid != null) {
      balances[fromUid] = (balances[fromUid] ?? 0) + amount.toDouble();
      balances[toUid] = (balances[toUid] ?? 0) - amount.toDouble();
    }
  }

  List<MapEntry<String, double>> debtors = [];
  List<MapEntry<String, double>> creditors = [];

  balances.forEach((uid, balance) {
    if (balance < -0.01) {
      debtors.add(MapEntry(uid, balance.abs()));
    } else if (balance > 0.01) {
      creditors.add(MapEntry(uid, balance));
    }
  });

  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  List<Due> allDues = [];
  int i = 0;
  int j = 0;

  while (i < debtors.length && j < creditors.length) {
    final debtorId = debtors[i].key;
    final creditorId = creditors[j].key;
    final amount = debtors[i].value < creditors[j].value ? debtors[i].value : creditors[j].value;
    
    allDues.add(Due(
      owedToId: creditorId,
      owedById: debtorId,
      amount: amount,
      roomId: roomId,
      roomName: '',
    ));

    debtors[i] = MapEntry(debtorId, debtors[i].value - amount);
    creditors[j] = MapEntry(creditorId, creditors[j].value - amount);

    if (debtors[i].value < 0.01) i++;
    if (creditors[j].value < 0.01) j++;
  }

  return AsyncValue.data(allDues);
});
