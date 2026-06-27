import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';

import 'room_provider.dart';

final _rawPersonalExpensesProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('personalExpenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Expense.fromMap(doc.data(), doc.id))
          .toList());
});

final personalExpensesProvider = Provider.autoDispose<AsyncValue<List<Expense>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const AsyncValue.data([]);

  final personalAsync = ref.watch(_rawPersonalExpensesProvider);
  final roomsAsync = ref.watch(userRoomsProvider);

  if (personalAsync.isLoading || roomsAsync.isLoading) return const AsyncValue.loading();
  if (personalAsync.hasError) return AsyncValue.error(personalAsync.error!, personalAsync.stackTrace!);
  if (roomsAsync.hasError) return AsyncValue.error(roomsAsync.error!, roomsAsync.stackTrace!);

  final personalExpenses = personalAsync.value ?? [];
  final rooms = roomsAsync.value ?? [];

  List<Expense> allExpenses = [...personalExpenses];

  for (var room in rooms) {
    final roomExpAsync = ref.watch(roomExpensesProvider(room.id));
    if (roomExpAsync.isLoading) return const AsyncValue.loading();
    if (roomExpAsync.hasError) return AsyncValue.error(roomExpAsync.error!, roomExpAsync.stackTrace!);

    final roomExpenses = roomExpAsync.value ?? [];
    for (var re in roomExpenses) {
      if (re.splitBetweenIds.contains(user.uid)) {
        allExpenses.add(Expense(
          id: re.id,
          amount: re.amount / re.splitBetweenIds.length,
          categoryId: re.categoryId,
          note: re.description,
          date: re.createdAt,
          createdAt: re.createdAt,
          roomId: re.roomId,
        ));
      }
    }
  }

  allExpenses.sort((a, b) => b.date.compareTo(a.date));
  return AsyncValue.data(allExpenses);
});

final customCategoriesProvider = StreamProvider.autoDispose<List<ExpenseCategory>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('personalCategories')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ExpenseCategory.fromMap(doc.data(), doc.id))
          .toList());
});

final allCategoriesProvider = Provider.autoDispose<List<ExpenseCategory>>((ref) {
  final customCategories = ref.watch(customCategoriesProvider).value ?? [];
  return [...ExpenseCategory.defaultCategories, ...customCategories];
});

class ExpenseController {
  final String uid;

  ExpenseController(this.uid);

  Future<void> addPersonalExpense(Expense expense) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('personalExpenses')
        .add(expense.toMap());
  }

  Future<void> addCustomCategory(ExpenseCategory category) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('personalCategories')
        .add(category.toMap());
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('personalCategories')
        .doc(categoryId)
        .delete();
  }
}

final expenseControllerProvider = Provider.autoDispose<ExpenseController?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return null;
  return ExpenseController(user.uid);
});
