import '../entities/ride_screenshot_import_entity.dart';
import 'movesj_history_screenshot_parser.dart';

class NinetyNineScreenshotParser {
  const NinetyNineScreenshotParser();

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
    final headerLines = regions.headerLines.map((line) => line.text).toList();
    final profileLines = regions.profileLines.map((line) => line.text).toList();
    final routeLines = regions.routeLines.map((line) => line.text).toList();

    return _parseLines(
      cardLines,
      headerLines: headerLines,
      profileLines: profileLines,
      routeLines: routeLines,
    );
  }

  RideScreenshotImportEntity parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return _parseLines(
      lines,
      headerLines: lines,
      profileLines: lines,
      routeLines: lines,
    );
  }

  bool looksLike(List<String> lines) {
    final joined = _normalize(lines.join(' '));
    final hasRouteStats = _routeStatsRegex.allMatches(joined).length >= 2;
    final hasNinetyNineMarkers =
        joined.contains('preco x') ||
        joined.contains('nao afeta a ta') ||
        joined.contains('aceitar por') ||
        joined.contains('perfil essencial') ||
        joined.contains('perfil premium') ||
        joined.contains('corridas') ||
        joined.contains('tarifa base dinamica') ||
        joined.contains('prioritario') ||
        joined.contains('pgto') ||
        joined.contains('cpf verif') ||
        joined.contains('parada');

    return hasRouteStats && hasNinetyNineMarkers;
  }

  RideScreenshotImportEntity _parseLines(
    List<String> lines, {
    required List<String> headerLines,
    required List<String> profileLines,
    required List<String> routeLines,
  }) {
    final passengerName = _extractPassengerName(profileLines);
    final addresses = _extractAddresses(routeLines, passengerName);

    return RideScreenshotImportEntity(
      platformName: '99',
      detectedAt: null,
      passengerName: passengerName,
      passengerRating: _extractPassengerRating(profileLines),
      paymentMethod: _extractPaymentMethod(headerLines),
      grossValueCents: _extractMainValueCents(lines),
      originAddress: addresses.$1,
      destinationAddress: addresses.$2,
    );
  }

  _NinetyNineRegions _buildRegions(List<OcrTextLine> ocrLines) {
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
        lines
            .where(
              (line) =>
                  _priceRegex.hasMatch(line.text) &&
                  !_normalize(line.text).contains('/km') &&
                  (firstRouteTop == null || line.top < firstRouteTop),
            )
            .toList()
          ..sort((a, b) {
            final areaComparison = _area(b).compareTo(_area(a));
            return areaComparison != 0
                ? areaComparison
                : a.top.compareTo(b.top);
          });

    if (mainPrice.isEmpty) {
      return _NinetyNineRegions(
        cardLines: lines,
        headerLines: lines,
        profileLines: lines,
        routeLines: lines,
      );
    }

    final priceLine = mainPrice.first;
    final priceHeight = (priceLine.bottom - priceLine.top).clamp(1.0, 9999.0);
    final cardTop = (priceLine.top - priceHeight * 2).clamp(0.0, priceLine.top);
    final cardLines = lines.where((line) => line.top >= cardTop).toList();
    final headerLines = cardLines
        .where((line) => firstRouteTop == null || line.top < firstRouteTop)
        .toList();
    final profileLines = headerLines.where((line) {
      final normalized = _normalize(line.text);
      return line.top >= priceLine.bottom &&
          (normalized.contains('perfil') ||
              normalized.contains('corridas') ||
              normalized.contains('passageiro') ||
              _ratingRegex.hasMatch(normalized));
    }).toList();
    final routeLines = firstRouteTop == null
        ? cardLines
        : cardLines.where((line) => line.top >= firstRouteTop).toList();

    return _NinetyNineRegions(
      cardLines: cardLines,
      headerLines: headerLines,
      profileLines: profileLines,
      routeLines: routeLines,
    );
  }

  int? _extractMainValueCents(List<String> lines) {
    final matches = lines
        .where((line) => !_normalize(line).contains('/km'))
        .expand(_priceRegex.allMatches)
        .map((match) => match.group(0)!)
        .toList();
    if (matches.isEmpty) {
      return null;
    }
    return _currencyToCents(matches.first);
  }

  double? _extractPassengerRating(List<String> lines) {
    final ratingLine = lines.firstWhere((line) {
      final normalized = _normalize(line);
      return normalized.contains('perfil') || normalized.contains('corridas');
    }, orElse: () => '');
    if (ratingLine.isEmpty) {
      return null;
    }

    final match = _ratingRegex.firstMatch(ratingLine);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  String? _extractPassengerName(List<String> lines) {
    for (final line in lines) {
      final match = RegExp(
        r'Perfil\s+([A-Za-zÀ-ÿ]+(?:\s+[A-Za-zÀ-ÿ]+)*)',
        caseSensitive: false,
      ).firstMatch(line);
      final profile = match?.group(1)?.trim();
      if (profile != null && profile.isNotEmpty) {
        return 'Perfil $profile';
      }
    }
    return null;
  }

  String? _extractPaymentMethod(List<String> lines) {
    for (final line in lines) {
      for (final part in _splitLabels(line)) {
        final normalized = _normalize(part);
        if (normalized.contains('dinheiro')) {
          return 'Dinheiro';
        }
        if (normalized.contains('pix')) {
          return 'Pix';
        }
        if (normalized.contains('cartao')) {
          return 'Cartao';
        }
      }
    }
    return null;
  }

  (String?, String?) _extractAddresses(
    List<String> lines,
    String? passengerName,
  ) {
    final addresses = <String>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_routeStatsRegex.hasMatch(_normalize(line))) {
        continue;
      }

      final addressParts = <String>[
        ?_addressAfterRouteStats(line, passengerName),
        ..._collectAddressContinuationParts(lines, index + 1, passengerName),
      ];
      final address = _joinAddressParts(addressParts);
      if (address != null) {
        addresses.add(address);
      }
    }

    if (addresses.isEmpty) {
      addresses.addAll(
        lines.where((line) => _isAddressCandidate(line, passengerName)),
      );
    }

    final unique = <String>[];
    for (final address in addresses) {
      if (!unique.contains(address)) {
        unique.add(address);
      }
    }

    return (unique.firstOrNull, unique.skip(1).lastOrNull);
  }

  String? _addressAfterRouteStats(String line, String? passengerName) {
    final match = _routeStatsRegex.firstMatch(_normalize(line));
    if (match == null) {
      return null;
    }

    final candidate = line.substring(match.end).trim();
    return _isAddressCandidate(candidate, passengerName) ? candidate : null;
  }

  List<String> _collectAddressContinuationParts(
    List<String> lines,
    int startIndex,
    String? passengerName,
  ) {
    final parts = <String>[];

    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }
      if (_routeStatsRegex.hasMatch(_normalize(line))) {
        break;
      }
      if (_isAddressCandidate(line, passengerName)) {
        parts.add(line);
        continue;
      }
      if (parts.isNotEmpty) {
        break;
      }
    }

    return parts;
  }

  String? _joinAddressParts(List<String> parts) {
    final unique = <String>[];
    for (final part in parts.map((part) => part.trim())) {
      if (part.isNotEmpty && !unique.contains(part)) {
        unique.add(part);
      }
    }
    final address = unique.join(' ').trim();
    return address.isEmpty ? null : address;
  }

  bool _isAddressCandidate(String line, String? passengerName) {
    final trimmed = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized = _normalize(trimmed);
    if (trimmed.length < 6 || !RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(trimmed)) {
      return false;
    }
    if (passengerName != null && normalized == _normalize(passengerName)) {
      return false;
    }
    if (_priceRegex.hasMatch(trimmed) ||
        _routeStatsRegex.hasMatch(normalized)) {
      return false;
    }

    const blockedTerms = [
      'preco x',
      'nao afeta a ta',
      'perfil',
      'corridas',
      'aceitar',
      'dinheiro',
      'pix',
      'cartao',
      'entrega',
      'negocia',
      'parada',
      'km',
      'min',
      'r\$',
      'passageiro',
      'google',
      'premium',
      'essencial',
      'novo',
    ];

    return !blockedTerms.any(normalized.contains);
  }

  List<String> _splitLabels(String line) {
    return line
        .split(RegExp(r'\s*[\u2022\u00B7]\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
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
    r'\d+\s*min(?:utos?)?\s*\(\s*\d+(?:[,.]\d+)?\s*(?:km|m)\s*\)',
    caseSensitive: false,
  );
  static final _ratingRegex = RegExp(r'\b[1-5][,.]\d{1,2}\b');
}

class _NinetyNineRegions {
  const _NinetyNineRegions({
    required this.cardLines,
    required this.headerLines,
    required this.profileLines,
    required this.routeLines,
  });

  final List<OcrTextLine> cardLines;
  final List<OcrTextLine> headerLines;
  final List<OcrTextLine> profileLines;
  final List<OcrTextLine> routeLines;
}
