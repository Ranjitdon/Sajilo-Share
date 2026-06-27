import 'package:cloud_firestore/cloud_firestore.dart';

class RoomExpense {
  final String id;
  final String roomId;
  final String description;
  final double amount;
  final String paidById;
  final List<String> splitBetweenIds;
  final DateTime createdAt;
  final String createdBy;
  final String categoryId;

  final String? imageUrl;

  RoomExpense({
    required this.id,
    required this.roomId,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.splitBetweenIds,
    required this.createdAt,
    required this.createdBy,
    this.categoryId = 'others',
    this.imageUrl,
  });

  factory RoomExpense.fromMap(Map<String, dynamic> map, String id) {
    return RoomExpense(
      id: id,
      roomId: map['roomId'] ?? '',
      description: map['description'] ?? 'Untitled',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paidById: map['paidById'] ?? '',
      splitBetweenIds: List<String>.from(map['splitBetweenIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      categoryId: map['categoryId'] ?? 'others',
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'splitBetweenIds': splitBetweenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'categoryId': categoryId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
