import 'package:dio/dio.dart';

class AddressSuggestion {
  const AddressSuggestion({required this.description, required this.provider});

  final String description;
  final String provider;
}

class AddressAutocompleteService {
  AddressAutocompleteService({Dio? dio, String? googleMapsApiKey})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {
                'User-Agent': 'DirecaoFinanceira/1.0 address autocomplete',
              },
            ),
          ),
      _googleMapsApiKey = googleMapsApiKey?.trim() ?? '';

  final Dio _dio;
  final String _googleMapsApiKey;

  Future<List<AddressSuggestion>> search(String input) async {
    final query = _normalizeInput(input);
    if (query.length < 3) {
      return const [];
    }

    return _searchGooglePlaces(query);
  }

  Future<List<AddressSuggestion>> _searchGooglePlaces(String query) async {
    if (_googleMapsApiKey.isEmpty) {
      return const [];
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _googleMapsApiKey,
            'X-Goog-FieldMask': 'suggestions.placePrediction.text.text',
          },
        ),
        data: {
          'input': _withLocalContext(query),
          'languageCode': 'pt-BR',
          'includedRegionCodes': ['br'],
          'locationBias': {
            'circle': {
              'center': {'latitude': -21.1358, 'longitude': -44.2619},
              'radius': 50000.0,
            },
          },
        },
      );

      final suggestions = response.data?['suggestions'];
      if (suggestions is! List) {
        return const [];
      }

      return suggestions
          .whereType<Map>()
          .map((item) {
            final prediction = item['placePrediction'];
            if (prediction is! Map) {
              return '';
            }

            final text = prediction['text'];
            if (text is! Map) {
              return '';
            }

            return text['text']?.toString().trim() ?? '';
          })
          .where((description) => description.isNotEmpty)
          .toSet()
          .map(
            (description) =>
                AddressSuggestion(description: description, provider: 'Google'),
          )
          .toList();
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  String _withLocalContext(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('brasil') || lower.contains('sao joao del rei')) {
      return input;
    }

    return '$input, Sao Joao del Rei, MG, Brasil';
  }

  String _normalizeInput(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
