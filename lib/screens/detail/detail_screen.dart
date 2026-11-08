// ==============================================================================
// Lecture Detail Screen (S4)
// File: lib/screens/detail/detail_screen.dart
//
// Displays the lecture's audio player, English academic summary (FR4),
// and timestamped transcript with interactive "Tap-to-Seek" (FR8).
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../data/models/qayd_model.dart';
import '../../providers/qayd_provider.dart';

class DetailScreen extends StatefulWidget {
  final String qaydId;

  const DetailScreen({
    super.key,
    required this.qaydId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AudioPlayer _audioPlayer;

  double _currentPositionSec = 0.0;
  double _playbackSpeed = 1.0;
  bool _audioAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _audioPlayer = AudioPlayer();

    _initAudioPlayer();
  }

  void _initAudioPlayer() async {
    final provider = context.read<QaydProvider>();
    final qayd = provider.qayds.firstWhere(
      (q) => q.id == widget.qaydId,
      orElse: () => provider.activeQayd!,
    );

    if (qayd.audioPath.isNotEmpty && await File(qayd.audioPath).exists()) {
      try {
        await _audioPlayer.setFilePath(qayd.audioPath);
        if (mounted) setState(() => _audioAvailable = true);

        // Track live audio position for Tap-to-Seek segment highlighting (FR8)
        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _currentPositionSec = position.inMilliseconds / 1000.0;
            });
          }
        });
      } catch (e) {
        debugPrint('Could not load audio file: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(double seconds) {
    final totalSec = seconds.toInt();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _seekToSegment(TranscriptSegment segment) {
    if (_audioAvailable) {
      _audioPlayer.seek(
        Duration(milliseconds: (segment.startSec * 1000).round()),
      );
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    }
  }

  void _togglePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
      _audioPlayer.setSpeed(_playbackSpeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QaydProvider>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final qayd = provider.qayds.cast<Qayd?>().firstWhere(
      (q) => q?.id == widget.qaydId,
      orElse: () => provider.activeQayd,
    );

    if (qayd == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(isArabic ? 'المحاضرة غير موجودة' : 'Qayd not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          qayd.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, qayd),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 10),
                    Text(isArabic ? 'إعادة التسمية' : 'Rename'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit_transcript',
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 20),
                    const SizedBox(width: 10),
                    Text(isArabic ? 'تعديل النص' : 'Edit Transcript'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'folder',
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20),
                    const SizedBox(width: 10),
                    Text(isArabic ? 'نقل إلى مجلد' : 'Move to Folder'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Text(
                      isArabic ? 'حذف' : 'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          tabs: [
            Tab(
              icon: const Icon(Icons.auto_awesome),
              text: isArabic ? 'الملخص الأكاديمي' : 'Academic Summary',
            ),
            Tab(
              icon: const Icon(Icons.subtitles),
              text: isArabic ? 'التفريغ النصي' : 'Full Transcript',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Audio Player Header Bar (FR8)
          if (_audioAvailable) _buildAudioPlayerBar(theme, qayd),

          // Content Tabs (Summary & Transcript)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(theme, qayd, isArabic),
                _buildTranscriptTab(theme, qayd, isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Audio Player Bar Widget (FR8)
  // ---------------------------------------------------------------------------
  Widget _buildAudioPlayerBar(ThemeData theme, Qayd qayd) {
    final totalDurationSec =
        (_audioPlayer.duration?.inMilliseconds ?? (qayd.durationSec * 1000)) /
            1000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.playing ?? false;
                  return IconButton.filledTonal(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(_currentPositionSec),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _currentPositionSec.clamp(0.0, totalDurationSec),
                    max: totalDurationSec > 0 ? totalDurationSec : 1.0,
                    onChanged: (val) {
                      _audioPlayer.seek(
                        Duration(milliseconds: (val * 1000).round()),
                      );
                    },
                  ),
                ),
              ),
              Text(
                _formatTime(totalDurationSec),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              // Playback Speed Toggle (1.0x, 1.25x, 1.5x, 2.0x)
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _togglePlaybackSpeed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Academic Summary View (FR4)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryTab(ThemeData theme, Qayd qayd, bool isArabic) {
    final summary = qayd.summary;

    if (summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notes, size: 64, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'الملخص غير متوفر بعد' : 'Summary Not Available',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'يمكنك إنشاء الملخص الأكاديمي الآن باستخدام Gemini'
                    : 'You can generate the academic summary now with Gemini',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  context.read<QaydProvider>().retrySummary(qayd.id);
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(isArabic ? 'توليد الملخص الآن' : 'Generate Summary Now'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Overview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary.overview,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Key Points Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.checklist, color: theme.colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Key Points & Takeaways',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...summary.keyPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            )),
                        Expanded(
                          child: Text(
                            point,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Key Terms & Definitions Card
        if (summary.keyTerms.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: theme.colorScheme.tertiary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Key Terminology',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...summary.keyTerms.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.term,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.definition,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Full Transcript with Tap-to-Seek & Highlighting (FR3, FR8)
  // ---------------------------------------------------------------------------
  Widget _buildTranscriptTab(ThemeData theme, Qayd qayd, bool isArabic) {
    if (qayd.segments.isEmpty && qayd.transcript.isEmpty) {
      return Center(
        child: Text(isArabic ? 'لا يوجد تفريغ نصي' : 'No transcript available'),
      );
    }

    // If segments exist, render interactive Tap-to-Seek list (FR8)
    if (qayd.segments.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        itemCount: qayd.segments.length,
        itemBuilder: (context, index) {
          final seg = qayd.segments[index];
          final isPlayingNow = _currentPositionSec >= seg.startSec &&
              _currentPositionSec <= seg.endSec;

          return InkWell(
            onTap: () => _seekToSegment(seg),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPlayingNow
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isPlayingNow
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPlayingNow
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatTime(seg.startSec),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPlayingNow
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Segment Text
                  Expanded(
                    child: Text(
                      seg.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontWeight:
                            isPlayingNow ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Fallback: Raw scrollable text
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SelectableText(
        qayd.transcript,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers (Rename, Move, Edit, Delete)
  // ---------------------------------------------------------------------------
  void _handleMenuAction(String action, Qayd qayd) {
    final provider = context.read<QaydProvider>();
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (action == 'rename') {
      final controller = TextEditingController(text: qayd.title);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isArabic ? 'إعادة تسمية المحاضرة' : 'Rename Lecture'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: isArabic ? 'العنوان' : 'Title',
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
                  provider.renameQayd(qayd.id, controller.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      );
    } else if (action == 'edit_transcript') {
      final controller = TextEditingController(text: qayd.transcript);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isArabic ? 'تعديل النص المفرغ' : 'Edit Transcript'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                provider.editTranscript(qayd.id, controller.text);
                Navigator.pop(ctx);
              },
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      );
    } else if (action == 'folder') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isArabic ? 'نقل إلى مجلد' : 'Move to Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.inbox),
                  title: Text(isArabic ? 'بدون مجلد (عام)' : 'Unfiled'),
                  selected: qayd.folderId == null,
                  onTap: () {
                    provider.moveQaydToFolder(qayd.id, null);
                    Navigator.pop(ctx);
                  },
                ),
                ...provider.folders.map(
                  (f) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(f.name),
                    selected: qayd.folderId == f.id,
                    onTap: () {
                      provider.moveQaydToFolder(qayd.id, f.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إغلاق' : 'Close'),
            ),
          ],
        ),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isArabic ? 'حذف المحاضرة؟' : 'Delete Qayd?'),
          content: Text(
            isArabic
                ? 'هل أنت متأكد من حذف هذه المحاضرة وجميع ملفاتها نهائياً؟'
                : 'Are you sure you want to delete this Qayd and its local audio file permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                provider.deleteQayd(qayd.id);
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to Home
              },
              child: Text(isArabic ? 'حذف' : 'Delete'),
            ),
          ],
        ),
      );
    }
  }
}
