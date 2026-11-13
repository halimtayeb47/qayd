// ==============================================================================
// Qayd PDF Export Service
// File: lib/data/services/pdf_export_service.dart
//
// Generates publication-grade academic PDF documents for:
// 1. Academic Summarization (Overview, Topic Breakdown, Key Points, Terms)
// 2. Full Transcript (Timestamped segments [MM:SS] with RTL/LTR support)
// 3. Complete Lecture Notes (Combined Summary + Transcript)
//
// Features official Qayd branding at the top (logo + bilingual title) and
// high-fidelity Arabic typography with contextual glyph shaping and ligature
// joining (Arabic Presentation Forms).
// ==============================================================================

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ignore: implementation_imports
import 'package:pdf/src/pdf/font/arabic.dart' as pdf_arabic;
import 'package:printing/printing.dart';
import '../models/qayd_model.dart';

enum PdfExportType {
  summary,
  transcript,
  full,
}

class PdfExportService {
  // Brand color palette matching Qayd UI design
  static const PdfColor _colorPrimary = PdfColor.fromInt(0xFF1E293B); // Slate 800
  static const PdfColor _colorSecondary = PdfColor.fromInt(0xFF0D9488); // Teal 600
  static const PdfColor _colorAccent = PdfColor.fromInt(0xFF4F46E5); // Indigo 600
  static const PdfColor _colorSurface = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
  static const PdfColor _colorBorder = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const PdfColor _colorTextPrimary = PdfColor.fromInt(0xFF0F172A); // Slate 900
  static const PdfColor _colorTextMuted = PdfColor.fromInt(0xFF64748B); // Slate 500
  static const PdfColor _colorBadgeBg = PdfColor.fromInt(0xFFEEF2F6); // Soft gray

  /// Strips Arabic diacritics (harakat / tashkeel) and tatweel to allow clean cursive font shaping.
  static String stripTashkeel(String input) {
    return input.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  }

  /// Shapes Arabic text for PDF rendering by stripping tashkeel, converting to
  /// contextual presentation forms, and maintaining correct forward letter order.
  /// Pure English or non-Arabic text is returned unchanged.
  static String shapePdfText(String text) {
    if (text.isEmpty) return text;
    final hasArabic = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(text);
    if (!hasArabic) return text;

    final converted = pdf_arabic.convert(stripTashkeel(text));
    // pdf_arabic.convert reverses characters inside Arabic words; un-reverse them so
    // each word is spelled forward in connected Presentation Forms.
    final words = converted.split(' ');
    final unreversed = words.map((w) {
      if (w.isEmpty) return w;
      var wordContent = w;
      var prefix = '';
      var suffix = '';

      final leadingMatch = RegExp(r'^[^\p{L}\p{N}]+', unicode: true).firstMatch(wordContent);
      if (leadingMatch != null) {
        prefix = leadingMatch.group(0)!;
        wordContent = wordContent.substring(prefix.length);
      }
      final trailingMatch = RegExp(r'[^\p{L}\p{N}]+$', unicode: true).firstMatch(wordContent);
      if (trailingMatch != null) {
        suffix = trailingMatch.group(0)!;
        wordContent = wordContent.substring(0, wordContent.length - suffix.length);
      }

      final hasPresForms = wordContent.runes.any((r) =>
          (r >= 0xFB50 && r <= 0xFDFF) ||
          (r >= 0xFE70 && r <= 0xFEFF) ||
          (r >= 0x0600 && r <= 0x06FF));
      if (hasPresForms) {
        return '${String.fromCharCodes(wordContent.runes.toList().reversed)}$prefix$suffix';
      }
      return w;
    }).join(' ');

    return unreversed;
  }

  /// Loads Cairo Arabic-compatible font family to support Arabic and English seamlessly.
  static Future<pw.ThemeData> _loadTheme() async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final semiBold = await PdfGoogleFonts.cairoSemiBold();

    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [semiBold, regular],
    );
  }

  /// Attempts to load the app icon logo from assets; returns null gracefully if missing.
  static Future<pw.MemoryImage?> _loadAppLogo() async {
    try {
      final bytes = await rootBundle.load('assets/icon/foreground.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _formatTimestamp(double seconds) {
    final totalSec = seconds < 0 ? 0 : seconds.floor();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Top Header with App Logo, App Name & Motto
  // ---------------------------------------------------------------------------
  static pw.Widget _buildHeader({
    required pw.MemoryImage? logoImage,
    required String documentBadge,
    required Qayd qayd,
    required bool isArabic,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _colorBorder, width: 1.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          // Top Row: App Logo + Title & Document Type Badge
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo + Bilingual Brand Name
              pw.Row(
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 38,
                      height: 38,
                      margin: const pw.EdgeInsets.only(right: 10),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Image(logoImage),
                    )
                  else
                    pw.Container(
                      width: 38,
                      height: 38,
                      margin: const pw.EdgeInsets.only(right: 10),
                      decoration: pw.BoxDecoration(
                        color: _colorSecondary,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'ق',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shapePdfText('Qayd • قيد'),
                        style: pw.TextStyle(
                          color: _colorPrimary,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        shapePdfText('قيدوا العلم بالكتاب • AI Lecture Notes'),
                        style: const pw.TextStyle(
                          color: _colorTextMuted,
                          fontSize: 9,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),

              // Document Category Badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _colorBadgeBg,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: _colorBorder, width: 0.8),
                ),
                child: pw.Text(
                  shapePdfText(documentBadge),
                  style: pw.TextStyle(
                    color: _colorSecondary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // Lecture Title
          pw.Text(
            shapePdfText(
              qayd.title.isNotEmpty
                  ? qayd.title
                  : (isArabic ? 'محاضرة بدون عنوان' : 'Untitled Lecture'),
            ),
            style: pw.TextStyle(
              color: _colorTextPrimary,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
          ),

          pw.SizedBox(height: 6),

          // Metadata Row: Date • Duration • Language
          pw.Row(
            mainAxisAlignment:
                isArabic ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
            children: [
              _buildMetaItem(
                label: isArabic ? 'التاريخ' : 'Date',
                value: _formatDate(qayd.createdAt),
                isArabic: isArabic,
              ),
              pw.SizedBox(width: 14),
              _buildMetaItem(
                label: isArabic ? 'المدة' : 'Duration',
                value: _formatDuration(qayd.durationSec),
                isArabic: isArabic,
              ),
              pw.SizedBox(width: 14),
              _buildMetaItem(
                label: isArabic ? 'اللغة' : 'Language',
                value: qayd.summaryLanguage == 'ar'
                    ? (isArabic ? 'العربية' : 'Arabic')
                    : (isArabic ? 'الإنجليزية' : 'English'),
                isArabic: isArabic,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaItem({
    required String label,
    required String value,
    required bool isArabic,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          shapePdfText('$label: '),
          style: const pw.TextStyle(
            color: _colorTextMuted,
            fontSize: 9,
          ),
          textDirection:
              isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.Text(
          shapePdfText(value),
          style: pw.TextStyle(
            color: _colorTextPrimary,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          textDirection:
              isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Page Footer with Page Numbers
  // ---------------------------------------------------------------------------
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _colorBorder, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            shapePdfText('Qayd • تم التصدير عبر تطبيق قيد لتدوين المحاضرات بالذكاء الاصطناعي'),
            style: const pw.TextStyle(color: _colorTextMuted, fontSize: 8),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              color: _colorTextMuted,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Export Academic Summary PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generateSummaryPdf(Qayd qayd) async {
    final pdf = pw.Document();
    final theme = await _loadTheme();
    final logoImage = await _loadAppLogo();
    final isArabic = qayd.summaryLanguage == 'ar';
    final summary = qayd.summary;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          logoImage: logoImage,
          documentBadge: isArabic ? 'الملخص الأكاديمي' : 'Academic Summary',
          qayd: qayd,
          isArabic: isArabic,
        ),
        footer: _buildFooter,
        build: (context) {
          final content = <pw.Widget>[];

          if (summary == null) {
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  shapePdfText(
                    isArabic
                        ? 'لا يتوفر ملخص أكاديمي لهذه المحاضرة بعد.'
                        : 'No academic summary is available for this lecture yet.',
                  ),
                  style: const pw.TextStyle(color: _colorTextMuted, fontSize: 11),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
            );
            return [
              pw.Directionality(
                textDirection:
                    isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Column(children: content),
              )
            ];
          }

          // Section 1: Overview
          if (summary.overview.isNotEmpty) {
            content.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _colorSecondary, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: isArabic
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: isArabic
                          ? pw.MainAxisAlignment.end
                          : pw.MainAxisAlignment.start,
                      children: [
                        if (!isArabic) ...[
                          pw.Container(
                            width: 8,
                            height: 8,
                            margin: const pw.EdgeInsets.only(right: 6),
                            decoration: const pw.BoxDecoration(
                              color: _colorSecondary,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ],
                        pw.Text(
                          shapePdfText(isArabic ? 'النظرة العامة' : 'Overview'),
                          style: pw.TextStyle(
                            color: _colorSecondary,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textDirection: isArabic
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                        ),
                        if (isArabic) ...[
                          pw.Container(
                            width: 8,
                            height: 8,
                            margin: const pw.EdgeInsets.only(left: 6),
                            decoration: const pw.BoxDecoration(
                              color: _colorSecondary,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      shapePdfText(summary.overview),
                      style: const pw.TextStyle(
                        color: _colorTextPrimary,
                        fontSize: 10.5,
                        lineSpacing: 3,
                      ),
                      textDirection: isArabic
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                      textAlign:
                          isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                  ],
                ),
              ),
            );
          }

          // Section 2: Topic Breakdown (Sections)
          if (summary.sections.isNotEmpty) {
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
                child: pw.Text(
                  shapePdfText(
                    isArabic ? 'المحاور والموضوعات' : 'Topic Breakdown',
                  ),
                  style: pw.TextStyle(
                    color: _colorPrimary,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign:
                      isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            );

            for (final section in summary.sections) {
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _colorBorder, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: isArabic
                        ? pw.CrossAxisAlignment.end
                        : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (!isArabic) ...[
                            // Timestamp pill (LTR)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: _colorPrimary,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                _formatTimestamp(section.startSec),
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(
                                shapePdfText(section.heading),
                                style: pw.TextStyle(
                                  color: _colorTextPrimary,
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Arabic (RTL): Heading first, pill on left
                            pw.Expanded(
                              child: pw.Text(
                                shapePdfText(section.heading),
                                style: pw.TextStyle(
                                  color: _colorTextPrimary,
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: _colorPrimary,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                _formatTimestamp(section.startSec),
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        shapePdfText(section.summary),
                        style: const pw.TextStyle(
                          color: _colorTextMuted,
                          fontSize: 10,
                          lineSpacing: 2.5,
                        ),
                        textDirection: isArabic
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        textAlign:
                            isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          // Section 3: Key Points
          if (summary.keyPoints.isNotEmpty) {
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12, bottom: 8),
                child: pw.Text(
                  shapePdfText(
                    isArabic ? 'أهم النقاط المستفادة' : 'Key Takeaways',
                  ),
                  style: pw.TextStyle(
                    color: _colorPrimary,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign:
                      isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            );

            for (final point in summary.keyPoints) {
              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (!isArabic) ...[
                        pw.Container(
                          width: 5,
                          height: 5,
                          margin: const pw.EdgeInsets.only(top: 5, right: 8),
                          decoration: const pw.BoxDecoration(
                            color: _colorAccent,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(point),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 10,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                      ] else ...[
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(point),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 10,
                              lineSpacing: 2,
                            ),
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Container(
                          width: 5,
                          height: 5,
                          margin: const pw.EdgeInsets.only(top: 5, left: 8),
                          decoration: const pw.BoxDecoration(
                            color: _colorAccent,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          }

          // Section 4: Key Terminology
          if (summary.keyTerms.isNotEmpty) {
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
                child: pw.Text(
                  shapePdfText(
                    isArabic
                        ? 'المصطلحات والمفاهيم العلمية'
                        : 'Key Terminology',
                  ),
                  style: pw.TextStyle(
                    color: _colorPrimary,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign:
                      isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            );

            for (final term in summary.keyTerms) {
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _colorSurface,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _colorBorder, width: 0.6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (!isArabic) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: _colorBorder, width: 0.5),
                          ),
                          child: pw.Text(
                            shapePdfText(term.term),
                            style: pw.TextStyle(
                              color: _colorSecondary,
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(term.definition),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 9.5,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                      ] else ...[
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(term.definition),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 9.5,
                              lineSpacing: 2,
                            ),
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: _colorBorder, width: 0.5),
                          ),
                          child: pw.Text(
                            shapePdfText(term.term),
                            style: pw.TextStyle(
                              color: _colorSecondary,
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          }

          return [
            pw.Directionality(
              textDirection:
                  isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: isArabic
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: content,
              ),
            )
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 2. Export Full Transcript PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generateTranscriptPdf(Qayd qayd) async {
    final pdf = pw.Document();
    final theme = await _loadTheme();
    final logoImage = await _loadAppLogo();

    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(qayd.transcript);
    final isArabic = qayd.summaryLanguage == 'ar' || hasArabic;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          logoImage: logoImage,
          documentBadge: isArabic ? 'التفريغ الصوتي' : 'Full Transcript',
          qayd: qayd,
          isArabic: isArabic,
        ),
        footer: _buildFooter,
        build: (context) {
          final content = <pw.Widget>[];

          if (qayd.segments.isNotEmpty) {
            content.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  shapePdfText(
                    isArabic
                        ? 'التفريغ الصوتي المرمز بالطوابع الزمنية (${qayd.segments.length} مقطع)'
                        : 'Timestamped Speech Segments (${qayd.segments.length} segments)',
                  ),
                  style: pw.TextStyle(
                    color: _colorPrimary,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign:
                      isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            );

            for (final seg in qayd.segments) {
              final segIsArabic =
                  RegExp(r'[\u0600-\u06FF]').hasMatch(seg.text);

              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _colorSurface,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _colorBorder, width: 0.6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (!segIsArabic) ...[
                        // LTR Segment: Timestamp on left, text on right
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _colorSecondary,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            _formatTimestamp(seg.startSec),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(seg.text),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 10,
                              lineSpacing: 2.5,
                            ),
                          ),
                        ),
                      ] else ...[
                        // RTL Segment: Text on right, timestamp on left
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(seg.text),
                            style: const pw.TextStyle(
                              color: _colorTextPrimary,
                              fontSize: 10,
                              lineSpacing: 2.5,
                            ),
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _colorSecondary,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            _formatTimestamp(seg.startSec),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          } else if (qayd.transcript.trim().isNotEmpty) {
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _colorBorder, width: 0.8),
                ),
                child: pw.Text(
                  shapePdfText(qayd.transcript),
                  style: const pw.TextStyle(
                    color: _colorTextPrimary,
                    fontSize: 10.5,
                    lineSpacing: 3,
                  ),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  textAlign:
                      isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            );
          } else {
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _colorSurface,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  shapePdfText(
                    isArabic
                        ? 'لا يوجد نص مفرغ لهذه المحاضرة.'
                        : 'No transcript text is available for this lecture.',
                  ),
                  style: const pw.TextStyle(color: _colorTextMuted, fontSize: 11),
                  textDirection:
                      isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                ),
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection:
                  isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: isArabic
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: content,
              ),
            )
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 3. Export Complete Lecture Notes PDF (Summary + Transcript)
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generateFullLecturePdf(Qayd qayd) async {
    final pdf = pw.Document();
    final theme = await _loadTheme();
    final logoImage = await _loadAppLogo();
    final isArabic = qayd.summaryLanguage == 'ar';
    final summary = qayd.summary;

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          logoImage: logoImage,
          documentBadge: isArabic ? 'المذكرة الشاملة' : 'Complete Lecture Notes',
          qayd: qayd,
          isArabic: isArabic,
        ),
        footer: _buildFooter,
        build: (context) {
          final content = <pw.Widget>[];

          // Part I: Academic Summary
          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _colorPrimary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                shapePdfText(
                  isArabic
                      ? 'الجزء الأول: الملخص الأكاديمي'
                      : 'Part I: Academic Summary',
                ),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection:
                    isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ),
          );

          if (summary != null) {
            if (summary.overview.isNotEmpty) {
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _colorSurface,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _colorSecondary, width: 0.8),
                  ),
                  child: pw.Text(
                    shapePdfText(summary.overview),
                    style: const pw.TextStyle(
                      color: _colorTextPrimary,
                      fontSize: 10,
                      lineSpacing: 2.5,
                    ),
                    textDirection:
                        isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    textAlign:
                        isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                ),
              );
            }

            if (summary.keyPoints.isNotEmpty) {
              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
                  child: pw.Text(
                    shapePdfText(
                      isArabic ? 'أهم النقاط المستفادة' : 'Key Takeaways',
                    ),
                    style: pw.TextStyle(
                      color: _colorPrimary,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection:
                        isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    textAlign:
                        isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                ),
              );

              for (final pt in summary.keyPoints) {
                content.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (!isArabic) ...[
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 5, right: 6),
                            decoration: const pw.BoxDecoration(
                              color: _colorAccent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              shapePdfText(pt),
                              style: const pw.TextStyle(
                                fontSize: 9.5,
                                lineSpacing: 2,
                              ),
                            ),
                          ),
                        ] else ...[
                          pw.Expanded(
                            child: pw.Text(
                              shapePdfText(pt),
                              style: const pw.TextStyle(
                                fontSize: 9.5,
                                lineSpacing: 2,
                              ),
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 5, left: 6),
                            decoration: const pw.BoxDecoration(
                              color: _colorAccent,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            }
          }

          content.add(pw.SizedBox(height: 18));

          // Part II: Full Transcript
          content.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _colorPrimary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                shapePdfText(
                  isArabic
                      ? 'الجزء الثاني: التفريغ الصوتي'
                      : 'Part II: Audio Transcript',
                ),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection:
                    isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ),
          );

          if (qayd.segments.isNotEmpty) {
            for (final seg in qayd.segments) {
              final segIsArabic =
                  RegExp(r'[\u0600-\u06FF]').hasMatch(seg.text);
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _colorSurface,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _colorBorder, width: 0.5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (!segIsArabic) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _colorSecondary,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            _formatTimestamp(seg.startSec),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(seg.text),
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                      ] else ...[
                        pw.Expanded(
                          child: pw.Text(
                            shapePdfText(seg.text),
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              lineSpacing: 2,
                            ),
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _colorSecondary,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            _formatTimestamp(seg.startSec),
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          } else if (qayd.transcript.isNotEmpty) {
            content.add(
              pw.Text(
                shapePdfText(qayd.transcript),
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 2.5),
                textDirection:
                    isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                textAlign:
                    isArabic ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection:
                  isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: isArabic
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: content,
              ),
            )
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Share & Print Helpers
  // ---------------------------------------------------------------------------
  static Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
    String? subject,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      subject: subject,
    );
  }

  static Future<void> printPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => bytes,
      name: filename,
    );
  }
}
