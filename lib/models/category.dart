import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final String color; // hex string

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseCategory(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  static List<ExpenseCategory> get defaultCategories => [
    ExpenseCategory(id: 'food', name: 'Food', icon: 'restaurant', color: '#F59E0B'),
    ExpenseCategory(id: 'travel', name: 'Travel', icon: 'directions_car', color: '#3B82F6'),
    ExpenseCategory(id: 'groceries', name: 'Groceries', icon: 'shopping_cart', color: '#10B981'),
    ExpenseCategory(id: 'clothes', name: 'Clothes', icon: 'checkroom', color: '#EC4899'),
    ExpenseCategory(id: 'utilities', name: 'Utilities', icon: 'bolt', color: '#8B5CF6'),
    ExpenseCategory(id: 'rent', name: 'Rent', icon: 'home', color: '#6366F1'),
    ExpenseCategory(id: 'entertainment', name: 'Entertainment', icon: 'movie', color: '#F43F5E'),
    ExpenseCategory(id: 'other', name: 'Other', icon: 'category', color: '#64748B'),
  ];
}
