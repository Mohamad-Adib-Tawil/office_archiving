import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

enum OcrLanguageProfile { auto, mixed, arabic, english }

class ProfessionalOcrOptions {
  const ProfessionalOcrOptions({
    this.languageProfile = OcrLanguageProfile.auto,
    this.enableOrientationSweep = true,
    this.enableBinaryVariant = true,
    this.enableDocumentVariant = true,
    this.preferredLongSide = 1800,
    this.maxLongSide = 2600,
    this.pdfMaxPages = 3,
    this.pdfDpi = 96,
    this.pdfMaxFileSizeBytes = 12 * 1024 * 1024,
  });

  final OcrLanguageProfile languageProfile;
  final bool enableOrientationSweep;
  final bool enableBinaryVariant;
  final bool enableDocumentVariant;
  final int preferredLongSide;
  final int maxLongSide;
  final int pdfMaxPages;
  final int pdfDpi;
  final int pdfMaxFileSizeBytes;
}

class OcrCandidateSummary {
  const OcrCandidateSummary({
    required this.backend,
    required this.variant,
    required this.angle,
    required this.score,
    required this.preview,
  });

  final String backend;
  final String variant;
  final int angle;
  final int score;
  final String preview;
}

class ProfessionalOcrResult {
  const ProfessionalOcrResult({
    required this.text,
    required this.profile,
    required this.primaryBackend,
    required this.primaryVariant,
    required this.primaryAngle,
    required this.score,
    required this.candidates,
  });

  final String text;
  final OcrLanguageProfile profile;
  final String primaryBackend;
  final String primaryVariant;
  final int primaryAngle;
  final int score;
  final List<OcrCandidateSummary> candidates;
}

class ProfessionalOcrService {
  ProfessionalOcrService._();

  static final ProfessionalOcrService instance = ProfessionalOcrService._();

  late final TextRecognizer _latinRecognizer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initialized = true;
  }

  Future<ProfessionalOcrResult> recognizeImage(
    String imagePath, {
    ProfessionalOcrOptions options = const ProfessionalOcrOptions(),
  }) async {
    await initialize();

    final sourceFile = File(imagePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Image file does not exist', imagePath);
    }

    final profile = _normalizeProfile(options.languageProfile);
    final variants = await _buildVariants(imagePath, options);
    final candidates = <_OcrCandidate>[];

    try {
      for (final variant in variants) {
        candidates.addAll(
          await _recognizeVariant(variant, profile: profile, angles: const [0]),
        );
      }

      if (candidates.isEmpty) {
        return ProfessionalOcrResult(
          text: '',
          profile: profile,
          primaryBackend: 'none',
          primaryVariant: 'none',
          primaryAngle: 0,
          score: 0,
          candidates: const [],
        );
      }

      final bestInitial = _bestCandidate(candidates)!;
      if (options.enableOrientationSweep &&
          _shouldRunOrientationSweep(bestInitial, profile)) {
        final bestVariant = variants.firstWhere(
          (variant) => variant.name == bestInitial.variant,
          orElse: () => variants.first,
        );
        candidates.addAll(
          await _recognizeVariant(
            bestVariant,
            profile: profile,
            angles: const [-4, 4, 90, 180, 270],
          ),
        );
      }

      final bestCandidate = _bestCandidate(candidates)!;
      final finalText = _composeFinalText(candidates, profile);
      final finalScore = _scoreText(finalText, profile: profile);

      return ProfessionalOcrResult(
        text: finalText,
        profile: profile,
        primaryBackend: bestCandidate.backend.label,
        primaryVariant: bestCandidate.variant,
        primaryAngle: bestCandidate.angle,
        score: finalScore,
        candidates: candidates
            .map(
              (candidate) => OcrCandidateSummary(
                backend: candidate.backend.label,
                variant: candidate.variant,
                angle: candidate.angle,
                score: candidate.score,
                preview: _preview(candidate.text),
              ),
            )
            .toList(growable: false),
      );
    } finally {
      for (final variant in variants) {
        if (variant.deleteAfterUse) {
          await _deleteTempFile(variant.file);
        }
      }
    }
  }

  Future<ProfessionalOcrResult> recognizePdf(
    String pdfPath, {
    ProfessionalOcrOptions options = const ProfessionalOcrOptions(),
  }) async {
    final sourceFile = File(pdfPath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('PDF file does not exist', pdfPath);
    }

    final fileSize = await sourceFile.length();
    if (fileSize > options.pdfMaxFileSizeBytes) {
      log(
        'Professional OCR skipped large PDF: '
        'path=$pdfPath size=$fileSize limit=${options.pdfMaxFileSizeBytes}',
      );
      return ProfessionalOcrResult(
        text: '',
        profile: _normalizeProfile(options.languageProfile),
        primaryBackend: 'skipped',
        primaryVariant: 'pdf_guard',
        primaryAngle: 0,
        score: 0,
        candidates: const [],
      );
    }

    final data = await sourceFile.readAsBytes();
    final pages = Printing.raster(data, dpi: options.pdfDpi.toDouble());
    final buffer = StringBuffer();
    final summaries = <OcrCandidateSummary>[];
    var pageIndex = 1;

    await for (final page in pages) {
      if (pageIndex > options.pdfMaxPages) {
        break;
      }

      final pngBytes = await page.toPng();
      final tempImage = await _writeTempFile(
        pngBytes,
        suffix: '_pdf_page_$pageIndex.png',
      );

      try {
        final result = await recognizeImage(tempImage.path, options: options);
        if (result.text.trim().isNotEmpty) {
          buffer.writeln('--- Page $pageIndex ---');
          buffer.writeln(result.text.trim());
          buffer.writeln();
        }
        summaries.addAll(result.candidates);
      } finally {
        await _deleteTempFile(tempImage);
      }

      pageIndex++;
    }

    final finalText = buffer.toString().trim();
    return ProfessionalOcrResult(
      text: finalText,
      profile: _normalizeProfile(options.languageProfile),
      primaryBackend: summaries.isNotEmpty ? summaries.first.backend : 'none',
      primaryVariant: summaries.isNotEmpty ? summaries.first.variant : 'none',
      primaryAngle: summaries.isNotEmpty ? summaries.first.angle : 0,
      score: _scoreText(
        finalText,
        profile: _normalizeProfile(options.languageProfile),
      ),
      candidates: summaries,
    );
  }

  Future<Map<String, dynamic>> extractLatinDetails(String imagePath) async {
    await initialize();
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _latinRecognizer.processImage(inputImage);
    final blocks = recognizedText.blocks
        .map(
          (block) => {
            'text': block.text,
            'lines': block.lines.map((line) => {'text': line.text}).toList(),
          },
        )
        .toList();

    return {
      'fullText': recognizedText.text,
      'blocks': blocks,
      'totalBlocks': blocks.length,
      'hasText': recognizedText.text.trim().isNotEmpty,
    };
  }

  Future<bool> isLatinTextDetected(String imagePath) async {
    await initialize();
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _latinRecognizer.processImage(inputImage);
    return recognizedText.text.trim().isNotEmpty;
  }

  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }
    await _latinRecognizer.close();
    _initialized = false;
  }

  Future<List<_PreparedVariant>> _buildVariants(
    String imagePath,
    ProfessionalOcrOptions options,
  ) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return [
        _PreparedVariant(
          name: 'original',
          file: File(imagePath),
          deleteAfterUse: false,
        ),
      ];
    }

    final baseImage = _normalizeBaseImage(decoded, options);
    final variants = <_PreparedVariant>[
      await _saveVariant(_buildBalancedVariant(baseImage), 'balanced'),
    ];

    if (options.enableDocumentVariant) {
      variants.add(
        await _saveVariant(_buildDocumentVariant(baseImage), 'document'),
      );
    }

    if (options.enableBinaryVariant) {
      variants.add(
        await _saveVariant(_buildBinaryVariant(baseImage), 'binary'),
      );
    }

    return variants;
  }

  img.Image _normalizeBaseImage(
    img.Image source,
    ProfessionalOcrOptions options,
  ) {
    var normalized = img.bakeOrientation(source);
    final longSide = math.max(normalized.width, normalized.height);

    if (longSide < options.preferredLongSide) {
      final scale = options.preferredLongSide / longSide;
      normalized = img.copyResize(
        normalized,
        width: (normalized.width * scale).round(),
        height: (normalized.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    } else if (longSide > options.maxLongSide) {
      final scale = options.maxLongSide / longSide;
      normalized = img.copyResize(
        normalized,
        width: (normalized.width * scale).round(),
        height: (normalized.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    return normalized;
  }

  img.Image _buildBalancedVariant(img.Image base) {
    final variant = img.Image.from(base);
    return img.adjustColor(
      variant,
      contrast: 1.12,
      brightness: 1.04,
      saturation: 1.0,
      gamma: 1.0,
    );
  }

  img.Image _buildDocumentVariant(img.Image base) {
    final variant = img.Image.from(base);
    img.grayscale(variant);
    return img.adjustColor(
      variant,
      contrast: 1.35,
      brightness: 1.03,
      saturation: 0,
      gamma: 0.95,
    );
  }

  img.Image _buildBinaryVariant(img.Image base) {
    final variant = img.Image.from(base);
    img.grayscale(variant);
    img.adjustColor(
      variant,
      contrast: 1.6,
      brightness: 1.02,
      saturation: 0,
      gamma: 0.9,
    );
    return img.luminanceThreshold(variant, threshold: 0.58);
  }

  Future<_PreparedVariant> _saveVariant(img.Image image, String name) async {
    final file = await _writeTempFile(
      img.encodePng(image),
      suffix: '_$name.png',
    );
    return _PreparedVariant(name: name, file: file, deleteAfterUse: true);
  }

  Future<List<_OcrCandidate>> _recognizeVariant(
    _PreparedVariant variant, {
    required OcrLanguageProfile profile,
    required List<int> angles,
  }) async {
    final candidates = <_OcrCandidate>[];

    for (final angle in angles) {
      final rotatedFile = angle == 0
          ? variant.file
          : await _rotateImageToTemp(variant.file.path, angle);
      try {
        for (final backend in _backendsForProfile(profile)) {
          final text = await _runBackend(rotatedFile.path, backend);
          final normalizedText = _normalizeOutput(text);
          if (normalizedText.isEmpty) {
            continue;
          }

          candidates.add(
            _OcrCandidate(
              backend: backend,
              variant: variant.name,
              angle: angle,
              text: normalizedText,
              score: _scoreText(normalizedText, profile: profile),
            ),
          );
        }
      } finally {
        if (angle != 0) {
          await _deleteTempFile(rotatedFile);
        }
      }
    }

    return candidates;
  }

  List<_OcrBackend> _backendsForProfile(OcrLanguageProfile profile) {
    switch (profile) {
      case OcrLanguageProfile.arabic:
        return const [_OcrBackend.tesseractArabic, _OcrBackend.tesseractMixed];
      case OcrLanguageProfile.english:
        return const [_OcrBackend.mlkitLatin, _OcrBackend.tesseractEnglish];
      case OcrLanguageProfile.mixed:
      case OcrLanguageProfile.auto:
        return const [
          _OcrBackend.tesseractMixed,
          _OcrBackend.mlkitLatin,
          _OcrBackend.tesseractArabic,
        ];
    }
  }

  Future<String> _runBackend(String imagePath, _OcrBackend backend) async {
    switch (backend) {
      case _OcrBackend.mlkitLatin:
        final inputImage = InputImage.fromFilePath(imagePath);
        final text = await _latinRecognizer.processImage(inputImage);
        return text.text;
      case _OcrBackend.tesseractArabic:
        return _extractWithTesseract(imagePath, languages: 'ara');
      case _OcrBackend.tesseractEnglish:
        return _extractWithTesseract(imagePath, languages: 'eng');
      case _OcrBackend.tesseractMixed:
        return _extractWithTesseract(imagePath, languages: 'ara+eng');
    }
  }

  Future<String> _extractWithTesseract(
    String imagePath, {
    required String languages,
  }) async {
    final args = <String, String>{
      'psm': '6',
      'oem': '3',
      'preserve_interword_spaces': '1',
    };
    return FlutterTesseractOcr.extractText(
      imagePath,
      language: languages,
      args: args,
    );
  }

  bool _shouldRunOrientationSweep(
    _OcrCandidate candidate,
    OcrLanguageProfile profile,
  ) {
    if (candidate.score < 90) {
      return true;
    }
    if (profile == OcrLanguageProfile.mixed ||
        profile == OcrLanguageProfile.auto) {
      return !_hasBothArabicAndLatin(candidate.text);
    }
    return false;
  }

  String _composeFinalText(
    List<_OcrCandidate> candidates,
    OcrLanguageProfile profile,
  ) {
    final bestOverall = _bestCandidate(candidates);
    if (bestOverall == null) {
      return '';
    }

    if (profile == OcrLanguageProfile.arabic ||
        profile == OcrLanguageProfile.english) {
      return bestOverall.text;
    }

    final mixedCandidate = _bestWhere(
      candidates,
      (candidate) => candidate.backend == _OcrBackend.tesseractMixed,
    );
    final arabicCandidate = _bestWhere(
      candidates,
      (candidate) => _arabicCount(candidate.text) >= 8,
    );
    final latinCandidate = _bestWhere(
      candidates,
      (candidate) =>
          candidate.backend == _OcrBackend.mlkitLatin ||
          _latinCount(candidate.text) >= 8,
    );

    final merged = _mergeMixedTexts(
      base: mixedCandidate?.text ?? bestOverall.text,
      arabic: arabicCandidate?.text,
      latin: latinCandidate?.text,
    );

    final mergedScore = _scoreText(merged, profile: profile);
    if (mergedScore >= bestOverall.score) {
      return merged;
    }

    return bestOverall.text;
  }

  String _mergeMixedTexts({
    required String base,
    String? arabic,
    String? latin,
  }) {
    final baseLines = _splitLines(base);
    final arabicLines = _splitLines(arabic ?? '');
    final latinLines = _splitLines(latin ?? '');

    if (baseLines.isEmpty) {
      return _normalizeOutput([arabic ?? '', latin ?? ''].join('\n'));
    }

    final totalLines = [
      baseLines.length,
      arabicLines.length,
      latinLines.length,
    ].reduce(math.max);
    final merged = <String>[];

    for (var index = 0; index < totalLines; index++) {
      final lineOptions = <String>[
        _lineAtScaledIndex(baseLines, index, totalLines),
        _lineAtScaledIndex(arabicLines, index, totalLines),
        _lineAtScaledIndex(latinLines, index, totalLines),
      ].where((line) => line.trim().isNotEmpty).toList(growable: false);

      if (lineOptions.isEmpty) {
        continue;
      }

      var bestLine = lineOptions.first;
      for (final line in lineOptions.skip(1)) {
        if (_scoreText(line, profile: OcrLanguageProfile.mixed) >
            _scoreText(bestLine, profile: OcrLanguageProfile.mixed)) {
          bestLine = line;
        }
      }

      for (final line in lineOptions) {
        if (line == bestLine) {
          continue;
        }
        bestLine = _augmentLine(bestLine, line);
      }

      if (merged.isEmpty || !_areLinesSimilar(merged.last, bestLine)) {
        merged.add(_normalizeOutput(bestLine));
      }
    }

    return _normalizeOutput(merged.join('\n'));
  }

  String _augmentLine(String base, String other) {
    if (_areLinesSimilar(base, other)) {
      return _scoreText(other, profile: OcrLanguageProfile.mixed) >
              _scoreText(base, profile: OcrLanguageProfile.mixed)
          ? other
          : base;
    }

    var result = base;

    if (!_containsArabic(result) && _containsArabic(other)) {
      result = '${_extractArabicTokens(other)} $result'.trim();
    }

    if (!_containsLatin(result) && _containsLatin(other)) {
      result = '$result ${_extractLatinTokens(other)}'.trim();
    }

    return _normalizeOutput(result);
  }

  String _lineAtScaledIndex(List<String> lines, int index, int totalLines) {
    if (lines.isEmpty) {
      return '';
    }
    if (lines.length == totalLines) {
      return lines[index.clamp(0, lines.length - 1)];
    }
    final mappedIndex = ((index / totalLines) * lines.length).floor().clamp(
      0,
      lines.length - 1,
    );
    return lines[mappedIndex];
  }

  List<String> _splitLines(String text) {
    return text
        .split('\n')
        .map(_normalizeOutput)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  bool _areLinesSimilar(String a, String b) {
    final tokensA = _comparisonTokens(a);
    final tokensB = _comparisonTokens(b);
    if (tokensA.isEmpty || tokensB.isEmpty) {
      return _normalizeForComparison(a) == _normalizeForComparison(b);
    }
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    return union > 0 && intersection / union >= 0.72;
  }

  Set<String> _comparisonTokens(String line) {
    return _normalizeForComparison(
      line,
    ).split(RegExp(r'\s+')).where((token) => token.trim().isNotEmpty).toSet();
  }

  _OcrCandidate? _bestCandidate(List<_OcrCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    final sorted = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.first;
  }

  _OcrCandidate? _bestWhere(
    List<_OcrCandidate> candidates,
    bool Function(_OcrCandidate candidate) test,
  ) {
    final filtered = candidates.where(test).toList(growable: false);
    if (filtered.isEmpty) {
      return null;
    }
    filtered.sort((a, b) => b.score.compareTo(a.score));
    return filtered.first;
  }

  int _scoreText(String text, {required OcrLanguageProfile profile}) {
    final normalized = _normalizeOutput(text);
    if (normalized.isEmpty) {
      return 0;
    }

    final arabic = _arabicCount(normalized);
    final latin = _latinCount(normalized);
    final digits = RegExp(r'\d').allMatches(normalized).length;
    final words = RegExp(
      r'[\u0600-\u06FFA-Za-z0-9]{2,}',
    ).allMatches(normalized).length;
    final weirdChars = RegExp(
      r'[^\u0600-\u06FFA-Za-z0-9\s\.,:;!?()\[\]{}%/\-_@#&\+\*]',
    ).allMatches(normalized).length;
    final singleCharWords = RegExp(
      r'(?<![\u0600-\u06FFA-Za-z0-9])[\u0600-\u06FFA-Za-z](?![\u0600-\u06FFA-Za-z0-9])',
    ).allMatches(normalized).length;
    final repeatedNoise = RegExp(r'(.)\1{4,}').allMatches(normalized).length;

    var score = normalized.length + words * 10 + digits * 2;

    switch (profile) {
      case OcrLanguageProfile.arabic:
        score += arabic * 4;
        score += latin;
        break;
      case OcrLanguageProfile.english:
        score += latin * 4;
        score += arabic;
        break;
      case OcrLanguageProfile.mixed:
      case OcrLanguageProfile.auto:
        score += arabic * 3;
        score += latin * 3;
        if (arabic > 4 && latin > 4) {
          score += 30;
        }
        break;
    }

    score -= weirdChars * 5;
    score -= repeatedNoise * 12;
    score -= singleCharWords * 2;

    return score;
  }

  OcrLanguageProfile _normalizeProfile(OcrLanguageProfile profile) {
    if (profile == OcrLanguageProfile.auto) {
      return OcrLanguageProfile.mixed;
    }
    return profile;
  }

  String _normalizeOutput(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _normalizeForComparison(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0600-\u06FFA-Za-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasBothArabicAndLatin(String text) {
    return _arabicCount(text) >= 8 && _latinCount(text) >= 8;
  }

  bool _containsArabic(String text) => _arabicCount(text) > 0;

  bool _containsLatin(String text) => _latinCount(text) > 0;

  int _arabicCount(String text) {
    return RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
  }

  int _latinCount(String text) {
    return RegExp(r'[A-Za-z]').allMatches(text).length;
  }

  String _extractArabicTokens(String text) {
    return RegExp(
      r'[\u0600-\u06FF0-9]+',
    ).allMatches(text).map((match) => match.group(0)!).toSet().join(' ');
  }

  String _extractLatinTokens(String text) {
    return RegExp(
      r'[A-Za-z0-9@._:/-]+',
    ).allMatches(text).map((match) => match.group(0)!).toSet().join(' ');
  }

  String _preview(String text) {
    final normalized = _normalizeOutput(text);
    if (normalized.length <= 120) {
      return normalized;
    }
    return '${normalized.substring(0, 120)}...';
  }

  Future<File> _rotateImageToTemp(String path, int angle) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return File(path);
    }
    final rotated = img.copyRotate(decoded, angle: angle);
    return _writeTempFile(img.encodePng(rotated), suffix: '_r$angle.png');
  }

  Future<File> _writeTempFile(List<int> bytes, {String suffix = '.png'}) async {
    final dir = await Directory.systemTemp.createTemp('professional_ocr_');
    final file = File('${dir.path}/variant$suffix');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
      final parent = file.parent;
      if (await parent.exists()) {
        await parent.delete();
      }
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}

class _PreparedVariant {
  const _PreparedVariant({
    required this.name,
    required this.file,
    required this.deleteAfterUse,
  });

  final String name;
  final File file;
  final bool deleteAfterUse;
}

class _OcrCandidate {
  const _OcrCandidate({
    required this.backend,
    required this.variant,
    required this.angle,
    required this.text,
    required this.score,
  });

  final _OcrBackend backend;
  final String variant;
  final int angle;
  final String text;
  final int score;
}

enum _OcrBackend {
  mlkitLatin('mlkit_latin'),
  tesseractArabic('tesseract_ara'),
  tesseractEnglish('tesseract_eng'),
  tesseractMixed('tesseract_ara_eng');

  const _OcrBackend(this.label);

  final String label;
}
