/// API 异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (statusCode: $statusCode)';
  }

  /// 网络错误
  factory ApiException.networkError() {
    return ApiException(
      message: '网络连接失败，请检查网络设置',
      statusCode: -1,
    );
  }

  /// 超时错误
  factory ApiException.timeout() {
    return ApiException(
      message: '请求超时，请稍后重试',
      statusCode: -2,
    );
  }

  /// 请求取消
  factory ApiException.cancelled() {
    return ApiException(
      message: '请求已取消',
      statusCode: -3,
    );
  }

  /// 未知错误
  factory ApiException.unknown(String? message) {
    return ApiException(
      message: message ?? '未知错误',
      statusCode: -4,
    );
  }

  /// 服务器错误
  factory ApiException.serverError(int statusCode, String? message) {
    return ApiException(
      message: message ?? '服务器错误',
      statusCode: statusCode,
    );
  }

  /// 400 错误请求
  factory ApiException.badRequest(String? message) {
    return ApiException(
      message: message ?? '请求参数错误',
      statusCode: 400,
    );
  }

  /// 401 未授权
  factory ApiException.unauthorized(String? message) {
    return ApiException(
      message: message ?? '未授权，请重新登录',
      statusCode: 401,
    );
  }

  /// 403 禁止访问
  factory ApiException.forbidden(String? message) {
    return ApiException(
      message: message ?? '禁止访问',
      statusCode: 403,
    );
  }

  /// 404 未找到
  factory ApiException.notFound(String? message) {
    return ApiException(
      message: message ?? '资源未找到',
      statusCode: 404,
    );
  }

  /// 500 服务器内部错误
  factory ApiException.internalServerError(String? message) {
    return ApiException(
      message: message ?? '服务器内部错误',
      statusCode: 500,
    );
  }

  /// 业务错误
  factory ApiException.businessError(dynamic errorCode, String? message) {
    return ApiException(
      message: message ?? '业务处理失败',
      statusCode: int.tryParse(errorCode.toString()),
      data: errorCode,
    );
  }
}
