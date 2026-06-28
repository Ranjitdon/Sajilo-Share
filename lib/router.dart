import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_personal_expense_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/room_details_screen.dart';
import 'screens/add_room_expense_screen.dart';
import 'screens/manage_categories_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/due_breakdown_screen.dart';
import 'screens/room_analytics_screen.dart';
import 'models/room.dart';
import 'models/room_expense.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // If the authentication state is still loading, don't redirect yet.
      if (authState.isLoading || authState.hasError) return null;

      final isAuth = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuth) {
        return '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-personal-expense',
        builder: (context, state) => const AddPersonalExpenseScreen(),
      ),
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: '/join-room',
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: '/room-details',
        builder: (context, state) => RoomDetailsScreen(room: state.extra as Room),
      ),
      GoRoute(
        path: '/add-room-expense',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddRoomExpenseScreen(
            room: extra['room'] as Room,
            expenseToEdit: extra['expenseToEdit'],
          );
        },
      ),
      GoRoute(
        path: '/manage-categories',
        builder: (context, state) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/due-breakdown/:roomId/:otherUserId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final otherUserId = state.pathParameters['otherUserId']!;
          return DueBreakdownScreen(roomId: roomId, otherUserId: otherUserId);
        },
      ),
      GoRoute(
        path: '/room-analytics/:roomId',
        builder: (context, state) {
          final room = state.extra as Room;
          return RoomAnalyticsScreen(roomId: room.id, roomName: room.name);
        },
      ),
    ],
  );
});
