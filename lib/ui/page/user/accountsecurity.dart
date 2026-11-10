import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/utils/securestorageutil.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/helper/topsnackbar.dart';

class AccountSecurity extends ConsumerStatefulWidget {
  const AccountSecurity({super.key});

  @override
  ConsumerState<AccountSecurity> createState() => _AccountSecurityState();
}

class _AccountSecurityState extends ConsumerState<AccountSecurity> {
  SharedPreferenceHelper prefs = SharedPreferenceHelper();
  // 获取当前语言代码
  String? currentLang;
  bool _isBusy = false; // 标记是否正在执行
  @override
  void initState() {
    super.initState();
  }

  // 登陆弹窗
  Future<Map<String, String>?> showUserLoginDialog(
      String? _username, String? _password) async {
    // 控制器 - 在方法内部创建
    TextEditingController userController =
        TextEditingController(text: _username);
    TextEditingController passController =
        TextEditingController(text: _password);

    // 使用 Completer 来处理异步返回（避免复杂的嵌套）
    Completer<Map<String, String>?> completer = Completer();

    await showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: customText(S.of(context).login, style: TextStyles.textStyle14),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: S.of(context).account,
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: InputDecoration(
                  labelText: S.of(context).password,
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 取消 - 返回 null
                completer.complete(null);
                Navigator.pop(context);
              },
              child: customText(S.of(context).cancel,
                  style: TextStyles.textStyle14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, // 正常背景色
                foregroundColor: Colors.white, // 文字/图标颜色
                elevation: 5, // 阴影高度，数值越大阴影越明显
                shadowColor: AppColor.primary.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // 确认 - 返回用户名密码
                completer.complete({
                  'username': userController.text,
                  'password': passController.text,
                });
                Navigator.pop(context);
              },
              child: customText(S.of(context).login,
                  style: TextStyles.textStyle14),
            ),
          ],
        );
      },
    );

    // 返回 Future 结果
    return completer.future;
  }

  //登出弹窗
  Future<bool> showUserLogoutDialog(String _username) async {
    // 使用 Completer 来处理异步返回（避免复杂的嵌套）
    Completer<bool> completer = Completer();

    await showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud,
          title:
              customText(S.of(context).logout, style: TextStyles.textStyle14),
          content: Row(children: [
            Text(S.of(context).currentuser + "：",
                style: TextStyles.textStyle14),
            Text(_username,
                style: TextStyles.textStyle14.copyWith(color: Colors.blue)),
          ]),
          actions: [
            TextButton(
              onPressed: () {
                // 取消 - 返回 null
                completer.complete(false);
                Navigator.pop(context);
              },
              child: customText(S.of(context).cancel,
                  style: TextStyles.textStyle14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, // 正常背景色
                foregroundColor: Colors.white, // 文字/图标颜色
                elevation: 5, // 阴影高度，数值越大阴影越明显
                shadowColor: AppColor.primary.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                completer.complete(true);
                Navigator.pop(context);
              },
              child: customText(S.of(context).logout,
                  style: TextStyles.textStyle14),
            ),
          ],
        );
      },
    );

    // 返回 Future 结果
    return completer.future;
  }

  //注销弹窗
  Future<bool> showDeleteUserDialog(String _username) async {
    // 使用 Completer 来处理异步返回（避免复杂的嵌套）
    Completer<bool> completer = Completer();

    await showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: customText(S.of(context).deleteAccount,
              style: TextStyles.textStyle14),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text("${S.of(context).currentuser}：",
                    style: TextStyles.textStyle14),
                Text(_username,
                    style: TextStyles.textStyle14.copyWith(color: Colors.blue)),
              ]),
              Text(S.of(context).deleteuserTip,
                  style: TextStyles.textStyle14.copyWith(color: Colors.orange)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 取消 - 返回 null
                completer.complete(false);
                Navigator.pop(context);
              },
              child: customText(S.of(context).cancel,
                  style: TextStyles.textStyle14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, // 正常背景色
                foregroundColor: Colors.white, // 文字/图标颜色
                elevation: 5, // 阴影高度，数值越大阴影越明显
                shadowColor: AppColor.primary.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                completer.complete(true);
                Navigator.pop(context);
              },
              child: customText(S.of(context).deleteAccount,
                  style: TextStyles.textStyle14),
            ),
          ],
        );
      },
    );

    // 返回 Future 结果
    return completer.future;
  }

  //登陆处理
  void _handleUserLogin() async {
    context.goNamed(AppRouter.login);
    /*
    final userNotifier = ref.read(userStateProvider.notifier);
    Map<String, String>? result = await showUserLoginDialog("", "");
    // 处理返回的数据
    if (result != null) {
      String username = result['username']!;
      String password = result['password']!;
      userNotifier.login(username, password);
      if (userNotifier.isLoggedIn) {
        TopSnackBar.show(
          context,
          S.of(context).loggedIn,
          backgroundColor: AppColor.info,
          icon: Icons.check_circle,
          duration: Duration(seconds: 2),
        );
      } else {
        TopSnackBar.show(
          context,
          S.of(context).userinfowrong,
          backgroundColor: AppColor.warn,
          icon: Icons.error,
          duration: Duration(seconds: 2),
        );
      }
    } else {
      return;
    }
    setState(() {});
    */
  }

  //登出处理
  void _handleUserLogout() async {
    final userNotifier = ref.read(userStateProvider.notifier);
    bool result = await showUserLogoutDialog(userNotifier.CurrentUser.account);
    // 处理返回的数据
    if (result) {
      userNotifier.logout();
      await SecureStorageUtil.save('account', "");
      await SecureStorageUtil.save('password', "");
      context.goNamed(AppRouter.login);
      TopSnackBar.show(
        context,
        S.of(context).loggedOut,
        backgroundColor: AppColor.info,
        icon: Icons.check_circle,
        duration: Duration(seconds: 2),
      );
    } else {
      return;
    }
    setState(() {});
  }

  //注销账号
  void _handleAccountDeletion() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });
    try {
      final userNotifier = ref.read(userStateProvider.notifier);
      bool result =
          await showDeleteUserDialog(userNotifier.CurrentUser.account);
      // 处理返回的数据
      if (result) {
        var apiService = ref.read(apiServiceProvider);
        var rec = await apiService.deleteAccount();
        var apiRes = ApiResponse.fromJson(rec);
        if (apiRes.code == 0) {
          userNotifier.logout();
          await SecureStorageUtil.save('account', "");
          await SecureStorageUtil.save('password', "");

          TopSnackBar.show(
            context,
            S.of(context).deleteAccount,
            backgroundColor: AppColor.info,
            icon: Icons.check_circle,
            duration: Duration(seconds: 2),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.goNamed(AppRouter.login);
          }
        } else {
          TopSnackBar.show(
            context,
            apiRes.message,
            backgroundColor: AppColor.warn,
            icon: Icons.error,
            duration: Duration(seconds: 2),
          );
        }
      } else {
        return;
      }
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStateProvider);
    final roleNumm = userState.role;
    final username = userState.username;
    return PopScope(
      canPop: !_isBusy,
      child: Stack(
        children: [
          Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: customTitleText(S.of(context).accountsecurity),
                centerTitle: true,
                backgroundColor: Colors.transparent, // AppBar 透明
                elevation: 0, // 移除底部阴影，否则会有灰色分层
              ),
              body: CustomBackground(
                child: ListView(
                    padding: EdgeInsets.only(bottom: 16),
                    children: <Widget>[
                      GFCard(
                        color: AppColor.backgroud,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //用户登录
                            Visibility(
                              visible: roleNumm == 0,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _handleUserLogin,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(border: Border()),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          size: 28,
                                          IconFont.login,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        customText(S.of(context).userload,
                                            style: TextStyles.textStyle14),
                                        Spacer(),
                                        customIcon(context,
                                            icon: AppIcon.chevron_right,
                                            size: 24,
                                            isTwitterIcon: false,
                                            iconColor: AppColor.primary)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            //用户登出
                            Visibility(
                              visible: roleNumm > 0,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _handleUserLogout,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          size: 28,
                                          IconFont.logout,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        customText(
                                            S.of(context).logout +
                                                '($username)',
                                            style: TextStyles.textStyle14),
                                        Spacer(),
                                        customIcon(context,
                                            icon: AppIcon.chevron_right,
                                            size: 24,
                                            isTwitterIcon: false,
                                            iconColor: AppColor.primary)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            //注销用户
                            Visibility(
                              visible: GlobalData.DeviceConnectType > 0,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _handleAccountDeletion,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      border: Border(
                                          top: BorderSide(
                                              color: AppColor.darkGrey))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          size: 28,
                                          IconFont.deleteaccount,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        customText(S.of(context).deleteAccount,
                                            style: TextStyles.textStyle14),
                                        Spacer(),
                                        customIcon(context,
                                            icon: AppIcon.chevron_right,
                                            size: 24,
                                            isTwitterIcon: false,
                                            iconColor: AppColor.primary)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ]),
              )),
          if (_isBusy)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
