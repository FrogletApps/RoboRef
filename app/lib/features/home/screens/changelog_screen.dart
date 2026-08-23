import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data model representing a release date / section in the change log.
class ChangeLogRelease {
  final String title;
  final List<ChangeLogItem> items;

  const ChangeLogRelease({
    required this.title,
    required this.items,
  });
}

/// Data model representing an individual bullet item in the change log.
class ChangeLogItem {
  final String rawText;
  final String? boldTitle;
  final String description;

  const ChangeLogItem({
    required this.rawText,
    this.boldTitle,
    required this.description,
  });
}

/// Parses raw markdown text from `documents/changeLog.md` into structured [ChangeLogRelease] objects.
List<ChangeLogRelease> parseChangeLog(String markdownContent) {
  final lines = markdownContent.split('\n');
  final releases = <ChangeLogRelease>[];
  String? currentTitle;
  final currentItems = <ChangeLogItem>[];

  void commitRelease() {
    final title = currentTitle;
    if (title != null && currentItems.isNotEmpty) {
      releases.add(
        ChangeLogRelease(
          title: title,
          items: List.unmodifiable(currentItems),
        ),
      );
      currentItems.clear();
    }
  }

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    // Header matching (## 23 August 2026, ### v1.0.0, etc.)
    if (line.startsWith('## ') || line.startsWith('### ')) {
      commitRelease();
      currentTitle = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    } else if (line.startsWith('# ')) {
      // Top-level document title (e.g. # Change Log) - skip
      continue;
    } else if (line.startsWith('- ') || line.startsWith('* ') || RegExp(r'^\d+\.\s').hasMatch(line)) {
      currentTitle ??= 'Recent Updates';
      final rawItem = line.replaceFirst(RegExp(r'^(?:[-*]|\d+\.)\s*'), '').trim();

      // Check for bold title format: **Title**: Description or **Title** - Description
      final boldWithSeparatorRegex = RegExp(r'^\*\*(.+?)\*\*(?:\s*[:\-–—]\s*)(.*)$');
      final match = boldWithSeparatorRegex.firstMatch(rawItem);

      if (match != null) {
        currentItems.add(
          ChangeLogItem(
            rawText: rawItem,
            boldTitle: match.group(1)?.trim(),
            description: match.group(2)?.trim() ?? '',
          ),
        );
      } else {
        // Check for **Title** Description without colon
        final boldOnlyRegex = RegExp(r'^\*\*(.+?)\*\*\s*(.*)$');
        final boldMatch = boldOnlyRegex.firstMatch(rawItem);
        if (boldMatch != null && boldMatch.group(2)!.isNotEmpty) {
          currentItems.add(
            ChangeLogItem(
              rawText: rawItem,
              boldTitle: boldMatch.group(1)?.trim(),
              description: boldMatch.group(2)?.trim() ?? '',
            ),
          );
        } else {
          // Regular bullet without bold title
          currentItems.add(
            ChangeLogItem(
              rawText: rawItem,
              description: rawItem,
            ),
          );
        }
      }
    } else if (currentTitle != null && currentItems.isNotEmpty) {
      // Multi-line continuation of previous bullet
      final last = currentItems.removeLast();
      currentItems.add(
        ChangeLogItem(
          rawText: '${last.rawText} $line',
          boldTitle: last.boldTitle,
          description: '${last.description} $line',
        ),
      );
    }
  }

  commitRelease();
  return releases;
}

class ChangeLogScreen extends StatefulWidget {
  final String changelogAssetPath;

  const ChangeLogScreen({
    super.key,
    this.changelogAssetPath = '../documents/changeLog.md',
  });

  @override
  State<ChangeLogScreen> createState() => _ChangeLogScreenState();
}

class _ChangeLogScreenState extends State<ChangeLogScreen> {
  final String version = '1.0.0+1';
  late Future<List<ChangeLogRelease>> _changelogFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChangeLog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadChangeLog() {
    setState(() {
      _changelogFuture = _fetchAndParseChangeLog();
    });
  }

  Future<List<ChangeLogRelease>> _fetchAndParseChangeLog() async {
    final rawMarkdown = await rootBundle.loadString(widget.changelogAssetPath);
    return parseChangeLog(rawMarkdown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Changelog',
            onPressed: _loadChangeLog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadChangeLog();
          await _changelogFuture;
        },
        child: FutureBuilder<List<ChangeLogRelease>>(
          future: _changelogFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading changelog...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildVersionCard(context),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.red.shade900.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load change log',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadChangeLog,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final releases = snapshot.data ?? [];
            final filteredReleases = _filterReleases(releases, _searchQuery);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Current Version Card with Copy action
                _buildVersionCard(context),
                const SizedBox(height: 20),

                // 2. Search & Filter Bar (if changelog is populated)
                if (releases.isNotEmpty) ...[
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                ],

                // 3. Release History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Release History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (releases.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${releases.fold<int>(0, (sum, r) => sum + r.items.length)} total updates',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Release History Cards
                if (filteredReleases.isEmpty)
                  _buildEmptyState(context)
                else
                  ...filteredReleases.map((release) => _buildReleaseCard(context, release)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ChangeLogRelease> _filterReleases(List<ChangeLogRelease> releases, String query) {
    if (query.trim().isEmpty) return releases;
    final lowerQuery = query.toLowerCase().trim();

    final result = <ChangeLogRelease>[];
    for (final release in releases) {
      final matchingItems = release.items.where((item) {
        return item.rawText.toLowerCase().contains(lowerQuery) ||
            (item.boldTitle?.toLowerCase().contains(lowerQuery) ?? false) ||
            item.description.toLowerCase().contains(lowerQuery);
      }).toList();

      if (matchingItems.isNotEmpty || release.title.toLowerCase().contains(lowerQuery)) {
        result.add(
          ChangeLogRelease(
            title: release.title,
            items: matchingItems.isNotEmpty ? matchingItems : release.items,
          ),
        );
      }
    }
    return result;
  }

  /// Version Card with Copy button
  Widget _buildVersionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Version',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
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
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RELEASE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'v$version',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
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
    );
  }

  /// Search & Filter Box
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search release notes...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
    );
  }

  /// Empty state when search yields no matches
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No changelog entries found matching "$_searchQuery"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Text('Clear search'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Individual Release Card
  Widget _buildReleaseCard(BuildContext context, ChangeLogRelease release) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Release Header (Date / Version Title + Item Count)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      release.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Text(
                    '${release.items.length} ${release.items.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // List of Items in this release
            ...release.items.map((item) => _buildChangeLogItemRow(context, item)),
          ],
        ),
      ),
    );
  }

  /// Individual item row with bullet indicator and rich text rendering
  Widget _buildChangeLogItemRow(BuildContext context, ChangeLogItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet indicator icon
          Container(
            margin: const EdgeInsets.only(top: 5.5, right: 10),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),

          // Content with RichText (supports bold titles, inline code spans, etc.)
          Expanded(
            child: _buildFormattedText(context, item),
          ),
        ],
      ),
    );
  }

  /// Builds formatted rich text handling bold title and inline code segments (`code`)
  Widget _buildFormattedText(BuildContext context, ChangeLogItem item) {
    final spans = <InlineSpan>[];
    final defaultStyle = TextStyle(
      fontSize: 13.5,
      height: 1.35,
      color: Theme.of(context).colorScheme.onSurface,
    );

    // 1. Add bold title if present
    if (item.boldTitle != null && item.boldTitle!.isNotEmpty) {
      spans.addAll(_parseInlineCodeSpans(
        context,
        item.boldTitle!,
        baseStyle: defaultStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));

      spans.add(TextSpan(
        text: item.description.isNotEmpty ? ': ' : '',
        style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
      ));
    }

    // 2. Add description with inline code formatting
    if (item.description.isNotEmpty) {
      spans.addAll(_parseInlineCodeSpans(
        context,
        item.description,
        baseStyle: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }

  /// Helper to convert text containing inline backticks `example` into formatted spans
  List<InlineSpan> _parseInlineCodeSpans(
    BuildContext context,
    String text, {
    required TextStyle baseStyle,
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'`([^`]+)`');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final codeText = match.group(1) ?? '';
      final isDark = Theme.of(context).brightness == Brightness.dark;

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
              ),
            ),
            child: Text(
              codeText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * 0.9 : 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
