import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Data model representing a release section in the changelog.
class ChangeLogRelease {
  final String title;
  final String markdownContent;
  final int itemCount;

  const ChangeLogRelease({
    required this.title,
    required this.markdownContent,
    required this.itemCount,
  });
}

/// Parses raw markdown text from `assets/changeLog.md` into structured [ChangeLogRelease] sections.
List<ChangeLogRelease> parseChangeLogReleases(String markdown) {
  final lines = markdown.split('\n');
  final releases = <ChangeLogRelease>[];

  String? currentTitle;
  final currentLines = <String>[];

  void commitRelease() {
    final title = currentTitle;
    if (title != null && currentLines.isNotEmpty) {
      final content = currentLines.join('\n').trim();
      final itemCount = currentLines
          .where((l) => l.trim().startsWith('- ') || l.trim().startsWith('* ') || RegExp(r'^\s*\d+\.').hasMatch(l))
          .length;

      releases.add(
        ChangeLogRelease(
          title: title,
          markdownContent: content,
          itemCount: itemCount > 0 ? itemCount : 1,
        ),
      );
      currentLines.clear();
    }
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();

    if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
      commitRelease();
      currentTitle = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    } else if (trimmed.startsWith('# ') && currentTitle == null) {
      // Top-level document title (e.g. # Change Log) - skip
      continue;
    } else {
      if (currentTitle != null) {
        currentLines.add(line);
      }
    }
  }

  commitRelease();

  // If no ## headings were found, treat whole document as single release
  if (releases.isEmpty && markdown.trim().isNotEmpty) {
    releases.add(
      ChangeLogRelease(
        title: 'Release Notes',
        markdownContent: markdown.trim(),
        itemCount: 1,
      ),
    );
  }

  return releases;
}

/// Loads changelog content from `assets/changeLog.md`.
Future<String> loadChangeLogMarkdown({String? overridePath}) async {
  final path = overridePath ?? 'assets/changeLog.md';
  return await rootBundle.loadString(path);
}

class ChangeLogScreen extends StatefulWidget {
  final String? changelogAssetPath;
  final String? overrideVersion;

  const ChangeLogScreen({
    super.key,
    this.changelogAssetPath,
    this.overrideVersion,
  });

  @override
  State<ChangeLogScreen> createState() => _ChangeLogScreenState();
}

class _ChangeLogScreenState extends State<ChangeLogScreen> {
  String _version = '2026.8.26+1';
  late Future<List<ChangeLogRelease>> _changelogFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.overrideVersion != null) {
      _version = widget.overrideVersion!;
    } else {
      _loadAppVersion();
    }
    _loadChangeLog();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        if (info.buildNumber.isNotEmpty) {
          _version = '${info.version}+${info.buildNumber}';
        } else {
          _version = info.version;
        }
      });
    } catch (_) {
      // Fallback to default version if platform channel is unavailable (e.g. tests)
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadChangeLog() {
    setState(() {
      _changelogFuture = _fetchReleases();
    });
  }

  Future<List<ChangeLogRelease>> _fetchReleases() async {
    final rawMarkdown = await loadChangeLogMarkdown(overridePath: widget.changelogAssetPath);
    return parseChangeLogReleases(rawMarkdown);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  _buildVersionCard(context, isDark),
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
                _buildVersionCard(context, isDark),
                const SizedBox(height: 20),

                // 2. Search & Filter Bar
                if (releases.isNotEmpty) ...[
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                ],

                // 3. Release History Header
                const Text(
                  'Release History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 4. Release History Cards
                if (filteredReleases.isEmpty)
                  _buildEmptyState(context)
                else
                  ...filteredReleases.map((release) => _buildReleaseCard(context, release, isDark)),
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
      if (release.title.toLowerCase().contains(lowerQuery) ||
          release.markdownContent.toLowerCase().contains(lowerQuery)) {
        // Filter lines inside markdown if matching specific bullets
        final lines = release.markdownContent.split('\n');
        final matchingLines = lines.where((l) => l.toLowerCase().contains(lowerQuery)).toList();

        final contentToUse = matchingLines.isNotEmpty ? matchingLines.join('\n') : release.markdownContent;

        result.add(
          ChangeLogRelease(
            title: release.title,
            markdownContent: contentToUse,
            itemCount: matchingLines.isNotEmpty ? matchingLines.length : release.itemCount,
          ),
        );
      }
    }
    return result;
  }

  /// Version Card with Copy button
  Widget _buildVersionCard(BuildContext context, bool isDark) {
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
                        'v$_version',
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
                      Clipboard.setData(ClipboardData(text: _version));
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

  /// Release Card rendering Markdown via MarkdownBody
  Widget _buildReleaseCard(BuildContext context, ChangeLogRelease release, bool isDark) {
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
            // Release Header (Date / Version Title)
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
            const SizedBox(height: 12),

            // Authentic Markdown Rendering
            MarkdownBody(
              data: release.markdownContent,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
                ),
                listBullet: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                listBulletPadding: const EdgeInsets.only(right: 6),
                listIndent: 16,
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                code: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
                  ),
                ),
                a: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  Clipboard.setData(ClipboardData(text: href));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied: $href'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
