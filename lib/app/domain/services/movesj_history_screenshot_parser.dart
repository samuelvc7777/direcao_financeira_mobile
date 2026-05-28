import '../entities/ride_screenshot_import_entity.dart';

class MoveSjHistoryScreenshotParser {
  const MoveSjHistoryScreenshotParser();

  RideScreenshotImportEntity parsePositioned(List<OcrTextLine> ocrLines) {
    if (ocrLines.isEmpty) {
      return parse('');
    }

    final sortedLines = [...ocrLines]
      ..sort((a, b) {
        final topComparison = a.top.compareTo(b.top);
        return topComparison != 0 ? topComparison : a.left.compareTo(b.left);
      });
    final textLines = sortedLines.map((line) => line.text).toList();
    final normalizedLines = textLines.map(_normalize).toList(growable: false);

    return RideScreenshotImportEntity(
      platformName: 'MoveSJ',
      detectedAt: _extractDetectedAt(textLines),
      passengerName: _extractPassengerPositioned(sortedLines),
      paymentMethod:
          _extractPositionedSection(
            sortedLines,
            startLabels: const ['forma de pagamento', 'pagamento'],
            endLabels: const ['valor motorista', 'valor total'],
          ) ??
          _extractSection(
            textLines,
            normalizedLines,
            startLabels: const ['forma de pagamento', 'pagamento'],
            endLabels: const ['valor motorista', 'valor total'],
          ),
      grossValueCents:
          _extractPositionedValueTotal(sortedLines) ??
          _extractValueCents(textLines, normalizedLines),
      originAddress:
          _extractPositionedSection(
            sortedLines,
            startLabels: const ['endereco de origem', 'origem'],
            endLabels: const ['endereco de destino'],
          ) ??
          _extractSection(
            textLines,
            normalizedLines,
            startLabels: const ['endereco de origem', 'origem'],
            endLabels: const ['endereco de destino'],
          ),
      destinationAddress:
          _extractPositionedSection(
            sortedLines,
            startLabels: const ['endereco de destino', 'destino'],
            endLabels: const ['numero viagem', 'numero da viagem', 'status'],
          ) ??
          _extractSection(
            textLines,
            normalizedLines,
            startLabels: const ['endereco de destino', 'destino'],
            endLabels: const ['numero viagem', 'numero da viagem', 'status'],
          ),
      tripNumber: _extractSection(
        textLines,
        normalizedLines,
        startLabels: const ['numero viagem', 'numero da viagem'],
        endLabels: const ['status', 'forma de pagamento'],
      ),
    );
  }

  RideScreenshotImportEntity parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final normalizedLines = lines.map(_normalize).toList(growable: false);

    return RideScreenshotImportEntity(
      platformName: 'MoveSJ',
      detectedAt: _extractDetectedAt(lines),
      passengerName: _extractPassenger(lines, normalizedLines),
      paymentMethod: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['forma de pagamento', 'pagamento'],
        endLabels: const ['valor motorista', 'valor total'],
      ),
      grossValueCents: _extractValueCents(lines, normalizedLines),
      originAddress: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['endereco de origem', 'origem'],
        endLabels: const ['endereco de destino'],
      ),
      destinationAddress: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['endereco de destino', 'destino'],
        endLabels: const ['numero viagem', 'numero da viagem', 'status'],
      ),
      tripNumber: _extractSection(
        lines,
        normalizedLines,
        startLabels: const ['numero viagem', 'numero da viagem'],
        endLabels: const ['status', 'forma de pagamento'],
      ),
    );
  }

  String? _extractPositionedSection(
    List<OcrTextLine> lines, {
    required List<String> startLabels,
    required List<String> endLabels,
  }) {
    final start = _findLine(lines, startLabels);
    if (start == null) {
      return null;
    }

    final endTop = lines
        .where(
          (line) =>
              line.centerY > start.centerY &&
              _containsLabel(_normalize(line.text), endLabels),
        )
        .map((line) => line.top)
        .fold<double?>(null, (current, top) {
          if (current == null || top < current) {
            return top;
          }
          return current;
        });

    final values = <String>[];
    final inline = _inlineValue(
      originalLine: start.text,
      normalizedLine: _normalize(start.text),
      labels: startLabels,
    );
    if (inline != null) {
      values.add(inline);
    }

    for (final line in lines) {
      if (identical(line, start)) {
        continue;
      }
      if (line.centerY <= start.bottom) {
        continue;
      }
      if (endTop != null && line.top >= endTop) {
        continue;
      }
      if (_containsLabel(_normalize(line.text), startLabels) ||
          _containsLabel(_normalize(line.text), endLabels)) {
        continue;
      }
      if (line.right < start.left - 40) {
        continue;
      }
      values.add(line.text);
    }

    final text = values.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  int? _extractPositionedValueTotal(List<OcrTextLine> lines) {
    final label = _findLine(lines, const ['valor total']);
    if (label == null) {
      return null;
    }

    final candidates = lines.where((line) {
      final isBelow =
          line.centerY > label.bottom && line.top < label.bottom + 120;
      final sameColumn = (line.centerX - label.centerX).abs() < 180;
      return isBelow && sameColumn && _currencyMatches(line.text).isNotEmpty;
    }).toList()..sort((a, b) => a.top.compareTo(b.top));

    if (candidates.isEmpty) {
      return null;
    }
    return _currencyMatchToCents(_currencyMatches(candidates.first.text).last);
  }

  String? _extractPassengerPositioned(List<OcrTextLine> lines) {
    final label = _findLine(lines, const ['cliente']);
    if (label == null) {
      return null;
    }

    final inline = _cleanPassengerName(
      _inlineValue(
        originalLine: label.text,
        normalizedLine: _normalize(label.text),
        labels: const ['cliente'],
      ),
    );
    if (inline != null) {
      return inline;
    }

    final candidates = lines.where((line) {
      final normalized = _normalize(line.text);
      final isBelow =
          line.centerY > label.bottom && line.top < label.bottom + 260;
      final isNotUi =
          !normalized.contains('relatar ocorrencia') &&
          !normalized.contains('direcao financeira');
      final isRightOfAvatar = line.centerX > label.left + 120;
      return isBelow && isRightOfAvatar && isNotUi;
    }).toList()..sort((a, b) => a.top.compareTo(b.top));

    for (final candidate in candidates) {
      final passenger = _cleanPassengerName(candidate.text);
      if (passenger != null) {
        return passenger;
      }
    }
    return null;
  }

  OcrTextLine? _findLine(List<OcrTextLine> lines, List<String> labels) {
    for (final line in lines) {
      if (_containsLabel(_normalize(line.text), labels)) {
        return line;
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
    final valueStart = normalizedLines.indexWhere(
      (line) => _containsLabel(line, const ['valor total']),
    );
    final scanText = valueStart >= 0
        ? lines.skip(valueStart).take(3).join(' ')
        : lines.join(' ');
    final matches = _currencyMatches(scanText);
    if (matches.isNotEmpty) {
      return _currencyMatchToCents(matches.last);
    }

    final fallbackMatches = _currencyMatches(lines.join(' '));
    if (fallbackMatches.isEmpty) {
      return null;
    }
    return _currencyMatchToCents(fallbackMatches.last);
  }

  List<RegExpMatch> _currencyMatches(String text) {
    return RegExp(
      r'R\$\s*([0-9]+(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    ).allMatches(text).toList();
  }

  int? _currencyMatchToCents(RegExpMatch match) {
    final normalized = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }

  String? _extractPassenger(List<String> lines, List<String> normalizedLines) {
    final start = normalizedLines.indexWhere(
      (line) => _containsLabel(line, const ['cliente']),
    );
    if (start < 0) {
      return null;
    }

    final inline = _cleanPassengerName(
      _inlineValue(
        originalLine: lines[start],
        normalizedLine: normalizedLines[start],
        labels: const ['cliente'],
      ),
    );
    if (inline != null) {
      return inline;
    }

    for (final line in lines.skip(start + 1)) {
      final normalized = _normalize(line);
      if (normalized.contains('relatar ocorrencia')) {
        return null;
      }
      final passenger = _cleanPassengerName(line);
      if (passenger != null) {
        return passenger;
      }
    }
    return null;
  }

  String? _extractSection(
    List<String> lines,
    List<String> normalizedLines, {
    required List<String> startLabels,
    required List<String> endLabels,
  }) {
    final start = normalizedLines.indexWhere(
      (line) => _containsLabel(line, startLabels),
    );
    if (start < 0) {
      return null;
    }

    final values = <String>[];
    final inlineValue = _inlineValue(
      originalLine: lines[start],
      normalizedLine: normalizedLines[start],
      labels: startLabels,
    );
    if (inlineValue != null) {
      values.add(
        _trimBeforeEndLabel(
          originalText: inlineValue,
          normalizedText: _normalize(inlineValue),
          endLabels: endLabels,
        ),
      );
    }

    for (var i = start + 1; i < lines.length; i++) {
      final normalized = normalizedLines[i];
      if (_containsLabel(normalized, endLabels)) {
        final beforeEnd = _trimBeforeEndLabel(
          originalText: lines[i],
          normalizedText: normalized,
          endLabels: endLabels,
        );
        if (beforeEnd.isNotEmpty) {
          values.add(beforeEnd);
        }
        break;
      }
      values.add(lines[i]);
    }

    final text = values.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  bool _containsLabel(String normalizedLine, List<String> labels) {
    return labels.any((label) {
      final normalizedLabel = _normalize(label);
      if (normalizedLine.contains(normalizedLabel)) {
        return true;
      }
      if (normalizedLabel.contains('endereco')) {
        final wantsOrigin = normalizedLabel.contains('origem');
        final wantsDestination = normalizedLabel.contains('destino');
        return normalizedLine.contains('endere') &&
            (!wantsOrigin || normalizedLine.contains('origem')) &&
            (!wantsDestination || normalizedLine.contains('destino'));
      }
      return false;
    });
  }

  String? _inlineValue({
    required String originalLine,
    required String normalizedLine,
    required List<String> labels,
  }) {
    for (final label in labels) {
      final normalizedLabel = _normalize(label);
      final index = normalizedLine.indexOf(normalizedLabel);
      if (index < 0) {
        continue;
      }
      final start = (index + normalizedLabel.length).clamp(
        0,
        originalLine.length,
      );
      final value = originalLine
          .substring(start)
          .replaceFirst(RegExp(r'^\s*[:\-]?\s*'), '')
          .trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _trimBeforeEndLabel({
    required String originalText,
    required String normalizedText,
    required List<String> endLabels,
  }) {
    var cutIndex = originalText.length;
    for (final label in endLabels) {
      final index = normalizedText.indexOf(_normalize(label));
      if (index >= 0 && index < cutIndex) {
        cutIndex = index;
      }
    }
    return originalText.substring(0, cutIndex).trim();
  }

  String? _cleanPassengerName(String? value) {
    if (value == null) {
      return null;
    }
    final withoutStars = value
        .replaceAll(RegExp(r'[\u2605\u2606*]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withoutLabel = withoutStars
        .replaceFirst(RegExp(r'^cliente\s*', caseSensitive: false), '')
        .trim();
    final normalized = _normalize(withoutLabel);
    if (normalized.length <= 1 ||
        normalized.contains('direcao financeira') ||
        normalized.contains('relatar ocorrencia') ||
        RegExp(r'^[0-9.,\s]+$').hasMatch(normalized)) {
      return null;
    }
    return withoutLabel;
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

class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}
