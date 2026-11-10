import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/state/user_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// BMS 设备实时状态 Provider
/// 获取指定设备的 BMS 实时数据
final bmsStateProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, macid) async {
  final apiService = ref.watch(apiServiceProvider);
  final userNotifier = ref.read(userStateProvider.notifier);

  try {
    // 如果用户未登录，先登录
    if (!userNotifier.isLoggedIn) {
      await userNotifier.login(userNotifier.CurrentUser.account,userNotifier.CurrentUser.password);
    }

    // 获取用户信息
    final mds = userNotifier.mds;
    final userId = userNotifier.userId;

    // 验证用户信息
    if (mds == null || userId == null) {
      throw Exception('用户信息缺少必要字段: mds 或 id');
    }

    // 获取 BMS 设备实时状态数据
    final bmsData = await apiService.getBmsRealTimeStatus(
      mds: mds,
      macid: macid,
    );

    // 验证返回数据结构
    if (bmsData.isEmpty) {
      throw Exception('BMS 状态数据为空');
    }

    print('BMS 设备状态 - macid: $macid, 数据: ${bmsData.keys.join(", ")}');

    return bmsData;
  } catch (e) {
    throw Exception('获取 BMS 设备状态失败: $e');
  }
});
