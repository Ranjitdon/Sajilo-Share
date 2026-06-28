import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'router.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (might be unsupported platform): $e');
  }

  await LocalNotificationService.initialize();

  runApp(
    const ProviderScope(
      child: FlatShareApp(),
    ),
  );
}

class FlatShareApp extends ConsumerStatefulWidget {
  const FlatShareApp({super.key});

  @override
  ConsumerState<FlatShareApp> createState() => _FlatShareAppState();
}

class _FlatShareAppState extends ConsumerState<FlatShareApp> {
  @override
  void initState() {
    super.initState();
    // Request permission on first start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sajilo Share',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
