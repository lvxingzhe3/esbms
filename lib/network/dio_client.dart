import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:bms_app/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Dio 客户端封装类
class DioClient {
  late Dio _dio;
  Function? _onBusinessError403;
  static const String baseBmsUrl = 'https://solar.siseli.com/openapis';
  static const String baseGpsUrl = 'http://openapi.18gps.net';

  /// 获取 Dio 实例
  Dio get dio => _dio;

  /// 构造函数
  DioClient({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    Function? onBusinessError403,
  }) {
    _onBusinessError403 = onBusinessError403;

    // 配置 Dio
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        sendTimeout: sendTimeout ?? const Duration(seconds: 30),
        headers: headers ?? {},
        responseType: ResponseType.json,
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(_JsonParseInterceptor());
    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
    _dio.interceptors.add(_BusinessErrorInterceptor(
      onBusinessError403: _onBusinessError403,
    ));

    /*
    // 跳过证书校验，仅开发环境
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // 所有证书全部放行
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    */
  }

  /// 设置 Authorization Token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 清除 Authorization Token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  //清理请求头
  void clearHeaders() {
    _dio.options.headers.clear();
  }

  /// 设置自定义请求头
  void setHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// 设置 Base URL 0: BMS 1: GPS
  Future<void> setBaseUrl(int baseurlType) async {
    if (baseurlType == 0) {
      _dio.options.baseUrl = baseBmsUrl;
    } else {
      _dio.options.baseUrl = baseGpsUrl;
    }
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET 请求
  Future<Response<T>> getgps<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // POST 请求默认使用 JSON content type
      final postOptions = options ??
          Options(
            contentType: Headers.jsonContentType,
            //headers: {'Content-Type': Headers.jsonContentType},
          );

      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: postOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // PUT 请求默认使用 JSON content type
      final putOptions = options ??
          Options(
            contentType: Headers.jsonContentType,
            headers: {'Content-Type': Headers.jsonContentType},
          );

      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: putOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH 请求
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // PATCH 请求默认使用 JSON content type
      final patchOptions = options ??
          Options(
            contentType: Headers.jsonContentType,
            headers: {'Content-Type': Headers.jsonContentType},
          );

      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: patchOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 文件上传
  Future<Response<T>> upload<T>(
    String path, {
    required String filePath,
    required String fileKey,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        ...?data,
        fileKey: await MultipartFile.fromFile(filePath),
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 文件下载
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout();

      case DioExceptionType.cancel:
        return ApiException.cancelled();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? error.message;

        switch (statusCode) {
          case 400:
            return ApiException.badRequest(message);
          case 401:
            return ApiException.unauthorized(message);
          case 403:
            return ApiException.forbidden(message);
          case 404:
            return ApiException.notFound(message);
          case 500:
            return ApiException.internalServerError(message);
          default:
            return ApiException.serverError(statusCode!, message);
        }

      case DioExceptionType.connectionError:
        return ApiException.networkError();

      case DioExceptionType.badCertificate:
        return ApiException.unknown('SSL 证书错误');

      case DioExceptionType.unknown:
        return ApiException.unknown(error.message);
      default:
        return ApiException.notFound(error.message);
    }
  }
}

/// JSON 反序列化拦截器
/// 统一处理响应数据，如果是字符串则自动解析为 JSON
class _JsonParseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 如果响应数据是字符串，尝试解析为 JSON
    if (response.data is String) {
      try {
        final jsonData = jsonDecode(response.data as String);
        response.data = jsonData;
      } catch (e) {
        developer.log(
          '⚠️ JSON 解析失败: $e',
          name: 'JsonParseInterceptor',
        );
        // 如果解析失败，保持原始字符串数据
      }
    }
    super.onResponse(response, handler);
  }
}

/// 日志拦截器
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '🚀 REQUEST[${options.method}] => PATH: ${options.uri}',
      name: 'DioClient',
    );
    developer.log(
      '🚀 Headers: ${options.headers}',
      name: 'DioClient',
    );
    if (options.data != null) {
      developer.log(
        '🚀 Body: ${options.data}',
        name: 'DioClient',
      );
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.uri}',
      name: 'DioClient',
    );
    developer.log(
      '✅ Data: ${response.data}',
      name: 'DioClient',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.uri}',
      name: 'DioClient',
    );
    developer.log(
      '❌ Error: ${err.message}',
      name: 'DioClient',
    );
    super.onError(err, handler);
  }
}

/// 错误拦截器（可用于统一处理 401 等错误）
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 统一处理 401 错误（如跳转登录页）
    if (err.response?.statusCode == 401) {
      //_TODO 跳转到登录页或刷新token
      developer.log(
        '⚠️ 未授权，需要重新登录',
        name: 'DioClient',
      );
    }

    super.onError(err, handler);
  }
}

/// 业务错误拦截器
class _BusinessErrorInterceptor extends Interceptor {
  final Function? onBusinessError403;

  _BusinessErrorInterceptor({this.onBusinessError403});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 检查业务响应中的 errorCode
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final errorCode = data['errorCode'];
      final errorMsg = data['msg'];

      // 如果存在业务错误码且不是成功状态
      if (errorCode == 403) {
        developer.log(
          '⚠️ 业务错误 403: $errorMsg - 尝试重新登录',
          name: 'BusinessErrorInterceptor',
        );

        // 调用回调函数处理 403 错误
        if (onBusinessError403 != null) {
          try {
            await onBusinessError403!();
            developer.log(
              '✅ 重新登录成功',
              name: 'BusinessErrorInterceptor',
            );
          } catch (e) {
            developer.log(
              '❌ 重新登录失败: $e',
              name: 'BusinessErrorInterceptor',
            );
          }
        }
      }
    }

    super.onResponse(response, handler);
  }
}
