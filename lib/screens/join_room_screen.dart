import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      await roomService.joinRoom(code, user.uid);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the room!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlatShareAppBar(
        showBackButton: true,
        title: Text(
          'Join Room',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Atmospheric Details
          Positioned(
            top: 100,
            right: -80,
            width: 250,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            width: 250,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main Body Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Visual Anchor Group Add Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                offset: const Offset(0, 8),
                                blurRadius: 16,
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.group_add,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Header Text
                      Text(
                        'Enter Invite Code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Ask your roommate for the 6-character code or scan their QR code to join the flat.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Styled Code Field Input
                      TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'e.g. X9A2B4',
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          hintStyle: TextStyle(
                            color: theme.colorScheme.outlineVariant,
                            letterSpacing: 2,
                            fontSize: 18,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: theme.colorScheme.primary,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        autofocus: true,
                        onSubmitted: (_) => _joinRoom(),
                      ),
                      const SizedBox(height: 32),
                      // Primary Actions
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _joinRoom,
                                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                                    label: const Text(
                                      'Join Room',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // OR Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Scan QR Code Tonal Button
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: Icon(Icons.qr_code_scanner, color: theme.colorScheme.primary, size: 20),
                                    label: Text(
                                      'Scan QR Code',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                                      side: BorderSide(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 32),
                      // Secondary invite preview card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuBaHwp9FdA6F3fuOJeNE1LN_SW3z9OuBDPkFDPrOSZn9BKT_lsAYFXK0w4AfZF4_Yj5hpzahcHhG5YxYl99dtblROd4usEfR-uRek7bLOdqAxbpkfwUnNtyyyekh1YvMYuZNylfl9GmOGV0vaRSs8T2EDgwS641H0MepusfdlUDfgdHfKavcVw1NXMtzxmiAQqbpctWKaxkEy9f_M-b1z94kfnvLhnoCzpQNqz-K80bY4iXpg9yZvOsEiEvQvWc8OQ0fm2hYw2PNAw',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'INVITED BY',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 9,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'Sarah Jenkins',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+2 members',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
