import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/providers/locale_provider.dart';
import 'package:bms_app/state/gpsuser_state.dart';
import 'package:bms_app/state/location_state.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/utils/securestorageutil.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/radio_list_tile/gf_radio_list_tile.dart';
import 'package:getwidget/types/gf_radio_type.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/helper/topsnackbar.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  SharedPreferenceHelper prefs = SharedPreferenceHelper();
  // 获取当前语言代码
  String? currentLang;

  @override
  void initState() {
    super.initState();
    _loadGpsUser();
  }

  Future<void> _loadGpsUser() async {
    final gpsuserNotifier = ref.read(gpsuserStateProvider.notifier);
    String? username = await SecureStorageUtil.get('gpsusername');
    String? password = await SecureStorageUtil.get('gpspassword');
    if (username != null && password != null) {
      gpsuserNotifier.gpsusername = username;
      gpsuserNotifier.gpspassword = password;
    }
  }

  // 更新语言
  void updateLanguageCode(String lang) async {
    Map langRegionMap = {'en': 'US', 'zh': 'CN'};
    await S.load(Locale(lang, langRegionMap[lang]));
    await prefs.saveLang(lang);
    setState(() {
      currentLang = lang;
      GlobalData.language = lang;
      ref.read(localeProvider.notifier).state = Locale(lang);
    });
    print('lang: $lang');
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

  //弹出登陆gps账号弹窗
  Future<Map<String, String>?> showgpsLoginDialog(
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
          //dialogBackgroundColor: AppColor.backgroud,
          title:
              customText(S.of(context).gpslogin, style: TextStyles.textStyle14),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                style: TextStyles.textStyle14,
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
                style: TextStyles.textStyle14,
                decoration: InputDecoration(
                  //提示文字
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

  //登陆gps账号
  void _handleLoginGpsUser() async {
    final gpsuserNotifier = ref.read(gpsuserStateProvider.notifier);
    //&&(gpsuserNotifier.gpsusername!.isEmpty || gpsuserNotifier.gpspassword!.isEmpty)
    if (!gpsuserNotifier.isGpsLogin) {
      // 直接调用并等待结果
      Map<String, String>? result = await showgpsLoginDialog(
          gpsuserNotifier.gpsusername, gpsuserNotifier.gpspassword);
      // 处理返回的数据
      if (result != null) {
        String username = result['username']!;
        String password = result['password']!;
        gpsuserNotifier.gpsusername = username;
        gpsuserNotifier.gpspassword = password;
      } else {
        return;
      }
    }

    ref.invalidate(locationProvider);
    await context.pushNamed(AppRouter.map);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('currentLang: $currentLang');
    final userState = ref.watch(userStateProvider);
    final roleNumm = userState.role;
    final username = userState.username;
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: customTitleText(S.of(context).userPage),
          centerTitle: true,
          backgroundColor: Colors.transparent, // AppBar 透明
          elevation: 0, // 移除底部阴影，否则会有灰色分层
        ),
        body: CustomBackground(
          child:
              ListView(padding: EdgeInsets.only(bottom: 16), children: <Widget>[
            GFCard(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: AppColor.backgroud,
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        context.pushNamed(AppRouter.wificonfigfind);
                      },
                      child: Column(
                        children: [
                          Icon(
                            IconFont.bluewifi,
                            size: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 5), // 自由调整间距
                          customText(S.of(context).bluewifi,
                              style: TextStyles.textStyle14),
                        ],
                      ),
                    ),
                    SizedBox(width: 15),
                    InkWell(
                      onTap: () {
                        context.pushNamed(AppRouter.privacy);
                      },
                      child: Column(
                        children: [
                          Icon(
                            IconFont.agreement,
                            size: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 5), // 自由调整间距
                          customText(S.of(context).agreement,
                              style: TextStyles.textStyle14),
                        ],
                      ),
                    ),
                    SizedBox(width: 15),
                    InkWell(
                      onTap: () {
                        context.pushNamed(AppRouter.faqpage);
                      },
                      child: Column(
                        children: [
                          Icon(
                            IconFont.question,
                            size: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 5), // 自由调整间距
                          customText(S.of(context).question,
                              style: TextStyles.textStyle14),
                        ],
                      ),
                    ),
                  ],
                )),
            SizedBox(height: 0),
            GFCard(
              color: AppColor.backgroud,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //软件信息
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      context.pushNamed(AppRouter.firmware);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              size: 28,
                              IconFont.softwareinfo,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 4),
                            customText(S.of(context).sofewareInfo,
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
                  //设备位置
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    //onTap: () async { context.pushNamed(AppRouter.map); },
                    onTap: _handleLoginGpsUser,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppColor.darkGrey))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              size: 28,
                              IconFont.position,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 4),
                            customText(S.of(context).deviceLocation,
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
                  //升级
                  Visibility(
                    visible: roleNumm > 0 && GlobalData.DeviceConnectType == 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        context.pushNamed(AppRouter.otaupgrade);
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: AppColor.darkGrey))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                size: 28,
                                IconFont.otaupgrade,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 4),
                              customText(S.of(context).otaUpgrade,
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
                  //语言
                  DecoratedBox(
                    decoration: BoxDecoration(
                        color: AppColor.backgroud,
                        border:
                            Border(top: BorderSide(color: AppColor.darkGrey))),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        if (currentLang == null) {
                          currentLang = await prefs.getLang();
                        }
                        setState(() {});
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showModalBottomSheet(
                            backgroundColor: AppColor.backgroud,
                            context: context,
                            isDismissible: true,
                            builder: (BuildContext context) {
                              return Container(
                                height: 120,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const ScrollPhysics(),
                                  children: [
                                    GFRadioListTile(
                                      title: customText(S.of(context).chinese,
                                          style: TextStyles.textStyle16),
                                      size: 20,
                                      activeBorderColor: Colors.green,
                                      focusColor: Colors.green,
                                      type: GFRadioType.basic,
                                      value: 'zh',
                                      groupValue: currentLang,
                                      onChanged: (value) {
                                        updateLanguageCode(value);
                                        context.pop();
                                      },
                                      inactiveIcon: null,
                                    ),
                                    GFRadioListTile(
                                      title: customText(S.of(context).english,
                                          style: TextStyles.textStyle16),
                                      size: 20,
                                      activeBorderColor: Colors.green,
                                      focusColor: Colors.green,
                                      type: GFRadioType.basic,
                                      value: 'en',
                                      groupValue: currentLang,
                                      onChanged: (value) {
                                        updateLanguageCode(value);
                                        context.pop();
                                      },
                                      inactiveIcon: null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              size: 28,
                              IconFont.language,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 4),
                            customText(S.of(context).langSwitch,
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
                  //账号安全
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      context.pushNamed(AppRouter.accountsecurity);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppColor.darkGrey))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              size: 28,
                              Icons.person_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 4),
                            customText(S.of(context).accountsecurity,
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
                ],
              ),
            )
          ]),
        ));
  }
}
