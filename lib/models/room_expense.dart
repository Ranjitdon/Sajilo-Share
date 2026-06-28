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
  final List<Map<String, dynamic>> items;

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
    this.items = const [],
    this.imageUrl,
  });

  factory RoomExpense.fromMap(Map<String, dynamic> map, String id) {
    List<Map<String, dynamic>> parsedItems = [];
    if (map['items'] != null) {
      parsedItems = List<Map<String, dynamic>>.from(
          (map['items'] as List).map((e) => Map<String, dynamic>.from(e)));
    }

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
      items: parsedItems,
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
      'items': items,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
