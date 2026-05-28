import 'package:dio/dio.dart';

import '../../../../domain/entities/bank_account_entity.dart';
import '../../../datasources/bank_account_datasource.dart';
import '../../../mappers/bank_account_codec.dart';
import '../../../models/bank_account_model.dart';

class NestBankAccountRemoteDataSource implements IBankAccountDataSource {
  NestBankAccountRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    final response = await dio.get('/finance/bank-accounts');
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
        ? (data['data'] ?? data['bankAccounts'] ?? [])
        : [];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) => BankAccountModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<BankAccountModel> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    final response = await dio.post(
      '/finance/bank-accounts',
      data: {
        'name': name,
        'bankName': bankName,
        'color': color,
        'accountType': AccountTypeCodec.encode(accountType),
        'initialBalanceCents': initialBalanceCents,
      },
    );

    return _parseBankAccount(response.data);
  }

  @override
  Future<BankAccountModel> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'bankName': bankName,
      'color': color,
      'accountType': AccountTypeCodec.encode(accountType),
      'initialBalanceCents': initialBalanceCents,
    };

    if (isActive != null) {
      data['isActive'] = isActive;
    }

    final response = await dio.patch('/finance/bank-accounts/$id', data: data);
    return _parseBankAccount(response.data);
  }

  @override
  Future<void> deactivateBankAccount(int id) {
    return dio.delete('/finance/bank-accounts/$id');
  }

  @override
  Future<void> reactivateBankAccount(int id) {
    return dio.patch('/finance/bank-accounts/$id', data: {'isActive': true});
  }

  BankAccountModel _parseBankAccount(dynamic data) {
    if (data is Map) {
      if (data['account'] is Map) {
        return BankAccountModel.fromJson(
          Map<String, dynamic>.from(data['account'] as Map),
        );
      }
      if (data['bankAccount'] is Map) {
        return BankAccountModel.fromJson(
          Map<String, dynamic>.from(data['bankAccount'] as Map),
        );
      }
      if (data['data'] is Map) {
        return BankAccountModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return BankAccountModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Resposta invalida da API de contas bancarias.');
  }
}
