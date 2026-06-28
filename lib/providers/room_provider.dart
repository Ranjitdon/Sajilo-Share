import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import '../models/room_expense.dart';
import 'auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService(FirebaseFirestore.instance);
});

// Stream of all rooms the user is a member of
final userRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('rooms')
      .where('memberIds', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        final rooms = snapshot.docs.map((doc) => Room.fromMap(doc.data(), doc.id)).toList();
        rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return rooms;
      });
});

class RoomService {
  final FirebaseFirestore _db;

  RoomService(this._db);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> createRoom(String name, String creatorUid, {String icon = 'home', String color = '#4648d4', String? location}) async {
    final inviteCode = _generateInviteCode();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final newRoom = Room(
      id: '',
      name: name,
      inviteCode: inviteCode,
      memberIds: [user.uid],
      createdAt: DateTime.now(),
      createdBy: user.uid,
      icon: icon,
      color: color,
      location: location,
    );

    final docRef = await _db.collection('rooms').add(newRoom.toMap());
    
    // Optional: create an 'invites' mapping collection to easily look up room by code
    await _db.collection('invites').doc(inviteCode).set({
      'roomId': docRef.id,
      'createdBy': user.uid,
    });
  }

  Future<void> joinRoom(String inviteCode, String uid) async {
    // Lookup the room by invite code
    final inviteDoc = await _db.collection('invites').doc(inviteCode).get();
    
    if (!inviteDoc.exists) {
      throw Exception('Invalid invite code');
    }
    
    final roomId = inviteDoc.data()?['roomId'] as String;
    
    // Add user to the room's memberIds
    await _db.collection('rooms').doc(roomId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> deleteRoom(String roomId) async {
    // Note: This only deletes the room document itself.
    // In a production app with subcollections (expenses, settlements), you would either 
    // need a Cloud Function to recursively delete them, or delete them client-side first.
    // For MVP, we'll just delete the room document.
    await _db.collection('rooms').doc(roomId).delete();
  }

  Future<void> addRoomExpense(String roomId, String description, double amount, String paidById, List<String> splitBetweenIds, [String categoryId = 'others', DateTime? date, String? imageUrl, List<Map<String, dynamic>> items = const []]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final expense = RoomExpense(
      id: '',
      roomId: roomId,
      description: description,
      amount: amount,
      paidById: paidById,
      splitBetweenIds: splitBetweenIds,
      createdAt: date ?? DateTime.now(),
      createdBy: user.uid,
      categoryId: categoryId,
      imageUrl: imageUrl,
      items: items,
    );
    await _db.collection('rooms').doc(roomId).collection('expenses').add(expense.toMap());
  }

  Future<void> updateRoomExpense(String roomId, String expenseId, String description, double amount, String paidById, List<String> splitBetweenIds, [String categoryId = 'others', DateTime? date, String? imageUrl, List<Map<String, dynamic>> items = const []]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final updates = {
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'splitBetweenIds': splitBetweenIds,
      'categoryId': categoryId,
      'items': items,
    };
    if (date != null) updates['createdAt'] = Timestamp.fromDate(date);
    if (imageUrl != null) updates['imageUrl'] = imageUrl;

    await _db.collection('rooms').doc(roomId).collection('expenses').doc(expenseId).update(updates);
  }
}

// Stream of expenses for a specific room
final roomExpensesProvider = StreamProvider.family<List<RoomExpense>, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('expenses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => RoomExpense.fromMap(doc.data(), doc.id)).toList());
});
