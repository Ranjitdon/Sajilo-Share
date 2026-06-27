import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;
  final String createdBy;
  final String icon;
  final String color;
  final String? location;

  Room({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
    required this.createdBy,
    this.icon = 'home',
    this.color = '#4648d4',
    this.location,
  });

  factory Room.fromMap(Map<String, dynamic> map, String id) {
    return Room(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Room',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      icon: map['icon'] as String? ?? 'home',
      color: map['color'] as String? ?? '#4648d4',
      location: map['location'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'icon': icon,
      'color': color,
      if (location != null) 'location': location,
    };
  }
}
