import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/state/gpsuser_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// 设备位置 Provider
/// 获取设备的经纬度坐标
final locationProvider = FutureProvider<LatLng>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final gpsuserNotifier = ref.read(gpsuserStateProvider.notifier);

  try {
    // 如果用户未登录，先登录
    if (!gpsuserNotifier.isGpsLogin) {
      await gpsuserNotifier.gpslogin();
    }

    // 获取用户信息
    final mds = gpsuserNotifier.mds;
    final userId = gpsuserNotifier.userId;

    // 验证用户信息
    if (mds == null || userId == null) {
      gpsuserNotifier.isGpsLogin=false;
      throw Exception('用户信息缺少必要字段: mds 或 id');
    }

    // 获取设备位置数据
    final deviceLocation = await apiService.getDeviceLocation(
      mds: mds,
      user_id: userId,
    );

    // 验证返回数据结构
    if (!deviceLocation.containsKey('data')) {
       gpsuserNotifier.isGpsLogin=false;
      throw Exception('位置数据格式错误: 缺少 data 字段');
    }

    final data = deviceLocation['data'] as List;
    if (data.isEmpty) {
       gpsuserNotifier.isGpsLogin=false;
      throw Exception('位置数据为空');
    }

    final records = data[0]['records'] as List;
    if (records.isEmpty) {
       gpsuserNotifier.isGpsLogin=false;
      throw Exception('位置记录为空');
    }

    final valueList = records[0] as List;
    if (valueList.length < 4) {
      throw Exception('位置数据格式错误: 索引超出范围');
    }

    // 提取经纬度 (索引 2: 经度, 索引 3: 纬度)
    final longitude = (valueList[2] as num).toDouble();
    final latitude = (valueList[3] as num).toDouble();

    // 验证经纬度范围
    if (longitude < -180 || longitude > 180) {
      throw Exception('经度超出有效范围: $longitude');
    }
    if (latitude < -90 || latitude > 90) {
      throw Exception('纬度超出有效范围: $latitude');
    }

    print('设备位置 - 经度: $longitude, 纬度: $latitude');

    return LatLng(latitude, longitude);
  } catch (e) {
    throw Exception('获取设备位置失败: $e');
  }
  
});



