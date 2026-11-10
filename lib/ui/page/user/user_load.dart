import 'dart:async';
import 'dart:convert';

import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/helper/topsnackbar.dart';
import 'package:bms_app/model/device.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/providers/locale_provider.dart';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/utils/loggerdebug_util.dart';
import 'package:bms_app/utils/securestorageutil.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/radio_list_tile/gf_radio_list_tile.dart';
import 'package:getwidget/types/gf_radio_type.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  late TextEditingController _phoneCtrl = TextEditingController();
  late TextEditingController _codeCtrl = TextEditingController();
  late TextEditingController _confirmPwdCtrl = TextEditingController();
  late TextEditingController _areaCtrl = TextEditingController(text: "+86");
  bool _loading = false;
  bool _obscurePwd = true;
  bool _isRegister = false; // 切换标记
  String captchaId = ""; // 验证码id
  Timer? _codeTimer;
  int _countDownSeconds = 0;
  SharedPreferenceHelper prefs = SharedPreferenceHelper();
  // 获取当前语言代码
  String? currentLang;
  bool isAgreeChecked = false;
  @override
  void initState() {
    super.initState();
    initPage();
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    _codeTimer?.cancel();
    _codeTimer = null;
    super.dispose();
  }

  Future<void> initPage() async {
    try {
      currentLang = await prefs.getLang();
      GlobalData.language = currentLang;
      //加载用户
      String? account = await SecureStorageUtil.get("account");
      String? password = await SecureStorageUtil.get("password");
      if (account != null &&
          account.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        isAgreeChecked = true;
        await login(account, password);
      }
    } finally {}
  }

  /// 模拟登录逻辑，这里可以接入你之前写的签名加密逻辑
  Future<void> _onLogin() async {
    try {
      final account = _accountCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      if (!isAgreeChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).selectagreementTip)));
        return;
      }
      if (account.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).inputaccount)));
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).inputpassword)));
        return;
      }

      await login(account, password);
    } catch (e) {
      LoggerDebugUtil.e('_onLogin', e);
    }
  }

  Future<void> login(String account, String password) async {
    try {
      setState(() {
        _loading = true;
      });
      final apiService = ref.read(apiServiceProvider);
      final userInfo =
          await apiService.userLogin(name: account, password: password);
      // todo: 这里调用你的接口，密码md5，生成nonce、hmac‑sha256签名，发起dio请求
      await Future.delayed(const Duration(seconds: 1));
      final apiRes = ApiResponse.fromJson(userInfo);
      // ===== 登录成功，跳转主页，并且销毁登录页面，无法返回 =====
      if (mounted) {
        if (apiRes.code == 0 && apiRes.data != null) {
          String token = apiRes.data['accessToken'] as String;
          String refreshToken = apiRes.data['refreshToken'] as String;
          if (token.isNotEmpty) {
            GlobalData.apiAccessToken = token;
            GlobalData.apiRefreshToken = refreshToken;
            await SecureStorageUtil.save('account', account);
            await SecureStorageUtil.save('password', password);
          }
          GlobalData.DeviceConnectType = 1;
          String? deviceStr = await SecureStorageUtil.get("device");
          if (deviceStr != null && deviceStr.isNotEmpty) {
            Map<String, dynamic> map = json.decode(deviceStr);
            DeviceItem device = DeviceItem.fromJson(map);
            if (device.id.isNotEmpty) {
              GlobalData.currentDeviceId = device.id;
              GlobalData.currentDeviceName = device.name;
              GlobalData.currentDtuId = device.dtuDtuid;
            }
          }

          //GoRouter.of(context).goNamed(AppRouter.home);
          context.goNamed(AppRouter.home);
          final userStateNotifier = ref.watch(userStateProvider.notifier);
          bool isAdmin = apiRes.data['isAdmin'] as bool;
          userStateNotifier.updateUserState(account, isAdmin ? 1 : 2, true);
        } else {
          TopSnackBar.show(
            context,
            apiRes.message ?? S.loginfail,
            backgroundColor: AppColor.info,
            icon: Icons.check_circle,
            duration: Duration(seconds: 2),
          );
        }
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// 获取验证码逻辑
  Future<void> _onGetCode() async {
    try {
      final phone = _phoneCtrl.text.trim();
      String areaCode = _areaCtrl.text.trim();
      if (phone.isEmpty || areaCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).inputphonecode)));
        return;
      }
      if (!RegExp(r'^[1][3-9][0-9]{9}$').hasMatch(phone)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).phonenumwrong)));
        return;
      }
      areaCode = areaCode.replaceAll("+", ""); // 去掉空格和加号
      final apiService = ref.read(apiServiceProvider);
      final userInfo = await apiService.getPhoneCode(phone, areaCode);
      final apiRes = ApiResponse.fromJson(userInfo);
      if (apiRes.code != 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiRes.message ?? "获取验证码失败")));
      } else {
        captchaId = apiRes.data['iotCaptchaId'];
        // 开启60秒倒计时
        _countDownSeconds = 60;
        _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _countDownSeconds--;
          });
          if (_countDownSeconds <= 0) {
            timer.cancel();
          }
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).sentvercode)));
      }
    } catch (e) {
      LoggerDebugUtil.e('_onGetCode', e);
    }
  }

  // 注册回调
  Future<void> _onRegister() async {
    try {
      final account = _accountCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final code = _codeCtrl.text.trim();
      final confirmPwd = _confirmPwdCtrl.text.trim();
      String areaCode = _areaCtrl.text.trim();
      areaCode = areaCode.replaceAll("+", "");
      if (account.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).inputaccount)));
        return;
      }
      if (password.isEmpty || confirmPwd.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).inputpassword)));
        return;
      }
      if (account.length < 6 || account.length > 20) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).accounttip)));
        return;
      }
      if (password.length < 6 || password.length > 20) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).passwordtip)));
        return;
      }
      if (password != confirmPwd) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).passworddif)));
        return;
      }
      if (phone.isEmpty || code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).inputphonecode)));
        return;
      }
      if (!RegExp(r'^[1][3-9][0-9]{9}$').hasMatch(phone)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).phonenumwrong)));
        return;
      }
      await register(account, areaCode, phone, password, captchaId,
          code); // 这里的verifyCode可以根据实际情况传入
    } catch (e) {
      LoggerDebugUtil.e('_onRegister', e);
    }
  }

  Future<void> register(String account, String areacode, String phone,
      String password, String captcha, String verifyCode) async {
    try {
      setState(() {
        _loading = true;
      });
      final apiService = ref.read(apiServiceProvider);
      final userInfo = await apiService.registerByPhone(
          account, areacode, phone, captcha, password, verifyCode);
      // todo: 这里调用你的接口，密码md5，生成nonce、hmac‑sha256签名，发起dio请求
      await Future.delayed(const Duration(seconds: 1));
      final apiRes = ApiResponse.fromJson(userInfo);
      if (mounted) {
        if (apiRes.code == 0) {
          _isRegister = false; // 注册成功后切换回登录界面
          TopSnackBar.show(
            context,
            S.of(context).registersuccess,
            backgroundColor: AppColor.info,
            icon: Icons.check_circle,
            duration: Duration(seconds: 2),
          );
        } else {
          TopSnackBar.show(
            context,
            apiRes.message ?? S.of(context).registerfail,
            backgroundColor: AppColor.info,
            icon: Icons.check_circle,
            duration: Duration(seconds: 2),
          );
        }
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  //离线登陆
  Future<void> offlineLoad() async {
    try {
      if (!isAgreeChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).selectagreementTip)));
        return;
      }
      final userNotifier = ref.read(userStateProvider.notifier);
      String account = _accountCtrl.text.trim();
      String password = _passwordCtrl.text.trim();
      if (account.isEmpty && password.isEmpty) {
        account = "user";
        password = "123456";
      }
      userNotifier.login(account, password);
      if (userNotifier.isLoggedIn) {
        GlobalData.DeviceConnectType = 0;
        GlobalData.currentDeviceId = null;
        context.goNamed(AppRouter.home);
      } else {
        return;
      }
    } catch (e) {
      LoggerDebugUtil.e('offlineLoad异常', e);
    }
  }

  // 更新语言
  void updateLanguageCode(String lang) async {
    try {
      Map langRegionMap = {'en': 'US', 'zh': 'CN'};
      await S.load(Locale(lang, langRegionMap[lang]));
      await prefs.saveLang(lang);
      setState(() {
        currentLang = lang;
        GlobalData.language = lang;
        ref.read(localeProvider.notifier).state = Locale(lang);
      });
      print('lang: $lang');
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomBackground(
        child: SafeArea(
            child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                customText(
                  _isRegister
                      ? S.of(context).userregister
                      : S.of(context).userload,
                  style: TextStyles.textStyleTitle,
                  textAlign: TextAlign.center,
                ),
                customText(
                  S.of(context).title,
                  style: TextStyles.textStyleLight14,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                GFCard(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: AppColor.backgroud,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // 账号输入框（登录、注册都需要）
                      // build内组件
                      TextField(
                        controller: _accountCtrl,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: S.of(context).account,
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintStyle: const TextStyle(color: Colors.white60),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Colors.white),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                        ),
                        enabled: !_loading,
                      ),

                      const SizedBox(height: 16),

                      // ========== 注册才显示：手机号 ==========
                      Visibility(
                        visible: _isRegister,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 左侧 可输入区号框
                                SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    controller: _areaCtrl,
                                    keyboardType: TextInputType.number,
                                    enabled: !_loading,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        borderSide:
                                            BorderSide(color: Colors.white70),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    onTap: () {
                                      // 这里可以弹出下拉选择弹窗
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // ========= 你的原有TextField【完全原样，一行不改】=========
                                Expanded(
                                  child: TextField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).phonenum,
                                      labelStyle: const TextStyle(
                                          color: Colors.white60),
                                      hintStyle: const TextStyle(
                                          color: Colors.white60),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                      prefixIcon: const Icon(
                                          Icons.phone_android,
                                          color: Colors.white),
                                      enabledBorder: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        borderSide:
                                            BorderSide(color: Colors.white70),
                                      ),
                                    ),
                                    enabled: !_loading,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            // 验证码行：输入框 + 获取验证码按钮
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codeCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).vercode,
                                      labelStyle:
                                          TextStyle(color: Colors.white60),
                                      hintStyle:
                                          TextStyle(color: Colors.white60),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                      prefixIcon:
                                          Icon(Icons.sms, color: Colors.white),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        borderSide:
                                            BorderSide(color: Colors.white70),
                                      ),
                                    ),
                                    enabled: !_loading,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    // loading 或者倒计时中 按钮不可点击
                                    onPressed:
                                        (_loading || _countDownSeconds > 0)
                                            ? null
                                            : () {
                                                _onGetCode();
                                              },
                                    child: _countDownSeconds > 0
                                        ? customText("${_countDownSeconds}s",
                                            style: TextStyles.textStyle14)
                                        : customText(S.of(context).getvercode,
                                            style: TextStyles.textStyle14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // 密码输入框（登录、注册都需要）
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePwd,
                        decoration: InputDecoration(
                          labelText: S.of(context).password,
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintStyle: const TextStyle(color: Colors.white60),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePwd
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePwd = !_obscurePwd;
                              });
                            },
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                        ),
                        enabled: !_loading,
                      ),

                      const SizedBox(height: 16),

                      // ========== 注册才显示：确认密码 ==========
                      Visibility(
                        visible: _isRegister,
                        child: Column(
                          children: [
                            TextField(
                              controller: _confirmPwdCtrl,
                              obscureText: _obscurePwd,
                              decoration: InputDecoration(
                                labelText: S.of(context).confirmpassword,
                                labelStyle:
                                    const TextStyle(color: Colors.white60),
                                hintStyle:
                                    const TextStyle(color: Colors.white60),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.white),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePwd
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePwd = !_obscurePwd;
                                    });
                                  },
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // 登录/注册按钮
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                          ).copyWith(
                            overlayColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.blue.shade800;
                              }
                              return null;
                            }),
                          ),
                          onPressed: _loading
                              ? null
                              : (_isRegister ? _onRegister : _onLogin),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: AppColor.white)
                              : customText(
                                  _isRegister
                                      ? S.of(context).userregister
                                      : S.of(context).login,
                                  style: TextStyles.textStyle16,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: isAgreeChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  isAgreeChecked = value ?? false;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                style: TextStyles.textStyle14
                                    .copyWith(color: Colors.grey),
                                children: [
                                  TextSpan(
                                      text:
                                          S.of(context).loginUseragreementTip),
                                  TextSpan(
                                    text: "《${S.of(context).useragreement}》",
                                    style: const TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(Uri.parse(
                                            "https://lvxingzhe3.github.io/sinota-esbms/user-agreement.html"));
                                      },
                                  ),
                                  TextSpan(
                                    text: "《${S.of(context).agreement}》",
                                    style: const TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(Uri.parse(
                                            "https://lvxingzhe3.github.io/sinota-esbms/privacy.html"));
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              offlineLoad();
                            },
                            child: Text(
                              S.of(context).offlineload,
                              style: TextStyle(
                                  color: Colors.lightBlueAccent, fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegister = !_isRegister;
                                // 切换时清空输入框
                                _accountCtrl.clear();
                                _passwordCtrl.clear();
                                _phoneCtrl.clear();
                                _codeCtrl.clear();
                                _confirmPwdCtrl.clear();
                              });
                            },
                            child: Text(
                              _isRegister
                                  ? S.of(context).logintip
                                  : S.of(context).registertip,
                              style: const TextStyle(
                                  color: Colors.lightBlueAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 悬浮固定在屏幕右下角，不参与滚动
          Positioned(
            right: 12,
            top: 12,
            // 删掉 Align！不要包Align
            child: DecoratedBox(
              decoration: BoxDecoration(),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  if (currentLang == null) {
                    currentLang = await prefs.getLang();
                  }
                  if (!mounted) return;
                  setState(() {});
                  showModalBottomSheet(
                    backgroundColor: AppColor.backgroud,
                    context: context,
                    isDismissible: true,
                    builder: (BuildContext context) {
                      return Container(
                        height: 120,
                        margin:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // ✅关键！Row包裹自身内容，不要无限撑开
                    children: [
                      Icon(
                        IconFont.language,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      customText(S.of(context).langSwitch,
                          style: TextStyles.textStyle14),
                      const SizedBox(width: 4),
                      customIcon(
                        context,
                        icon: Icons.keyboard_arrow_down,
                        size: 24,
                        isTwitterIcon: false,
                        iconColor: AppColor.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ])),
      ),
    );
  }
}
