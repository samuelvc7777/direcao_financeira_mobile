import '../entities/ride_screenshot_import_entity.dart';
import 'movesj_history_screenshot_parser.dart';

class UberScreenshotParser {
  const UberScreenshotParser();

  RideScreenshotImportEntity parsePositioned(List<OcrTextLine> ocrLines) {
    if (ocrLines.isEmpty) {
      return parse('');
    }

    final sortedLines = [...ocrLines]
      ..sort((a, b) {
        final topComparison = a.top.compareTo(b.top);
        return topComparison != 0 ? topComparison : a.left.compareTo(b.left);
      });
    final regions = _buildRegions(sortedLines);
    final cardLines = regions.cardLines.map((line) => line.text).toList();
    final routeLines = regions.routeLines.map((line) => line.text).toList();

    return _parseLines(cardLines, routeLines: routeLines);
  }

  RideScreenshotImportEntity parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return _parseLines(lines, routeLines: lines);
  }

  bool looksLike(List<String> lines) {
    final joined = _normalize(lines.join(' '));
    final hasUberMarker =
        joined.contains('uberx') ||
        joined.contains('uber comfort') ||
        joined.contains('uber black');
    final hasRouteStats = _routeStatsRegex.allMatches(joined).length >= 2;
    return hasUberMarker && hasRouteStats && _priceRegex.hasMatch(joined);
  }

  RideScreenshotImportEntity _parseLines(
    List<String> lines, {
    required List<String> routeLines,
  }) {
    final addresses = _extractAddresses(routeLines);

    return RideScreenshotImportEntity(
      platformName: 'Uber',
      passengerName: null,
      passengerRating: _extractPassengerRating(lines),
      paymentMethod: null,
      grossValueCents: _extractMainValueCents(lines),
      originAddress: addresses.$1,
      destinationAddress: addresses.$2,
    );
  }

  _UberRegions _buildRegions(List<OcrTextLine> ocrLines) {
    final lines = ocrLines
        .where((line) => line.text.trim().isNotEmpty)
        .toList(growable: false);
    final firstRouteTop = lines
        .where((line) => _routeStatsRegex.hasMatch(_normalize(line.text)))
        .map((line) => line.top)
        .fold<double?>(null, (current, top) {
          if (current == null || top < current) {
            return top;
          }
          return current;
        });
    final mainPrice =
        lines.where((line) => _priceRegex.hasMatch(line.text)).toList()..sort((
          a,
          b,
        ) {
          final areaComparison = _area(b).compareTo(_area(a));
          return areaComparison != 0 ? areaComparison : a.top.compareTo(b.top);
        });

    if (mainPrice.isEmpty) {
      return _UberRegions(cardLines: lines, routeLines: lines);
    }

    final priceLine = mainPrice.first;
    final priceHeight = (priceLine.bottom - priceLine.top).clamp(1.0, 9999.0);
    final cardTop = (priceLine.top - priceHeight * 2).clamp(0.0, priceLine.top);
    final cardLines = lines.where((line) => line.top >= cardTop).toList();
    final routeLines = firstRouteTop == null
        ? cardLines
        : cardLines.where((line) => line.top >= firstRouteTop).toList();

    return _UberRegions(cardLines: cardLines, routeLines: routeLines);
  }

  int? _extractMainValueCents(List<String> lines) {
    for (final line in lines) {
      final match = _priceRegex.firstMatch(line);
      if (match != null) {
        return _currencyToCents(match.group(0)!);
      }
    }
    return null;
  }

  double? _extractPassengerRating(List<String> lines) {
    for (final line in lines) {
      final match = _ratingRegex.firstMatch(line);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', '.'));
      }
    }
    return null;
  }

  (String?, String?) _extractAddresses(List<String> lines) {
    final addresses = <String>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_routeStatsRegex.hasMatch(_normalize(line))) {
        continue;
      }

      final inlineAddress = _addressAfterRouteStats(line);
      if (inlineAddress != null) {
        addresses.add(inlineAddress);
        continue;
      }

      final nextAddress = _collectNextAddress(lines, index + 1);
      if (nextAddress != null) {
        addresses.add(nextAddress);
      }
    }

    final unique = <String>[];
    for (final address in addresses) {
      if (!unique.contains(address)) {
        unique.add(address);
      }
    }

    return (unique.firstOrNull, unique.skip(1).lastOrNull);
  }

  String? _addressAfterRouteStats(String line) {
    final normalized = _normalize(line);
    final match = _routeStatsRegex.firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final candidate = line.substring(match.end).trim();
    return _isAddressCandidate(candidate) ? candidate : null;
  }

  String? _collectNextAddress(List<String> lines, int startIndex) {
    final parts = <String>[];
    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }
      if (_routeStatsRegex.hasMatch(_normalize(line))) {
        break;
      }
      if (_isAddressCandidate(line)) {
        parts.add(line);
        continue;
      }
      if (parts.isNotEmpty) {
        break;
      }
    }
    final address = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return address.isEmpty ? null : address;
  }

  bool _isAddressCandidate(String line) {
    final trimmed = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized = _normalize(trimmed);
    if (trimmed.length < 6 || !RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(trimmed)) {
      return false;
    }
    if (_priceRegex.hasMatch(trimmed) ||
        _routeStatsRegex.hasMatch(normalized)) {
      return false;
    }

    const blockedTerms = [
      'aceitar',
      'uberx',
      'uber',
      'comfort',
      'black',
      'r\$',
    ];

    return !blockedTerms.any(normalized.contains);
  }

  int _currencyToCents(String value) {
    final normalized = value
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();
    return ((double.tryParse(normalized) ?? 0) * 100).round();
  }

  int _area(OcrTextLine line) {
    return ((line.right - line.left).clamp(0.0, 99999.0) *
            (line.bottom - line.top).clamp(0.0, 99999.0))
        .round();
  }

  String _normalize(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    var output = value.toLowerCase();
    accents.forEach((from, to) {
      output = output.replaceAll(from, to);
    });
    return output.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final _priceRegex = RegExp(
    r'R\$\s*\d{1,3}(?:\.\d{3})*(?:,\d{2})|R\$\s*\d+(?:,\d{2})',
    caseSensitive: false,
  );
  static final _routeStatsRegex = RegExp(
    r'\d+\s*min(?:utos?)?\s*\(\s*\d+(?:[,.]\d+)?\s*km\s*\)',
    caseSensitive: false,
  );
  static final _ratingRegex = RegExp(r'\b([1-5][,.]\d{1,2})\s*\((\d+)\)');
}

class _UberRegions {
  const _UberRegions({required this.cardLines, required this.routeLines});

  final List<OcrTextLine> cardLines;
  final List<OcrTextLine> routeLines;
}
