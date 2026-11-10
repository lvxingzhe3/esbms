class ApiResponse<T> {
  final int code;
  final String message;
  final String? localMessage;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.localMessage,
    this.data,
  });

  // JSON → 对象
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: json["code"] as int,
      message: json["message"] as String,
      localMessage: json["localMessage"],
      data: json["data"],
    );
  }

  // 对象 → JSON
  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "message": message,
      "localMessage":localMessage,
      "data": data,
    };
  }
}
