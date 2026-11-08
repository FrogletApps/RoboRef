import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';

/// Screen displaying the RoboRef Privacy Policy offline from local assets.
class PrivacyPolicyScreen extends StatefulWidget {
  final String? privacyAssetPath;

  const PrivacyPolicyScreen({
    super.key,
    this.privacyAssetPath,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late Future<String> _privacyPolicyFuture;

  @override
  void initState() {
    super.initState();
    final path = widget.privacyAssetPath ?? 'assets/privacy.md';
    _privacyPolicyFuture = loadLocalizedAssetString(path);
  }

  void _reloadPrivacyPolicy() {
    setState(() {
      final path = widget.privacyAssetPath ?? 'assets/privacy.md';
      _privacyPolicyFuture = loadLocalizedAssetString(
        path,
        locale: Localizations.maybeLocaleOf(context),
      );
    });
  }

  Future<void> _openWebPolicy(BuildContext context) async {
    const urlStr = 'https://roboref.app/privacy';
    final uri = Uri.parse(urlStr);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.privacyCannotOpenBrowser(urlStr)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.privacyCannotOpenWebLink),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.privacyPolicyTitle),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: context.l10n.privacyOpenInBrowserTooltip,
              onPressed: () => _openWebPolicy(context),
            ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _privacyPolicyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.privacyLoadErrorTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reloadPrivacyPolicy,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final content = snapshot.data ?? '';

          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                // Markdown body
                MarkdownBody(
                  data: content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    h1: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                    h2: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                    h3: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      height: 1.3,
                    ),
                    p: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                    ),
                    listBullet: TextStyle(
                      fontSize: 13.5,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer with web link (mobile/desktop app only)
                if (!kIsWeb) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _openWebPolicy(context),
                      icon: const Icon(Icons.public, size: 16),
                      label: Text(context.l10n.privacyViewOnline),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
