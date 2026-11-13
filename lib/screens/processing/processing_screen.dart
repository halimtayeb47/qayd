// ==============================================================================
// Processing Screen (S3)
// File: lib/screens/processing/processing_screen.dart
//
// Shows real-time progress for audio transcription and academic summarization.
// Enforces the core reliability invariant: work is never lost if summary fails.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/qayd_model.dart';
import '../../providers/qayd_provider.dart';
import '../detail/detail_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _hasNavigatedToDetail = false;

  void _checkAutoNavigate(Qayd? qayd) {
    if (qayd != null && qayd.status == QaydStatus.done && !_hasNavigatedToDetail) {
      _hasNavigatedToDetail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(qaydId: qayd.id),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QaydProvider>();
    final activeQayd = provider.activeQayd;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    _checkAutoNavigate(activeQayd);

    final hasError = provider.errorMessage != null;
    final isDone = activeQayd?.status == QaydStatus.done;
    final hasTranscript = activeQayd != null && activeQayd.transcript.isNotEmpty;

    return PopScope(
      canPop: isDone || hasError,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'معالجة المحاضرة' : 'Processing Lecture'),
          centerTitle: true,
          automaticallyImplyLeading: isDone || hasError,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Status Icon
                  if (hasError)
                    Icon(
                      Icons.error_outline,
                      size: 84,
                      color: theme.colorScheme.error,
                    )
                  else if (isDone)
                    Icon(
                      Icons.check_circle_outline,
                      size: 84,
                      color: theme.colorScheme.secondary,
                    )
                  else
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: provider.processingProgress > 0
                            ? provider.processingProgress
                            : null,
                        strokeWidth: 6,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Processing Step Title
                  Text(
                    hasError
                        ? (isArabic ? 'حدث خطأ أثناء المعالجة' : 'Processing Encountered an Issue')
                        : isDone
                            ? (isArabic ? 'اكتملت المعالجة بنجاح!' : 'Processing Complete!')
                            : (isArabic ? 'جاري تقييد وتلخيص المحاضرة' : 'Tethering & Summarizing Lecture'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detailed Status Message
                  Text(
                    hasError
                        ? provider.errorMessage!
                        : provider.processingStatusMessage,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasError
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pipeline Stages Progress Checklist
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 20.0,
                      ),
                      child: Column(
                        children: [
                          _buildStageRow(
                            title: isArabic
                                ? 'تحويل الصوت إلى نص (Groq Whisper)'
                                : 'Speech-to-Text (Groq Whisper)',
                            isCompleted: hasTranscript || isDone,
                            isActive: !hasTranscript && !hasError && !isDone,
                            theme: theme,
                          ),
                          const Divider(height: 24),
                          _buildStageRow(
                            title: isArabic
                                ? 'حفظ وتثبيت النص محلياً'
                                : 'Preserve Transcript Locally',
                            isCompleted: hasTranscript || isDone,
                            isActive: false,
                            theme: theme,
                          ),
                          const Divider(height: 24),
                          _buildStageRow(
                            title: isArabic
                                ? 'التلخيص الأكاديمي (Google Gemini)'
                                : 'Academic Summary (Google Gemini)',
                            isCompleted: isDone,
                            isActive: hasTranscript && !isDone && !hasError,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions upon Completion or Error
                  if (hasError && hasTranscript) ...[
                    // Recovery Action 1: View Transcript (Transcript is never lost!)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(qaydId: activeQayd.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description),
                      label: Text(
                        isArabic ? 'عرض النص المفرغ المحفوظ' : 'View Saved Transcript',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Recovery Action 2: Retry Summary
                    OutlinedButton.icon(
                      onPressed: () {
                        provider.retrySummary(activeQayd.id);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        isArabic ? 'إعادة محاولة التلخيص' : 'Retry Summary',
                      ),
                    ),
                  ] else if (isDone) ...[
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(qaydId: activeQayd!.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        isArabic ? 'فتح ملخص المحاضرة' : 'Open Lecture Notes',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageRow({
    required String title,
    required bool isCompleted,
    required bool isActive,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        if (isCompleted)
          Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 22)
        else if (isActive)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.primary,
            ),
          )
        else
          Icon(Icons.circle_outlined, color: theme.colorScheme.outlineVariant, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isCompleted
                  ? theme.colorScheme.onSurface
                  : isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
