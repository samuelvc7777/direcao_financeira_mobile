import 'dart:io';

import 'package:dio/dio.dart';

DioException dioBadResponse({
  required int statusCode,
  required dynamic data,
  String path = '/test',
  String method = 'GET',
}) {
  final requestOptions = RequestOptions(path: path, method: method);
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException dioTimeout({
  String path = '/test',
  String method = 'GET',
  DioExceptionType type = DioExceptionType.connectionTimeout,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: method),
    type: type,
    message: 'timeout',
  );
}

DioException dioConnectionError({
  String path = '/test',
  String method = 'GET',
}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: method),
    type: DioExceptionType.connectionError,
    error: const SocketException('Failed host lookup'),
    message: 'connection error',
  );
}
