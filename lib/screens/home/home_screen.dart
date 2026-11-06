import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Row(
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
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
            tooltip: isArabic ? 'بحث' : 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              // Folders view
            },
            tooltip: isArabic ? 'المجلدات' : 'Folders',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Settings bottom sheet
            },
            tooltip: isArabic ? 'الإعدادات' : 'Settings',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 24),
              Text(
                isArabic ? 'لا توجد تسجيلات بعد' : 'No Qayds yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'ابدأ بتسجيل المحاضرة أو استيراد ملف صوتي لتقييد وتلخيص المحاضرة'
                    : 'Start recording or import an audio file to capture and summarize your lecture',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Navigate to New Qayd / Recording screen
                },
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'ابدأ قيداً جديداً' : 'Start New Qayd'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open record / import bottom sheet or screen
        },
        icon: const Icon(Icons.mic),
        label: Text(isArabic ? 'تسجيل جديد' : 'Record'),
      ),
    );
  }
}
