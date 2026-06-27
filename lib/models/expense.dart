import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final String? receiptUrl;
  final DateTime createdAt;
  
  // For room expenses
  final String? roomId;
  final String? paidBy;
  final List<String>? participantIds;
  final Map<String, double>? splitShare;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    this.receiptUrl,
    required this.createdAt,
    this.roomId,
    this.paidBy,
    this.participantIds,
    this.splitShare,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? 'other',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptUrl: data['receiptUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roomId: data['roomId'],
      paidBy: data['paidBy'],
      participantIds: data['participantIds'] != null ? List<String>.from(data['participantIds']) : null,
      splitShare: data['splitShare'] != null ? Map<String, double>.from(data['splitShare'].map((k, v) => MapEntry(k, (v as num).toDouble()))) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': Timestamp.fromDate(date),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (roomId != null) 'roomId': roomId,
      if (paidBy != null) 'paidBy': paidBy,
      if (participantIds != null) 'participantIds': participantIds,
      if (splitShare != null) 'splitShare': splitShare,
    };
  }
}
