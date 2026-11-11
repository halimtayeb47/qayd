import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qayd/data/models/folder_model.dart';
import 'package:qayd/data/models/qayd_model.dart';
import 'package:qayd/data/services/audio_picker_service.dart';
import 'package:qayd/data/services/audio_recording_service.dart';
import 'package:qayd/data/services/gemini_summary_service.dart';
import 'package:qayd/data/services/groq_whisper_service.dart';
import 'package:qayd/data/services/storage_service.dart';
import 'package:qayd/providers/qayd_provider.dart';
import 'package:qayd/screens/home/home_screen.dart';

class FakeStorage extends StorageService {
  final Map<String, Qayd> qayds = {};
  final Map<String, QaydFolder> folders = {};
  bool _seeded = true;

  @override
  bool get hasSeededDemo => _seeded;

  @override
  Future<void> markDemoSeeded() async {
    _seeded = true;
  }

  @override
  Qayd? getQayd(String id) => qayds[id];

  @override
  List<Qayd> getAllQayds() => qayds.values.toList();

  @override
  List<Qayd> getQaydsByFolder(String? folderId) =>
      qayds.values.where((q) => q.folderId == folderId).toList();

  @override
  List<QaydFolder> getAllFolders() => folders.values.toList();

  @override
  Future<void> saveQayd(Qayd qayd) async {
    qayds[qayd.id] = qayd;
  }

  @override
  Future<void> deleteQayd(String id) async {
    qayds.remove(id);
  }

  @override
  Future<void> saveFolder(QaydFolder folder) async {
    folders[folder.id] = folder;
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    for (final qayd in getQaydsByFolder(folderId)) {
      await saveQayd(qayd.copyWith(clearFolderId: true));
    }
    folders.remove(folderId);
  }
}

void main() {
  testWidgets('HomeScreen card & folder actions rename, move, edit, and delete',
      (tester) async {
    final storage = FakeStorage();
    await storage.saveFolder(
      QaydFolder(id: 'f1', name: 'Networks', createdAt: DateTime(2026)),
    );
    await storage.saveQayd(
      Qayd(
        id: 'q1',
        title: 'Test Lecture',
        createdAt: DateTime(2026),
        durationSec: 60,
        audioPath: '',
        transcript: 'Hello world.',
        status: QaydStatus.done,
      ),
    );

    final provider = QaydProvider(
      storageService: storage,
      whisperService: GroqWhisperService(),
      summaryService: GeminiSummaryService(),
      recordingService: AudioRecordingService(),
      pickerService: AudioPickerService(),
    )..loadInitialData();

    await tester.pumpWidget(
      ChangeNotifierProvider<QaydProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Rename Folder via chip options icon
    await tester.tap(find.byTooltip('Folder options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename Folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Computer Networks');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(provider.folders.first.name, 'Computer Networks');

    // 2. Rename Qayd from HomeScreen card menu
    await tester.tap(find.byTooltip('Qayd options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Home Renamed Lecture');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(provider.qayds.first.title, 'Home Renamed Lecture');

    // 3. Move to Folder from HomeScreen card menu & check badge renders
    await tester.tap(find.byTooltip('Qayd options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer Networks').last);
    await tester.pumpAndSettle();
    expect(provider.qayds.first.folderId, 'f1');

    // 4. Edit Transcript from HomeScreen card menu
    await tester.tap(find.byTooltip('Qayd options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Transcript'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Edited on home.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(provider.qayds.first.transcript, 'Edited on home.');

    // 5. Delete Qayd from HomeScreen card menu -> stays empty (no demo resurrection)
    await tester.tap(find.byTooltip('Qayd options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(provider.qayds, isEmpty);

    // 6. Delete Folder -> stays empty with no demo resurrection
    await tester.tap(find.byTooltip('Folder options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(provider.folders, isEmpty);
    expect(provider.qayds, isEmpty);
  });

  testWidgets('DetailScreen rename, edit, move, and delete actions work',
      (tester) async {
    final storage = FakeStorage();
    final folder = QaydFolder(
      id: 'f1',
      name: 'Networks',
      createdAt: DateTime(2026),
    );
    final qayd = Qayd(
      id: 'q1',
      title: 'Test Lecture',
      createdAt: DateTime(2026),
      durationSec: 60,
      audioPath: '',
      transcript: 'Hello world.',
      status: QaydStatus.done,
    );
    await storage.saveFolder(folder);
    await storage.saveQayd(qayd);

    final provider = QaydProvider(
      storageService: storage,
      whisperService: GroqWhisperService(),
      summaryService: GeminiSummaryService(),
      recordingService: AudioRecordingService(),
      pickerService: AudioPickerService(),
    )..loadInitialData();

    await tester.pumpWidget(
      ChangeNotifierProvider<QaydProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate from HomeScreen into DetailScreen
    await tester.tap(find.text('Test Lecture'));
    await tester.pumpAndSettle();

    // 1. Rename
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed Lecture');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(provider.qayds.first.title, 'Renamed Lecture');

    // 2. Move to Folder
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Networks'));
    await tester.pumpAndSettle();
    expect(provider.qayds.first.folderId, 'f1');

    // 3. Edit Transcript
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Transcript'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated transcript text.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(provider.qayds.first.transcript, 'Updated transcript text.');

    // 4. Delete returns cleanly to HomeScreen and keeps list empty
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(provider.qayds, isEmpty);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('DetailScreen hides empty Breakdown, Key Points, and Key Terms cards',
      (tester) async {
    final storage = FakeStorage();
    await storage.saveQayd(
      Qayd(
        id: 'q2',
        title: 'Quick Greeting',
        createdAt: DateTime(2026),
        durationSec: 4,
        audioPath: '',
        transcript: 'Hi! how are you?',
        status: QaydStatus.done,
        summary: const QaydSummary(
          overview: 'A brief casual greeting between speakers.',
          sections: [],
          keyPoints: [],
          keyTerms: [],
        ),
      ),
    );

    final provider = QaydProvider(
      storageService: storage,
      whisperService: GroqWhisperService(),
      summaryService: GeminiSummaryService(),
      recordingService: AudioRecordingService(),
      pickerService: AudioPickerService(),
    )..loadInitialData();

    await tester.pumpWidget(
      ChangeNotifierProvider<QaydProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quick Greeting'));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('A brief casual greeting between speakers.'), findsOneWidget);
    expect(find.text('Topic Breakdown'), findsNothing);
    expect(find.text('Key Points & Takeaways'), findsNothing);
    expect(find.text('Key Terminology'), findsNothing);
  });
}
