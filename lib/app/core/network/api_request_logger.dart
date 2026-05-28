import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_error_mapper.dart';

class ApiRequestLogger {
  ApiRequestLogger({required this.apiErrorMapper, this.enabled = kDebugMode});

  final ApiErrorMapper apiErrorMapper;
  final bool enabled;

  void logRequest(RequestOptions options) {
    if (!enabled) {
      return;
    }

    final payloadSummary = apiErrorMapper.summarizePayload(options.data);
    debugPrint(
      '[API][REQUEST] ${options.method.toUpperCase()} ${options.path} payload=$payloadSummary',
    );
  }

  void logResponse(Response<dynamic> response) {
    if (!enabled) {
      return;
    }

    final payloadSummary = apiErrorMapper.summarizePayload(response.data);
    debugPrint(
      '[API][RESPONSE] ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.path} status=${response.statusCode} data=$payloadSummary',
    );
  }

  void logError(DioException error) {
    if (!enabled) {
      return;
    }

    final details = apiErrorMapper.toLogDetails(error);
    if (details == null) {
      debugPrint('[API][ERROR] ${error.runtimeType}: $error');
      return;
    }

    debugPrint(
      '[API][ERROR] ${details.method} ${details.path} status=${details.statusCode ?? 'null'} type=${details.type} message=${details.message ?? 'null'} data=${details.responseSummary}',
    );
  }

  void logRepositoryFailure({required String source, required Object error}) {
    if (!enabled) {
      return;
    }

    final details = apiErrorMapper.toLogDetails(error);
    if (details == null) {
      debugPrint(
        '[REPOSITORY][ERROR] $source type=${error.runtimeType} error=$error',
      );
      return;
    }

    debugPrint(
      '[REPOSITORY][ERROR] $source ${details.method} ${details.path} status=${details.statusCode ?? 'null'} type=${details.type} data=${details.responseSummary}',
    );
  }

  void logInfo({required String source, required String message}) {
    if (!enabled) {
      return;
    }

    debugPrint('[REPOSITORY][INFO] $source $message');
  }
}
