import 'package:bms_app/network/api_service.dart';
import 'package:bms_app/network/dio_client.dart';
import 'package:bms_app/state/gpsuser_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio 客户端 Provider
///
/// 使用方式：
/// ```dart
/// final dioClient = ref.watch(dioClientProvider);
/// final response = await dioClient.get('/api/endpoint');
/// ```
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: 'https://solar.siseli.com/openapis',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    onBusinessError403: () async {
      // 当业务接口返回 403 时，自动重新登录
      final gpsuserNotifier = ref.read(gpsuserStateProvider.notifier);
      await gpsuserNotifier.gpslogin();
    },
  );
});

/// Dio 实例 Provider（直接访问 Dio）
///
/// 使用方式：
/// ```dart
/// final dio = ref.watch(dioProvider);
/// final response = await dio.get('/api/endpoint');
/// ```
final dioProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return dioClient.dio;
});

/// API Service Provider
///
/// 使用方式：
/// ```dart
/// final apiService = ref.watch(apiServiceProvider);
/// final userInfo = await apiService.getUserInfo('123');
/// ```
final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiService(dioClient);
});
