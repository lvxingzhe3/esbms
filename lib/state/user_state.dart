import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

/// 用户信息状态 Provider
/// 使用 StateNotifier 管理用户登录信息
final userStateProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});

/// 用户状态
class UserState {
  final String? username;
  final String? password;
  final String? userId;
  final int role; // 权限 1:超级管理员 2:管理员1 3:管理员2
  final String? mds;
  final bool isLoggedIn;

  UserState({
    this.username,
    this.password,
    this.userId,
    this.role = 0,
    this.mds,
    this.isLoggedIn = false,
  });

  UserState copyWith({
    String? username,
    String? mds,
    String? userId,
    int? role = 0,
    Map<String, dynamic>? fullData,
    bool? isLoggedIn,
  }) {
    return UserState(
      username: username ?? this.username,
      mds: mds ?? this.mds,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

/*
role：
  0：普通用户->基础信息
  1：超级管理员->所有权限  
  2：管理员1->OTA升级权限和参数设置所有权限  
  3：管理员2->OTA升级权限和参数设置的基础设置权限(其他参数不可设置)
*/
class UserCredential {
  String account;
  final String password;
  final int role;
  final DateTime createdAt;
  bool isLogin;

  // 改为位置参数
  UserCredential(
    this.account,
    this.password,
    this.role, {
    DateTime? createdAt,
    this.isLogin = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

final List<UserCredential?> Users = [
  UserCredential("user", "123456", 0),
  UserCredential("sinota", "sinota20260537", 1),
  UserCredential("admin", "35192012", 2),
  UserCredential("admin", "57213063", 3)
];

/// 用户状态管理器
class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;
  UserNotifier(this.ref) : super(UserState());
  UserCredential CurrentUser = UserCredential("user", "123456", 0);

  /// 用户登陆状态
  bool isLoggedIn = false;
  UserState? userState;

  /// 登录并保存用户信息
  Future<void> login(String _name, String _password) async {
    try {
      if (_name.isEmpty || _password.isEmpty) {
        return;
      }
      var user = Users.firstWhere(
          (u) => u?.account == _name && u?.password == _password,
          orElse: () => null);
      if (user != null && user.account.isNotEmpty) {
        CurrentUser = user;
        user.isLogin = true;
        isLoggedIn = true;

        // 保存用户信息
        state = UserState(
          username: user.account,
          password: user.password,
          role: user.role,
          isLoggedIn: true,
        );
        userState = state;
      }
    } catch (e) {
      isLoggedIn = false;
      // 登录失败，清空状态
      state = UserState(isLoggedIn: false);
      rethrow;
    }
  }

  //updateUserState
  void updateUserState(String name, int role, bool islogin) {
    CurrentUser = UserCredential(name, "", 1);
    state = state.copyWith(username: name, role: role, isLoggedIn: islogin);
  }

  /// 获取 mds
  String? get mds => state.mds;

  /// 获取 userId
  String? get userId => state.userId;

  /// 登出
  void logout() {
    isLoggedIn = false;
    state = UserState(isLoggedIn: false);
    CurrentUser = UserCredential("user", "123456", 0);
  }
}
