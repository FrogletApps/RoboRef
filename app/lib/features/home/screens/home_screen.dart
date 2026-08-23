import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sku_utils.dart';
import '../../event_selection/screens/event_selection_screen.dart';
import '../../event_selection/state/event_controller.dart';
import '../../event_workspace/screens/event_workspace_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/state/sync_settings_controller.dart';
import 'changelog_screen.dart';
import 'share_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToIncidents;

  const HomeScreen({
    super.key,
    this.onNavigateToIncidents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(recentEventsStreamProvider);
    final settings = ref.watch(syncSettingsProvider);
    final env = getAppEnvironment();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recentEventsStreamProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. RoboRef Title / Brand Bar
              _buildTitleBar(context, env),
              const SizedBox(height: 14),

              // 2. Quick Actions Grid (Change Log | Share RoboRef | Settings)
              _buildQuickActionsGrid(context),
              const SizedBox(height: 16),

              // 3. Primary Action: Add a new event button
              _buildAddEventButton(context),
              const SizedBox(height: 20),

              // 4. Recent Events List / Welcome Section
              recentEventsAsync.when(
                loading: () => _buildWelcomeCard(context),
                error: (err, stack) => _buildWelcomeCard(context),
                data: (events) {
                  if (events.isEmpty) {
                    return _buildWelcomeCard(context);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Tournaments',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...events.map((event) {
                      final isActive = event.sku.toUpperCase() == settings.currentSku.toUpperCase();
                      final color = getSkuColor(event.sku);
                      final dateRange = formatEventDateRange(event.startDate, event.endDate);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isActive ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive
                                ? color.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Set as active tournament SKU
                            ref.read(syncSettingsProvider.notifier).setSku(event.sku);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Active tournament: ${event.sku}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            if (onNavigateToIncidents != null) {
                              onNavigateToIncidents!();
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EventWorkspaceScreen(),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: SKU Badge + Dates + Active indicator
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: color.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        event.sku,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    if (dateRange.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateRange,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ] else
                                      const Spacer(),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, size: 12, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onSelected: (action) {
                                        if (action == 'hide') {
                                          ref.read(eventControllerProvider.notifier).hideEvent(event.sku);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Removed ${event.sku} from recent list')),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'hide',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility_off, size: 16),
                                              SizedBox(width: 8),
                                              Text('Remove from recent'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Event Name
                                Text(
                                  event.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),

                                // Venue / City Location
                                if (event.venue != null || event.city != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [event.venue, event.city, event.region]
                                              .where((s) => s != null && s.isNotEmpty)
                                              .join(', '),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// RoboRef Title Bar matching RoboRef-Deprecated styling
  Widget _buildTitleBar(BuildContext context, AppEnvironment env) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/roboref-192x192.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: -0.5,
                  color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                ),
                children: [
                  const TextSpan(text: 'RoboRef'),
                  TextSpan(
                    text: '.fyi',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Environment Badge
          if (env == AppEnvironment.local)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626), // Red-600
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LOCAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            )
          else if (env == AppEnvironment.test)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15), // Yellow-400
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TEST',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 3-Column Quick Actions Grid: Change Log | Share | Settings
  Widget _buildQuickActionsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Change Log Button
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.update_rounded,
            label: 'Change Log',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangeLogScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Share RoboRef Button
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.qr_code_2_rounded,
            label: 'Share RoboRef',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShareScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Settings Button
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Prominent "+ Add a new event" Primary Button
  Widget _buildAddEventButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB), // Blue-600
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventSelectionScreen()),
        );
      },
      icon: const Icon(Icons.add, size: 24),
      label: const Text(
        'Add a new event',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Welcome guidance card when no tournaments exist in database
  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 8),
              Text(
                'Welcome to RoboRef!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This is an anomaly log for Head Referees at VEX robotics competitions.',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'To get started, tap the "Add a new event" button above.',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
            ),
          ),
        ],
      ),
    );
  }
}
