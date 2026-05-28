import '../entities/ride_screenshot_import_entity.dart';
import 'movesj_history_screenshot_parser.dart';

class AutoRideScreenshotParser {
  const AutoRideScreenshotParser();

  RideScreenshotImportEntity parsePositioned(List<OcrTextLine> ocrLines) {
    if (_looksLikeMeLevaSj(ocrLines.map((line) => line.text).toList())) {
      return _parseMeLevaPositioned(ocrLines);
    }

    return const MoveSjHistoryScreenshotParser().parsePositioned(ocrLines);
  }

  RideScreenshotImportEntity parse(String rawText) {
    final lines = _splitLines(rawText);
    if (_looksLikeMeLevaSj(lines)) {
      return _parseMeLevaLines(lines);
    }

    return const MoveSjHistoryScreenshotParser().parse(rawText);
  }

  RideScreenshotImportEntity _parseMeLevaPositioned(
    List<OcrTextLine> ocrLines,
  ) {
    final sortedLines = [...ocrLines]
      ..sort((a, b) {
        final topComparison = a.top.compareTo(b.top);
        return topComparison != 0 ? topComparison : a.left.compareTo(b.left);
      });
    final lines = sortedLines.map((line) => line.text).toList(growable: false);
    return _parseMeLevaLines(lines);
  }

  RideScreenshotImportEntity _parseMeLevaLines(List<String> lines) {
    final normalizedLines = lines.map(_normalize).toList(growable: false);
    return RideScreenshotImportEntity(
      platformName: 'MeLevaSJ',
      detectedAt: _extractDetectedAt(lines),
      passengerName: _extractPassenger(lines, normalizedLines),
      passengerRating: _extractPassengerRating(lines, normalizedLines),
      paymentMethod: _extractPaymentMethod(lines, normalizedLines),
      grossValueCents: _extractValueCents(lines, normalizedLines),
      originAddress: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['embarque'],
        endLabels: const [
          'destino',
          'recusar',
          'aceitar',
          'moto taxi',
          'dinheiro',
          'pix',
        ],
      ),
      destinationAddress: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['destino'],
        endLabels: const ['recusar', 'aceitar', 'moto taxi', 'dinheiro', 'pix'],
        keepLastAddressBlock: true,
      ),
      tripNumber: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['numero viagem', 'numero da viagem'],
        endLabels: const ['status', 'forma de pagamento'],
      ),
    );
  }

  bool _looksLikeMeLevaSj(List<String> lines) {
    final joined = _normalize(lines.join(' '));
    const moveSjMarkers = [
      'endereco de origem',
      'endereco de destino',
      'numero viagem',
      'numero da viagem',
      'status',
      'forma de pagamento',
      'cliente',
      'passageiro',
    ];

    final hasMoveSjMarkers = moveSjMarkers.any(joined.contains);
    final hasMeLevaSignature =
        joined.contains('embarque') && joined.contains('destino');

    return joined.contains('me leva sj') ||
        (hasMeLevaSignature && !hasMoveSjMarkers);
  }

  List<String> _splitLines(String rawText) {
    return rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  String? _extractSection(
    List<String> lines,
    List<String> normalizedLines, {
    required List<String> startLabels,
    required List<String> endLabels,
    bool keepLastAddressBlock = false,
  }) {
    final startIndex = normalizedLines.indexWhere(
      (line) => _containsLabel(line, startLabels),
    );
    if (startIndex < 0) {
      return null;
    }

    final values = <String>[];
    final inline = _cleanAddressValue(
      _inlineValue(lines[startIndex], normalizedLines[startIndex], startLabels),
    );
    if (inline != null) {
      values.add(inline);
    }

    for (var index = startIndex + 1; index < lines.length; index++) {
      final line = lines[index];
      final normalized = normalizedLines[index];
      if ((!keepLastAddressBlock && _containsLabel(normalized, startLabels)) ||
          _containsLabel(normalized, endLabels)) {
        break;
      }
      if (keepLastAddressBlock &&
          values.isNotEmpty &&
          _isRouteSeparatorLine(line)) {
        values.clear();
        continue;
      }
      final cleaned = _cleanAddressValue(line);
      if (cleaned != null) {
        values.add(cleaned);
      }
    }

    final text = values.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  bool _isRouteSeparatorLine(String value) {
    final normalized = _normalize(value);
    return RegExp(r'^\d+\s*min\b').hasMatch(normalized) ||
        RegExp(r'^\(?\s*\d+(?:[.,]\d+)?\s*(?:m|km)\)?\b').hasMatch(normalized);
  }

  String? _extractPaymentMethod(
    List<String> lines,
    List<String> normalizedLines,
  ) {
    const labels = ['moto taxi', 'dinheiro', 'pix', 'cartao'];
    for (var index = 0; index < lines.length; index++) {
      final normalized = normalizedLines[index];
      for (final label in labels) {
        if (normalized.contains(label)) {
          return lines[index].replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }
    return null;
  }

  String? _extractPassenger(List<String> lines, List<String> normalizedLines) {
    final labelIndex = normalizedLines.indexWhere(
      (line) => line.contains('cliente') || line.contains('passageiro'),
    );
    if (labelIndex < 0) {
      return null;
    }

    final inline = _cleanPassengerName(
      _inlineValue(lines[labelIndex], normalizedLines[labelIndex], const [
        'cliente',
        'passageiro',
      ]),
    );
    if (inline != null) {
      return inline;
    }

    if (labelIndex + 1 < lines.length) {
      return _cleanPassengerName(lines[labelIndex + 1]);
    }

    return null;
  }

  double? _extractPassengerRating(
    List<String> lines,
    List<String> normalizedLines,
  ) {
    for (var index = 0; index < lines.length; index++) {
      final normalized = normalizedLines[index];
      if (_isUnlikelyPassengerRatingLine(normalized)) {
        continue;
      }

      final rating = _firstRatingInLine(lines[index]);
      if (rating != null) {
        return rating;
      }
    }

    return null;
  }

  bool _isUnlikelyPassengerRatingLine(String normalizedLine) {
    return normalizedLine.contains('r\$') ||
        normalizedLine.contains('/km') ||
        normalizedLine.contains('/min') ||
        normalizedLine.contains('km/h') ||
        normalizedLine.contains('valor') ||
        normalizedLine.contains('dinheiro') ||
        normalizedLine.contains('pix') ||
        normalizedLine.contains('cartao') ||
        normalizedLine.contains('moto taxi');
  }

  double? _firstRatingInLine(String line) {
    final matches = RegExp(
      r'(?<!\d)([1-5])[\.,]([0-9]{1,2})(?!\d)',
    ).allMatches(line);

    for (final match in matches) {
      final after = line.substring(match.end).trimLeft().toLowerCase();
      if (after.startsWith('km') ||
          after.startsWith('m') ||
          after.startsWith('min') ||
          after.startsWith('/')) {
        continue;
      }

      final value = double.tryParse('${match.group(1)}.${match.group(2)}');
      if (value != null && value >= 1 && value <= 5) {
        return value;
      }
    }

    return null;
  }

  DateTime? _extractDetectedAt(List<String> lines) {
    final joined = lines.join(' ');
    final match = RegExp(
      r'(\d{2})/(\d{2})/(\d{2,4})\s+(\d{2}):(\d{2})',
    ).firstMatch(joined);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    if ([day, month, rawYear, hour, minute].any((value) => value == null)) {
      return null;
    }

    final year = rawYear! < 100 ? 2000 + rawYear : rawYear;
    return DateTime(year, month!, day!, hour!, minute!);
  }

  int? _extractValueCents(List<String> lines, List<String> normalizedLines) {
    final startIndex = normalizedLines.indexWhere(
      (line) =>
          _containsLabel(line, const ['valor', 'valor total']) ||
          _currencyMatches(line).isNotEmpty,
    );
    final scanText = startIndex >= 0
        ? lines.sublist(startIndex).join(' ')
        : lines.join(' ');
    final matches = _currencyMatches(scanText);
    if (matches.isEmpty) {
      return null;
    }
    return _currencyMatchToCents(matches.last);
  }

  String? _inlineValue(
    String originalLine,
    String normalizedLine,
    List<String> labels,
  ) {
    for (final label in labels) {
      final index = normalizedLine.indexOf(label);
      if (index < 0) {
        continue;
      }
      final value = originalLine.substring(index + label.length);
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }
    return null;
  }

  bool _containsLabel(String normalizedLine, List<String> labels) {
    return labels.any((label) => normalizedLine.contains(label));
  }

  List<String> _currencyMatches(String text) {
    return RegExp(
      r'R\$\s*\d{1,3}(?:\.\d{3})*(?:,\d{2})|R\$\s*\d+(?:,\d{2})',
    ).allMatches(text).map((match) => match.group(0)!).toList(growable: false);
  }

  int _currencyMatchToCents(String match) {
    final normalized = match
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();
    final value = double.tryParse(normalized) ?? 0;
    return (value * 100).round();
  }

  String? _cleanAddressValue(String? value) {
    if (value == null) {
      return null;
    }

    var output = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    output = output.replaceFirst(RegExp(r'^\*\s*\d+(?:[.,]\d+)?\s*'), '');
    output = output.replaceFirst(RegExp(r'^\d+(?:[.,]\d+)?\s*'), '');
    output = output.replaceFirst(
      RegExp(r'^(embarque|destino)\s*[:\-]?\s*', caseSensitive: false),
      '',
    );
    output = output.replaceFirst(RegExp(r'^[\-\–\—\s]+'), '');
    output = output.replaceFirst(
      RegExp(r'^\(?\s*\d+(?:[.,]\d+)?\s*m\)?\s*', caseSensitive: false),
      '',
    );
    output = output.replaceFirst(
      RegExp(r'^\d+\s*min(?:\s*[\-\–\—]?\s*)?', caseSensitive: false),
      '',
    );
    output = output.replaceFirst(
      RegExp(r'^[^A-Za-z]*(?:in|rn|ii)\s+', caseSensitive: false),
      '',
    );
    output = output.replaceFirst(
      RegExp(r'^(?:[\-\–\—]\s*)+', caseSensitive: false),
      '',
    );
    output = output.replaceFirst(RegExp(r'\s+[A-Z]$'), '');
    output = output.replaceAll(RegExp(r'[,;]\s*$'), '');
    output = output.trim();
    output = output.replaceFirst(RegExp(r'^[^A-Za-z]+'), '');
    final streetMatch = RegExp(r'R\.').firstMatch(output);
    if (streetMatch != null && streetMatch.start <= 5) {
      output = output.substring(streetMatch.start).trim();
    }
    final lower = output.toLowerCase();
    if (lower.startsWith('in ')) {
      output = output.substring(3).trim();
    } else if (lower.startsWith('rn ')) {
      output = output.substring(3).trim();
    } else if (lower.startsWith('ii ')) {
      output = output.substring(3).trim();
    }

    if (output.isEmpty) {
      return null;
    }

    final normalizedOutput = _normalize(output);
    if (normalizedOutput == 'in' ||
        normalizedOutput == 'rn' ||
        normalizedOutput == 'ii') {
      return null;
    }

    if (normalizedOutput.contains('recalcular km e tempo')) {
      return null;
    }

    return output;
  }

  String? _cleanPassengerName(String? value) {
    if (value == null) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    final normalized = _normalize(cleaned);
    if (normalized.length <= 1 ||
        normalized.contains('direcao financeira') ||
        normalized.contains('relatar ocorrencia') ||
        RegExp(r'^[0-9.,\s]+$').hasMatch(normalized)) {
      return null;
    }
    return cleaned;
  }

  String _normalize(String value) {
    const accents = {
      '\u00E1': 'a',
      '\u00E0': 'a',
      '\u00E2': 'a',
      '\u00E3': 'a',
      '\u00E4': 'a',
      '\u00E9': 'e',
      '\u00E8': 'e',
      '\u00EA': 'e',
      '\u00EB': 'e',
      '\u00ED': 'i',
      '\u00EC': 'i',
      '\u00EE': 'i',
      '\u00EF': 'i',
      '\u00F3': 'o',
      '\u00F2': 'o',
      '\u00F4': 'o',
      '\u00F5': 'o',
      '\u00F6': 'o',
      '\u00FA': 'u',
      '\u00F9': 'u',
      '\u00FB': 'u',
      '\u00FC': 'u',
      '\u00E7': 'c',
    };
    var output = value.toLowerCase();
    accents.forEach((from, to) {
      output = output.replaceAll(from, to);
    });
    return output.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
