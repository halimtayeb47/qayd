import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/data/models/qayd_model.dart';
import 'package:qayd/data/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleQayd = Qayd(
    id: 'test-qayd-123',
    title: 'نظم التشغيل والمزامنة بين الخيوط البرمجية',
    createdAt: DateTime(2026, 11, 13, 10, 30),
    durationSec: 120,
    audioPath: '',
    language: QaydLanguage.mixed,
    summaryLanguage: 'ar',
    transcript:
        'ومن وسائل الثبات على الحق والهدى أن يحرص المرء على الرفقة والأصحاب حرصا عظيما، ونظم التشغيل تعتمد على الـ Threads والـ Process.',
    segments: const [
      TranscriptSegment(
        startSec: 0.0,
        endSec: 17.5,
        text: 'ومن وسائل الثبات على الحق والهدى أن يحرص المرء على الرفقة والأصحاب حرصا عظيما',
      ),
      TranscriptSegment(
        startSec: 18.0,
        endSec: 35.0,
        text: 'وأن يتخير لنفسه من الأصحاب والأصدقاء من يكونون عونا له على الثبات',
      ),
      TranscriptSegment(
        startSec: 36.0,
        endSec: 60.0,
        text: 'شرح مفهوم Process و Thread والمزامنة بواسطة Mutex و Semaphore في بيئة التشغيل.',
      ),
    ],
    summary: const QaydSummary(
      overview:
          'محاضرة شاملة تشرح مفاهيم الاستقرار وأهمية الصحبة الإيجابية، بالإضافة إلى المفاهيم التقنية المتقدمة لإدارة العمليات والخيوط المتزامنة في نظم التشغيل.',
      sections: [
        SummarySection(
          heading: 'مقدمة في الثبات وحسن الاختيار',
          startSec: 0.0,
          summary: 'التركيز على انتقاء الرفقاء الصالحين كأكبر معين على الاستقامة والثبات.',
        ),
        SummarySection(
          heading: 'مقارنة بين Process و Thread',
          startSec: 36.0,
          summary: 'توضيح الفروق الجوهرية في استهلاك الذاكرة وسرعة الـ Context Switch.',
        ),
      ],
      keyPoints: [
        'الصحبة الصالحة هي السند الحقيقي للاستقامة والثبات في أوقات الفتن.',
        'الـ Process تمتلك مساحة عنونة منفصلة تماماً، بينما الـ Threads تتشارك الـ Heap.',
        'استخدام Mutex يمنع Race Condition عند الكتابة المتزامنة في الذاكرة المشتركة.',
      ],
      keyTerms: [
        KeyTerm(
          term: 'Process',
          definition: 'برنامج قيد التشغيل يمتلك مساحة ذاكرة وموارد نظام معزولة.',
        ),
        KeyTerm(
          term: 'Thread',
          definition: 'وحدة تنفيذ خفيفة الوزن تشترك في الذاكرة مع خيوط العملية الواحدة.',
        ),
      ],
    ),
  );

  test('PdfExportService.stripTashkeel strips diacritics cleanly', () {
    const input = 'قَيِّدُوا الْعِلْمَ بِالْكِتَابِ';
    final stripped = PdfExportService.stripTashkeel(input);
    expect(stripped, equals('قيدوا العلم بالكتاب'));
  });

  test('PdfExportService.shapePdfText shapes Arabic into Presentation Forms and keeps English', () {
    const input = 'شرح الـ Process والـ Thread';
    final shaped = PdfExportService.shapePdfText(input);

    expect(shaped.contains('Process'), isTrue);
    expect(shaped.contains('Thread'), isTrue);

    // Verify Arabic characters are converted to presentation forms (0xFE70 - 0xFEFF)
    final hasPresentationForms = shaped.runes.any(
      (r) => (r >= 0xFB50 && r <= 0xFDFF) || (r >= 0xFE70 && r <= 0xFEFF),
    );
    expect(hasPresentationForms, isTrue);
  });

  test('PdfExportService.shapePdfText spells words forward in natural reading order', () {
    const input = 'قيد';
    final shaped = PdfExportService.shapePdfText(input);

    // Qaf initial (0xFED7), Yeh medial (0xFEF4), Dal final (0xFEAA)
    final runes = shaped.runes.toList();
    expect(runes, equals([0xFED7, 0xFEF4, 0xFEAA]));
  });

  test('PdfExportService generates Academic Summary PDF successfully', () async {
    final bytes = await PdfExportService.generateSummaryPdf(sampleQayd);
    expect(bytes.isNotEmpty, true);
    expect(bytes.length, greaterThan(1000));
  });

  test('PdfExportService generates Full Transcript PDF with segments', () async {
    final bytes = await PdfExportService.generateTranscriptPdf(sampleQayd);
    expect(bytes.isNotEmpty, true);
    expect(bytes.length, greaterThan(1000));
  });

  test('PdfExportService generates Complete Lecture Notes PDF', () async {
    final bytes = await PdfExportService.generateFullLecturePdf(sampleQayd);
    expect(bytes.isNotEmpty, true);
    expect(bytes.length, greaterThan(1000));
  });

  test('PdfExportService generates English PDF when summaryLanguage is en', () async {
    final englishQayd = sampleQayd.copyWith(
      summaryLanguage: 'en',
      title: 'Operating Systems - Concurrency',
    );
    final bytes = await PdfExportService.generateSummaryPdf(englishQayd);
    expect(bytes.isNotEmpty, true);
    expect(bytes.length, greaterThan(1000));
  });
}
