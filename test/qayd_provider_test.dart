// ==============================================================================
// Qayd Provider Unit Tests
// File: test/qayd_provider_test.dart
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/data/models/folder_model.dart';
import 'package:qayd/data/models/qayd_model.dart';
import 'package:qayd/data/services/audio_picker_service.dart';
import 'package:qayd/data/services/audio_recording_service.dart';
import 'package:qayd/data/services/gemini_summary_service.dart';
import 'package:qayd/data/services/groq_whisper_service.dart';
import 'package:qayd/data/services/storage_service.dart';
import 'package:qayd/providers/qayd_provider.dart';

class MockStorageService extends StorageService {
  final List<Qayd> _qayds = [];
  final List<QaydFolder> _folders = [];

  @override
  List<Qayd> getAllQayds() => List.unmodifiable(_qayds);

  @override
  List<QaydFolder> getAllFolders() => List.unmodifiable(_folders);

  @override
  Future<void> saveQayd(Qayd qayd) async {
    _qayds.removeWhere((q) => q.id == qayd.id);
    _qayds.add(qayd);
  }

  @override
  Future<void> saveFolder(QaydFolder folder) async {
    _folders.removeWhere((f) => f.id == folder.id);
    _folders.add(folder);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QaydProvider Unit Tests', () {
    late MockStorageService mockStorage;
    late QaydProvider provider;

    setUp(() {
      mockStorage = MockStorageService();
      provider = QaydProvider(
        storageService: mockStorage,
        whisperService: GroqWhisperService(),
        summaryService: GeminiSummaryService(),
        recordingService: AudioRecordingService(),
        pickerService: AudioPickerService(),
      );
    });

    test('Locale and Theme toggling works correctly (FR7)', () {
      expect(provider.currentLocale.languageCode, 'en');
      provider.toggleLocale();
      expect(provider.currentLocale.languageCode, 'ar');
      provider.toggleLocale();
      expect(provider.currentLocale.languageCode, 'en');

      expect(provider.isDarkMode, false);
      provider.toggleTheme();
      expect(provider.isDarkMode, true);
      provider.toggleTheme();
      expect(provider.isDarkMode, false);
    });

    test('Loads and seeds demo data when storage is empty', () async {
      provider.loadInitialData();
      // Allow async seeding to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.folders.isNotEmpty, true);
      expect(provider.folders.first.name, 'Operating Systems');

      expect(provider.qayds.isNotEmpty, true);
      expect(provider.qayds.first.title, contains('CS341'));
      expect(provider.qayds.first.summary, isNotNull);
      expect(provider.qayds.first.segments.length, 5);
    });

    test('Filters Qayds by search query correctly', () async {
      provider.loadInitialData();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      provider.setSearchQuery('threads');
      expect(provider.qayds.length, 1);

      provider.setSearchQuery('non_existent_query_xyz');
      expect(provider.qayds.isEmpty, true);

      provider.setSearchQuery('');
      expect(provider.qayds.isNotEmpty, true);
    });
  });
}
