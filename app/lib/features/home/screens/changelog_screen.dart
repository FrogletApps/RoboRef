import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChangeLogScreen extends StatelessWidget {
  const ChangeLogScreen({super.key});

  final String version = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    final entries = [
      {
        'date': '23 August 2026',
        'items': [
          'Brand Identity & Icon Assets: Integrated canonical RoboRef logo across in-app UI, Web PWA icons/favicons, Android mipmaps, and iOS AppIcon set',
          'Clean-Slate Rebuild: Complete ground-up rebuild using Flutter & Dart for cross-platform Android, iOS, and Web',
          'Match Schedule & Field Inspection: Added full tournament match schedule view with alliance team indicators and field inspection links',
          'VEXEvents API Integration: Direct retrieval of tournament match schedules and team rosters by SKU',
          'Tournament Manager (TM) CSV Import: Added support for manual paste/import of Tournament Manager team and match schedule CSVs for offline venue readiness',
          'Venue LAN Sync Priority (roboref.local): Set http://roboref.local:8080 as the preferred default connection with automatic LAN server status detection',
          'Universal Sync Server: TypeScript + Hono sync server for both local Raspberry Pi venue deployment and Cloudflare Workers cloud deployment',
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Log'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Version Card with Copy button
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Version',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use this to let a developer know what version you are using if you encounter an issue.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'v$version',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: version));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Version copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Release Notes List
          const Text(
            'Release History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...entries.map((entry) {
            final date = entry['date'] as String;
            final items = entry['items'] as List<String>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
