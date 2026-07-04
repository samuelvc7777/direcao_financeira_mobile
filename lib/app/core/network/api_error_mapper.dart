import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';

class ApiErrorLogDetails {
  const ApiErrorLogDetails({
    required this.method,
    required this.path,
    required this.type,
    required this.responseSummary,
    this.statusCode,
    this.message,
  });

  final String method;
  final String path;
  final String type;
  final String responseSummary;
  final int? statusCode;
  final String? message;
}

class ApiErrorMapper {
  const ApiErrorMapper();

  Failure mapToFailure(Object error, {required String fallback}) {
    if (error is Failure) {
      return error;
    }

    if (error is DioException) {
      final extractedMessage = extractMessage(error, fallback: fallback);
      final lowerMessage = extractedMessage.toLowerCase();
      final statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        return AuthFailure(extractedMessage);
      }

      if (_isConnectivityError(error) ||
          _looksLikeConnectivityMessage(lowerMessage)) {
        return NetworkFailure(
          'Verifique sua conexao com a internet e tente novamente.',
        );
      }

      if (_isTimeoutError(error) || lowerMessage.contains('timeout')) {
        return NetworkFailure(
          'O servidor demorou para responder. Tente novamente em instantes.',
        );
      }

      return ServerFailure(extractedMessage);
    }

    if (error is SocketException) {
      return NetworkFailure(
        'Verifique sua conexao com a internet e tente novamente.',
      );
    }

    if (error is AuthException) {
      return AuthFailure(
        error.message.trim().isEmpty ? fallback : error.message,
      );
    }

    if (error is PostgrestException) {
      final message = error.message.trim();
      if (message.toLowerCase().contains('jwt') ||
          message.toLowerCase().contains('permission') ||
          error.code == '42501') {
        return AuthFailure(message.isEmpty ? fallback : message);
      }

      return ServerFailure(message.isEmpty ? fallback : message);
    }

    return ServerFailure(fallback);
  }

  String extractMessage(Object error, {required String fallback}) {
    if (error is Failure) {
      return error.message;
    }

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        if (message != null) {
          return message.toString();
        }
      }

      if (_isConnectivityError(error)) {
        return 'Falha de conexao com o servidor.';
      }

      if (_isTimeoutError(error)) {
        return 'Tempo limite de conexao excedido.';
      }

      final rawMessage = error.message?.trim();
      if (rawMessage != null && rawMessage.isNotEmpty) {
        return rawMessage;
      }
    }

    if (error is SocketException) {
      return 'Falha de conexao com o servidor.';
    }

    if (error is AuthException) {
      return error.message.trim().isEmpty ? fallback : error.message;
    }

    if (error is PostgrestException) {
      return error.message.trim().isEmpty ? fallback : error.message;
    }

    return fallback;
  }

  ApiErrorLogDetails? toLogDetails(Object error) {
    if (error is DioException) {
      final requestOptions = error.requestOptions;
      return ApiErrorLogDetails(
        method: requestOptions.method.toUpperCase(),
        path: requestOptions.path,
        statusCode: error.response?.statusCode,
        type: error.type.name,
        responseSummary: summarizePayload(error.response?.data),
        message: error.message,
      );
    }

    if (error is SocketException) {
      return const ApiErrorLogDetails(
        method: 'UNKNOWN',
        path: 'UNKNOWN',
        type: 'socketException',
        responseSummary: 'SocketException',
      );
    }

    return null;
  }

  String summarizePayload(dynamic data) {
    if (data == null) {
      return 'null';
    }

    final summary = data.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (summary.isEmpty) {
      return 'empty';
    }

    return summary.length <= 180 ? summary : '${summary.substring(0, 177)}...';
  }

  bool _isTimeoutError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  bool _isConnectivityError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.error is SocketException;
  }

  bool _looksLikeConnectivityMessage(String message) {
    return message.contains('socketexception') ||
        message.contains('connection error') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable');
  }
}
