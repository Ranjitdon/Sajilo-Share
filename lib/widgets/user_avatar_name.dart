import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';

class UserNameText extends ConsumerWidget {
  final String uid;
  final TextStyle? style;
  final String fallback;
  final bool firstNameOnly;

  const UserNameText({super.key, required this.uid, this.style, this.fallback = 'Loading...', this.firstNameOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(uid));
    
    return userAsync.when(
      data: (user) {
        String name = user?.displayName ?? '';
        if (name.trim().isEmpty && uid == FirebaseAuth.instance.currentUser?.uid) {
          name = FirebaseAuth.instance.currentUser?.displayName ?? '';
        }
        if (name.trim().isEmpty) {
          name = 'Unknown User';
        }
        if (firstNameOnly && name.contains(' ')) {
          name = name.split(' ')[0];
        }
        return Text(name, style: style);
      },
      loading: () => Text(fallback, style: style),
      error: (_, __) => Text('Error', style: style),
    );
  }
}

class UserAvatar extends ConsumerWidget {
  final String uid;
  final double radius;

  const UserAvatar({super.key, required this.uid, this.radius = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(uid));
    final theme = Theme.of(context);
    
    return userAsync.when(
      data: (user) {
        if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: user.photoUrl!.startsWith('base64:')
                ? MemoryImage(base64Decode(user.photoUrl!.substring(7)))
                : NetworkImage(user.photoUrl!) as ImageProvider,
            onBackgroundImageError: (e, s) {
              // Suppress the error if the network image fails to load
            },
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: Icon(Icons.person, color: theme.colorScheme.primary, size: radius * 1.2),
        );
      },
      loading: () => CircleAvatar(radius: radius, backgroundColor: Colors.grey[300]),
      error: (_, __) => CircleAvatar(radius: radius, child: const Icon(Icons.error)),
    );
  }
}
