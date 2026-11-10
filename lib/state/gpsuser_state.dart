import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/utils/securestorageutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 用户信息状态 Provider
/// 使用 StateNotifier 管理用户登录信息
final gpsuserStateProvider =
    StateNotifierProvider<GpsUserNotifier, GpsUserState>((ref) {
  return GpsUserNotifier(ref);
});

/// 用户状态
class GpsUserState {
  final String? gpsusername;
  final String? gpspassword;
  final String? mds;
  final String? userId;
  final Map<String, dynamic>? fullData;
  final bool isLoggedIn;

  GpsUserState({
    this.gpsusername,
    this.gpspassword,
    this.mds,
    this.userId,
    this.fullData,
    this.isLoggedIn = false,
  });

  GpsUserState copyWith({
    String? mds,
    String? userId,
    Map<String, dynamic>? fullData,
    bool? isLoggedIn,
  }) {
    return GpsUserState(
      mds: mds ?? this.mds,
      userId: userId ?? this.userId,
      fullData: fullData ?? this.fullData,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

/// 用户状态管理器
class GpsUserNotifier extends StateNotifier<GpsUserState> {
  final Ref ref;

  GpsUserNotifier(this.ref) : super(GpsUserState());

  /// gps登录并保存用户信息
  Future<void> gpslogin({
    String language = 'cn',
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final userInfo = await apiService.gpsuserLogin(
        name: gpsusername!,
        password: gpspassword!,
        language: language,
      );

      // 保存用户信息
      state = GpsUserState(
        mds: userInfo['mds'] as String?,
        userId: userInfo['id'] as String?,
        fullData: userInfo,
        isLoggedIn: true,
      );

      if (!isGpsLogin) {
        isGpsLogin = true;
        await SecureStorageUtil.save('gpsusername', gpsusername!);
        await SecureStorageUtil.save('gpspassword', gpspassword!);
      }
    } catch (e) {
      gpsusername = null;
      gpspassword = null;
      isGpsLogin = false;
      // 登录失败，清空状态
      state = GpsUserState(isLoggedIn: false);
      rethrow;
    }
  }

  /// 登出
  void logout() {
    state = GpsUserState(isLoggedIn: false);
  }

  /// gps登陆状态
  bool isGpsLogin = false;

  ///gps用户名
  String? gpsusername;

  ///gps密码
  String? gpspassword;

  /// 获取 mds
  String? get mds => state.mds;

  /// 获取 userId
  String? get userId => state.userId;

  /// 获取完整的用户数据
  Map<String, dynamic>? get fullData => state.fullData;

  /// 是否已登录
  bool get isLoggedIn => state.isLoggedIn;
}
