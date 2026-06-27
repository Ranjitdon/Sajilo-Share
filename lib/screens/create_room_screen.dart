import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/flatshare_app_bar.dart';
import '../theme.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  
  // Design details
  String _selectedIconLabel = 'Home';
  IconData _selectedIcon = Icons.home;
  Color _selectedAccent = AppTheme.primary;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Apartment', 'icon': Icons.apartment},
    {'name': 'Cottage', 'icon': Icons.cottage},
    {'name': 'Weekend', 'icon': Icons.weekend},
    {'name': 'Domain', 'icon': Icons.domain},
    {'name': 'Bed', 'icon': Icons.bed},
    {'name': 'Kitchen', 'icon': Icons.kitchen},
    {'name': 'Deck', 'icon': Icons.deck},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final roomService = ref.read(roomServiceProvider);
      final hexColor = '#${_selectedAccent.value.toRadixString(16).substring(2).padLeft(6, '0')}';
      await roomService.createRoom(
        name,
        user.uid,
        icon: _selectedIconLabel.toLowerCase(),
        color: hexColor,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
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
          'Create Room',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: _selectedAccent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Visual Section
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBUYGPa4p9bsgD7NpzIHNLh1XTPFamfq0hTLDn007KpLLRm80v0h0Mo9D1BRWA_22FpnWhyXklLnXTjjSl26CFIm35Xz0Oec77GyK-EiYlz5blXV3y2k5_ca-IyK0Rfat_lsvyRxUGHgdKsjXeG_fqOvc91xq3RRkJsAvR-QyoPJHasVTqCihGKtdQCBjQaAW237Hsf0Ynj3pRv0qtvaJPeQFB9541KCWP6Sgk8v8qiFBYAhlwtdUA5hO6QqNNjop0quBF8TqUVOxs',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedAccent,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'NEW WORKSPACE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Room Name Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    'Room Name',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. The Penthouse',
                    suffixIcon: Icon(Icons.edit, size: 20, color: _selectedAccent),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _selectedAccent, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Location Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    'Location (Optional)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Skyline Towers, Floor 42',
                    suffixIcon: Icon(Icons.location_on, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _selectedAccent, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Icon Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Room Icon',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _selectedIconLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _selectedAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final item = _availableIcons[index];
                    final isSel = _selectedIconLabel == item['name'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIconLabel = item['name'];
                          _selectedIcon = item['icon'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _selectedAccent.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? _selectedAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSel ? _selectedAccent : theme.colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Color Palette Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                  child: Text(
                    'Accent Color',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildColorButton(AppTheme.primary),
                      _buildColorButton(AppTheme.secondary),
                      _buildColorButton(AppTheme.tertiary),
                      _buildColorButton(AppTheme.error),
                      _buildColorButton(AppTheme.primaryContainer),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add_circle, size: 22, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAccent,
                      ),
                      label: Text(
                        'Create Room',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedAccent == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccent = color;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
