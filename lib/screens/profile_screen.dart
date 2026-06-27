import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/dues_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDisplayName(String email) {
    if (email.contains('@')) {
      final namePart = email.split('@')[0];
      // capitalize parts
      return namePart.split('.').map((s) {
        if (s.isEmpty) return '';
        return s[0].toUpperCase() + s.substring(1);
      }).join(' ');
    }
    return email;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final expensesAsync = ref.watch(personalExpensesProvider);
    final duesAsync = ref.watch(userDuesProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final displayName = _formatDisplayName(user.email ?? 'Karan Malhotra');
    
    // Live calculations for Stats
    double totalShared = 0.0;
    if (expensesAsync.hasValue) {
      totalShared = expensesAsync.value!.fold<double>(0, (sum, exp) => sum + exp.amount);
    }

    double activeDues = 0.0;
    if (duesAsync.hasValue) {
      activeDues = duesAsync.value!.fold<double>(0, (sum, due) => sum + due.amount);
    }

    return Scaffold(
      appBar: const FlatShareAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Bento Profile Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: user.photoURL != null
                              ? Image.network(user.photoURL!, fit: BoxFit.cover)
                              : Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBHcmF9y-xD3mu2Ysm8n0egCCN60muUBhmM9ueAkfdvCDKyZMxbwNeZoEU36EDDGWf9uB4oBRT2l6mmX2WF-_giJtBQWrLiMkSV4Njy2dXyosttHP4ZTomMYu0X3geOdFwLaZpOCZANySz0K03ObZWTW5CiJSH6OPzqBJp_Q7zvFl0Jxsbqal3TykpmJCXKwWgd3H2i7jwdHzJAxW14jNmr9DvcvE2Ix5HpwW1krKoewUzkCEvZAMFVHMwAsO27sNdvGg4ejap6f3U',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.surfaceContainerLowest, width: 2),
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 12,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'karan@example.com',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'PREMIUM MEMBER',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats Asymmetric Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Shared',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatMoney(totalShared)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Dues',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatMoney(activeDues)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Menu List Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.category,
                    iconColor: theme.colorScheme.primary,
                    title: 'Manage Categories',
                    onTap: () => context.push('/manage-categories'),
                  ),
                  _buildDivider(theme),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    iconColor: theme.colorScheme.primary,
                    title: 'My Analytics',
                    onTap: () => context.push('/analytics'),
                  ),
                  _buildDivider(theme),
                  _buildMenuItem(
                    icon: Icons.settings,
                    iconColor: theme.colorScheme.primary,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  _buildDivider(theme),
                  _buildMenuItem(
                    icon: Icons.person_add,
                    iconColor: theme.colorScheme.primary,
                    title: 'Invite Friends',
                    onTap: () {},
                  ),
                  _buildDivider(theme),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    iconColor: theme.colorScheme.primary,
                    title: 'Support',
                    onTap: () {},
                  ),
                  _buildDivider(theme),
                  _buildMenuItem(
                    icon: Icons.logout,
                    iconColor: theme.colorScheme.error,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () async {
                      final authController = ref.read(authControllerProvider);
                      await authController.signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // App version / details
            Center(
              child: Column(
                children: [
                  Text(
                    'Sajilo Share v2.4.1',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Collective Trust & Clarity',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? iconColor.withValues(alpha: 0.1)
                    : AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? iconColor : AppTheme.onBackground,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? iconColor.withValues(alpha: 0.5) : AppTheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 72, // aligns with the text start
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}
