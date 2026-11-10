import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String baseUrl = ""}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        Headers.contentTypeHeader: Headers.jsonContentType,
      },
    ));

    // 请求拦截器：可统一添加全局header、签名
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 这里可以统一添加全局header，例如token
          // options.headers["Authorization"] = "Bearer xxx";
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // 合并header，保证json contentType
      final opt = _mergeOptions(options);
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final opt = _mergeOptions(options);
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opt = _mergeOptions(options);
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opt,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 合并Options，保证Content‑Type为json，合并自定义headers
  Options _mergeOptions(Options? options) {
    final Map<String, dynamic> headers = {
      Headers.contentTypeHeader: Headers.jsonContentType,
    };
    if (options?.headers != null) {
      headers.addAll(options!.headers!);
    }
    return Options(
      contentType: Headers.jsonContentType,
      headers: headers,
      sendTimeout: options?.sendTimeout,
      receiveTimeout: options?.receiveTimeout,
      responseType: options?.responseType,
      extra: options?.extra,
    );
  }

  /// 统一Dio异常处理
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "连接超时";
      case DioExceptionType.sendTimeout:
        return "发送超时";
      case DioExceptionType.receiveTimeout:
        return "接收超时";
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return "服务端错误：$statusCode";
      case DioExceptionType.cancel:
        return "请求已取消";
      case DioExceptionType.connectionError:
        return "网络异常，请检查网络";
      default:
        return "未知错误：${e.message}";
    }
  }

  /// 安全解析接口返回数据（防止Map/List类型报错）
  static Map<String, dynamic>? parseResponseMap(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  /// 关闭dio
  void close() {
    _dio.close();
  }
}
