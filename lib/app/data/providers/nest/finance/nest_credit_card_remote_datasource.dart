import 'package:dio/dio.dart';

import '../../../datasources/credit_card_datasource.dart';
import '../../../models/credit_card_model.dart';

class NestCreditCardRemoteDataSource implements ICreditCardDataSource {
  NestCreditCardRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<CreditCardModel>> getCreditCards() async {
    final response = await dio.get('/finance/credit-cards');
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
        ? (data['data'] ?? data['creditCards'] ?? [])
        : [];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) => CreditCardModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<CreditCardModel> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async {
    final response = await dio.post(
      '/finance/credit-cards',
      data: {
        'name': name,
        'brand': brand,
        'color': color,
        'limitCents': limitCents,
        'closingDay': closingDay,
        'dueDay': dueDay,
        'lastFourDigits': lastFourDigits,
      },
    );

    return _parseCreditCard(response.data);
  }

  @override
  Future<CreditCardModel> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'brand': brand,
      'color': color,
      'limitCents': limitCents,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'lastFourDigits': lastFourDigits,
    };

    if (isActive != null) {
      data['isActive'] = isActive;
    }

    final response = await dio.patch('/finance/credit-cards/$id', data: data);
    return _parseCreditCard(response.data);
  }

  @override
  Future<void> deactivateCreditCard(int id) {
    return dio.delete('/finance/credit-cards/$id');
  }

  @override
  Future<void> reactivateCreditCard(int id) {
    return dio.patch('/finance/credit-cards/$id', data: {'isActive': true});
  }

  CreditCardModel _parseCreditCard(dynamic data) {
    if (data is Map) {
      if (data['card'] is Map) {
        return CreditCardModel.fromJson(
          Map<String, dynamic>.from(data['card'] as Map),
        );
      }
      if (data['data'] is Map) {
        return CreditCardModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return CreditCardModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Resposta invalida da API de cartoes de credito.');
  }
}
