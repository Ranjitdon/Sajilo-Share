import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (might be unsupported platform): $e');
  }

  runApp(
    const ProviderScope(
      child: FlatShareApp(),
    ),
  );
}

class FlatShareApp extends ConsumerWidget {
  const FlatShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sajilo Share',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
