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
          'Implemented dedicated RoboRef Home screen with tournament discovery and quick referee tools',
          'Added color-coded SKU formatting (Red for V5RC/VRC/VEX U, Blue for VIQRC, Emerald for ADC)',
          'Added local SQLite persistence for recent events and incident logs with Drift',
          'Added one-click tournament switching and direct SKU validation',
        ]
      },
      {
        'date': '22 August 2026',
        'items': [
          'Added Data Export and referee report summaries',
          'Enhanced team note tracking and severity classification (Major vs Minor violations)',
          'Added responsive dark referee UI for field tablets and mobile devices',
        ]
      },
      {
        'date': '21 August 2026',
        'items': [
          'Added live peer sync connection manager for venue Wi-Fi referee mesh network',
          'Improved team search and rule code indexing for High Stakes and Rapid Relay',
        ]
      },
      {
        'date': '18 August 2026',
        'items': [
          'Initial release of RoboRef Flutter cross-platform referee utility',
          'Offline-first architecture with automatic sync reconnect',
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
