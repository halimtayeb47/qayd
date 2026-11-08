import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/data/models/qayd_model.dart';
import 'package:qayd/data/models/folder_model.dart';

void main() {
  group('Qayd Model Tests', () {
    test('TranscriptSegment serialization round-trip', () {
      const segment = TranscriptSegment(
        startSec: 2.74,
        endSec: 8.54,
        text: 'أحد أشهر المفاهيم في البرمجة هو الـ API',
      );

      final map = segment.toMap();
      final recovered = TranscriptSegment.fromMap(map);

      expect(recovered.startSec, 2.74);
      expect(recovered.endSec, 8.54);
      expect(recovered.text, 'أحد أشهر المفاهيم في البرمجة هو الـ API');
    });

    test('QaydSummary with KeyTerms serialization round-trip', () {
      const summary = QaydSummary(
        overview: 'Overview of modern web architecture with APIs.',
        keyPoints: [
          'APIs separate frontend from backend.',
          'Servers return structured JSON data rather than full HTML pages.',
        ],
        keyTerms: [
          KeyTerm(
            term: 'API',
            definition: 'Application Programming Interface connecting services.',
          ),
        ],
      );

      final map = summary.toMap();
      final recovered = QaydSummary.fromMap(map);

      expect(recovered.overview, summary.overview);
      expect(recovered.keyPoints.length, 2);
      expect(recovered.keyTerms.first.term, 'API');
    });

    test('Complete Qayd entity serialization and copyWith', () {
      final now = DateTime.now();
      final qayd = Qayd(
        id: 'qayd-123',
        title: 'Database Architecture Lecture',
        createdAt: now,
        durationSec: 1800,
        audioPath: '/data/audio/lecture1.m4a',
        language: QaydLanguage.mixed,
        transcript: 'Introduction to backend and APIs...',
        segments: const [
          TranscriptSegment(startSec: 0.0, endSec: 4.5, text: 'Hello everyone'),
        ],
        status: QaydStatus.done,
      );

      final map = qayd.toMap();
      final recovered = Qayd.fromMap(map);

      expect(recovered.id, 'qayd-123');
      expect(recovered.title, 'Database Architecture Lecture');
      expect(recovered.language, QaydLanguage.mixed);
      expect(recovered.segments.length, 1);
      expect(recovered.status, QaydStatus.done);

      // Test copyWith
      final updated = qayd.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.id, 'qayd-123');
    });

    test('QaydFolder serialization', () {
      final folder = QaydFolder(
        id: 'folder-1',
        name: 'Mobile Development',
        createdAt: DateTime.now(),
      );

      final map = folder.toMap();
      final recovered = QaydFolder.fromMap(map);

      expect(recovered.id, 'folder-1');
      expect(recovered.name, 'Mobile Development');
    });
  });
}
