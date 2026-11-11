// ==============================================================================
// Lecture Detail Screen (S4)
// File: lib/screens/detail/detail_screen.dart
//
// Displays the lecture's audio player, English academic summary (FR4),
// and timestamped transcript with interactive "Tap-to-Seek" (FR8).
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../data/models/qayd_model.dart';
import '../../providers/qayd_provider.dart';
import '../../widgets/qayd_actions.dart';

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
    final qayd = provider.qayds.cast<Qayd?>().firstWhere(
      (q) => q?.id == widget.qaydId,
      orElse: () => provider.activeQayd?.id == widget.qaydId
          ? provider.activeQayd
          : provider.storageService.getQayd(widget.qaydId),
    );

    if (qayd == null) return;

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

  void _seekToSeconds(double seconds) {
    if (_audioAvailable) {
      _audioPlayer.seek(
        Duration(milliseconds: (seconds * 1000).round()),
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
      orElse: () => provider.activeQayd?.id == widget.qaydId
          ? provider.activeQayd
          : provider.storageService.getQayd(widget.qaydId),
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
    final provider = context.watch<QaydProvider>();
    final isGenerating = provider.isRetryingSummary;
    final hasTranscript = qayd.transcript.trim().isNotEmpty;

    final showScopedError = provider.errorMessage != null &&
        provider.errorQaydId == qayd.id &&
        !isGenerating;

    if (summary == null) {
      return Center(
        child: SingleChildScrollView(
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
                !hasTranscript
                    ? (isArabic
                        ? 'يرجى تفريغ الصوت أو إضافة نص المحاضرة أولاً قبل توليد الملخص الأكاديمي'
                        : 'Please transcribe the lecture audio or add a transcript first before generating a summary.')
                    : (isArabic
                        ? 'يمكنك إنشاء الملخص الأكاديمي الآن باستخدام Gemini'
                        : 'You can generate the academic summary now with Gemini'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (showScopedError) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (!hasTranscript || isGenerating)
                    ? null
                    : () => context.read<QaydProvider>().retrySummary(qayd.id),
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  isGenerating
                      ? (isArabic ? 'جاري توليد الملخص...' : 'Generating Summary...')
                      : (isArabic ? 'توليد الملخص الآن' : 'Generate Summary Now'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
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
                      Icon(Icons.menu_book,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: isArabic ? 'نسخ الملخص' : 'Copy Summary',
                        icon: const Icon(Icons.content_copy, size: 20),
                        onPressed: () =>
                            _copySummaryToClipboard(qayd, summary, isArabic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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

          // Topic Breakdown Sections Card
          if (summary.sections.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.view_agenda_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Topic Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...summary.sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: _audioAvailable
                                        ? () =>
                                            _seekToSeconds(section.startSec)
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _audioAvailable
                                            ? theme.colorScheme.primaryContainer
                                            : theme.colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_audioAvailable) ...[
                                            Icon(
                                              Icons.play_arrow,
                                              size: 13,
                                              color: theme.colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                            const SizedBox(width: 2),
                                          ],
                                          Text(
                                            _formatTime(section.startSec),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _audioAvailable
                                                  ? theme.colorScheme
                                                      .onPrimaryContainer
                                                  : theme.colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      section.heading,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                section.summary,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
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
          ],
          const SizedBox(height: 16),

          // Key Points Card
          if (summary.keyPoints.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist,
                            color: theme.colorScheme.secondary, size: 20),
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
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
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
          ],

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
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.tertiary,
                          size: 20,
                        ),
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
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
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
      ),
    );
  }

  Future<void> _copySummaryToClipboard(
    Qayd qayd,
    QaydSummary summary,
    bool isArabic,
  ) async {
    final buffer = StringBuffer()
      ..writeln(qayd.title)
      ..writeln()
      ..writeln('OVERVIEW')
      ..writeln(summary.overview);

    if (summary.sections.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('TOPIC BREAKDOWN');
      for (final section in summary.sections) {
        buffer.writeln(
          '[${_formatTime(section.startSec)}] ${section.heading}: ${section.summary}',
        );
      }
    }

    if (summary.keyPoints.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('KEY TAKEAWAYS');
      for (final point in summary.keyPoints) {
        buffer.writeln('• $point');
      }
    }

    if (summary.keyTerms.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('KEY TERMINOLOGY');
      for (final term in summary.keyTerms) {
        buffer.writeln('- ${term.term}: ${term.definition}');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم نسخ الملخص إلى الحافظة' : 'Summary copied to clipboard',
        ),
      ),
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
            onTap: () => _seekToSeconds(seg.startSec),
            onLongPress: () => _showEditSegmentDialog(qayd, index, seg, isArabic),
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
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: isArabic ? 'تعديل المقطع' : 'Edit Segment',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        _showEditSegmentDialog(qayd, index, seg, isArabic),
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

  void _showEditSegmentDialog(
    Qayd qayd,
    int segmentIndex,
    TranscriptSegment segment,
    bool isArabic,
  ) {
    final controller = TextEditingController(text: segment.text);
    final provider = context.read<QaydProvider>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic
              ? 'تعديل المقطع [${_formatTime(segment.startSec)}]'
              : 'Edit Segment [${_formatTime(segment.startSec)}]',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
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
              if (controller.text.trim().isNotEmpty) {
                provider.editTranscriptSegment(
                  qayd.id,
                  segmentIndex,
                  controller.text,
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers (Rename, Move, Edit, Delete)
  // ---------------------------------------------------------------------------
  void _handleMenuAction(String action, Qayd qayd) {
    if (action == 'rename') {
      showRenameQaydDialog(context, qayd);
    } else if (action == 'edit_transcript') {
      showEditTranscriptDialog(context, qayd);
    } else if (action == 'folder') {
      showMoveToFolderDialog(context, qayd);
    } else if (action == 'delete') {
      final navigator = Navigator.of(context);
      showDeleteQaydDialog(
        context,
        qayd,
        beforeDelete: () async {
          try {
            await _audioPlayer.stop();
          } catch (_) {
            // Audio plugin may be unavailable in headless tests or uninitialized state
          }
        },
        onDeleted: () {
          if (mounted) {
            navigator.pop();
          }
        },
      );
    }
  }
}
