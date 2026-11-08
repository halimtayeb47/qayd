// ==============================================================================
// Home Screen (S1)
// File: lib/screens/home/home_screen.dart
//
// Displays saved Qayds newest-first, folder filter chips, search bar,
// and actions to record live or import audio (FR1, FR2, FR6, NFR10).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/qayd_model.dart';
import '../../providers/qayd_provider.dart';
import '../record/record_screen.dart';
import '../processing/processing_screen.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showNewQaydOptions(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'بدء قيد جديد' : 'Capture New Qayd',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.mic, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(isArabic ? 'تسجيل محاضرة حية' : 'Record Live Lecture'),
                  subtitle: Text(
                    isArabic
                        ? 'تسجيل الصوت مباشرة من الميكروفون'
                        : 'Record audio directly via microphone',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.upload_file,
                        color: theme.colorScheme.onSecondaryContainer),
                  ),
                  title: Text(isArabic ? 'استيراد ملف صوتي' : 'Import Audio File'),
                  subtitle: Text(
                    isArabic
                        ? 'رفع ملف MP3 أو M4A أو WAV (حتى 100 ميجابايت)'
                        : 'Import MP3, M4A, or WAV file (up to 100 MB)',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final provider = context.read<QaydProvider>();
                    final navigator = Navigator.of(context);

                    // Open file picker
                    final pickedQayd = await provider.importAudioAndProcess();
                    if (pickedQayd != null) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const ProcessingScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'إنشاء مجلد جديد' : 'New Course Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isArabic ? 'اسم المادة أو المقرر' : 'Course / Subject Name',
            hintText: isArabic ? 'مثال: الذكاء الاصطناعي' : 'e.g. Artificial Intelligence',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<QaydProvider>().createFolder(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'إنشاء' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QaydProvider>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isArabic ? 'بحث في المحاضرات والملخصات...' : 'Search lectures & notes...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: provider.setSearchQuery,
              )
            : Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'ق',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isArabic ? 'قَيْد' : 'Qayd',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  provider.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: isArabic ? 'مجلد جديد' : 'New Folder',
            onPressed: () => _showCreateFolderDialog(context),
          ),
          IconButton(
            icon: Icon(provider.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined),
            tooltip: isArabic ? 'المظهر' : 'Theme',
            onPressed: provider.toggleTheme,
          ),
          TextButton(
            onPressed: provider.toggleLocale,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(48, 36),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                isArabic ? 'EN' : 'عربي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder Filter Chips Bar (NFR10)
          _buildFoldersBar(theme, provider, isArabic),

          // Main Content: List of Qayds or Empty State
          Expanded(
            child: provider.qayds.isEmpty
                ? _buildEmptyState(theme, isArabic)
                : _buildQaydsList(theme, provider, isArabic),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewQaydOptions(context),
        icon: const Icon(Icons.mic),
        label: Text(isArabic ? 'قيد جديد' : 'New Qayd'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Folder Filter Chips (NFR10)
  // ---------------------------------------------------------------------------
  Widget _buildFoldersBar(
      ThemeData theme, QaydProvider provider, bool isArabic) {
    final selectedFolderId = provider.selectedFolderId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(isArabic ? 'الكل' : 'All Qayds'),
            selected: selectedFolderId == null,
            onSelected: (_) => provider.filterByFolder(null),
          ),
          const SizedBox(width: 8),
          ...provider.folders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(folder.name),
                selected: selectedFolderId == folder.id,
                onSelected: (selected) {
                  provider.filterByFolder(selected ? folder.id : null);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State View
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(ThemeData theme, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic_none_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'لا توجد محاضرات بعد' : 'No Qayds Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'العِلْمُ صَيْدٌ وَالكِتَابَةُ قَيْدُهُ\nابدأ بتسجيل أول محاضرة لتلخيصها وحفظها'
                  : 'Capture and summarize your lectures effortlessly.\nTap below to start recording or import audio.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showNewQaydOptions(context),
              icon: const Icon(Icons.add),
              label: Text(isArabic ? 'ابدأ قيداً جديداً' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Qayds List View (FR6)
  // ---------------------------------------------------------------------------
  Widget _buildQaydsList(
      ThemeData theme, QaydProvider provider, bool isArabic) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: provider.qayds.length,
      itemBuilder: (context, index) {
        final qayd = provider.qayds[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(qaydId: qayd.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status / Audio Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: qayd.status == QaydStatus.done
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          qayd.status == QaydStatus.done
                              ? Icons.auto_awesome
                              : Icons.mic,
                          color: qayd.status == QaydStatus.done
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              qayd.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(qayd.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Duration Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(qayd.durationSec),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Snippet or Overview Preview
                  if (qayd.summary?.overview.isNotEmpty == true)
                    Text(
                      qayd.summary!.overview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (qayd.transcript.isNotEmpty)
                    Text(
                      qayd.transcript,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Badges: Language & Folder
                  Wrap(
                    spacing: 8,
                    children: [
                      // Language Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          qayd.language == QaydLanguage.mixed
                              ? 'AR + EN'
                              : qayd.language.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      // Summary Status Badge
                      if (qayd.summary != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isArabic ? 'ملخص جاهز' : 'Summary Ready',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
