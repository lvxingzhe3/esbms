import 'package:bms_app/ui/page/device/add_device.dart';
import 'package:bms_app/ui/page/device/alarm_page.dart';
import 'package:bms_app/ui/page/device/runningstate_page.dart';
import 'package:bms_app/ui/page/settings/socparams_page.dart';
import 'package:bms_app/ui/page/settings/warnparams_page.dart';
import 'package:bms_app/ui/page/settings/warnprotparams_page.dart';
import 'package:bms_app/ui/page/user/accountsecurity.dart';
import 'package:bms_app/ui/page/user/faq.dart';
import 'package:bms_app/ui/page/user/otaupgrade.dart';
import 'package:bms_app/ui/page/user/user_load.dart';
import 'package:bms_app/ui/page/wifi/page_wconfig_find.dart';
import 'package:bms_app/ui/page/wifi/page_wifi_config.dart';
import 'package:bms_app/ui/page/wifi/wificonfig_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// 页面导入
import 'package:bms_app/ui/page/home/home_page.dart';
import 'package:bms_app/ui/page/splash/splash_page.dart';

import 'package:bms_app/ui/page/device/bluetooth_page.dart';
import 'package:bms_app/ui/page/device/battery_cell_page.dart';
import 'package:bms_app/ui/page/device/firmware_page.dart';
import 'package:bms_app/ui/page/device/map_page.dart';
import 'package:bms_app/ui/page/settings/paramsettings_page.dart';
import 'package:bms_app/ui/page/settings/basicsettings_page.dart';
import 'package:bms_app/ui/page/settings/systemparams_page.dart';
import 'package:bms_app/ui/page/settings/protectparams_page.dart';
import 'package:bms_app/ui/page/settings/funcparams_page.dart';

import 'package:bms_app/ui/page/user/privacy_page.dart';
import 'package:bms_app/widgets/customWidgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // 必须导入

class AppRouter {
  // 路由名称常量
  static const String login = 'login';
  static const String splash = 'splash';
  static const String home = 'home';
  static const String firmware = 'firmware';
  static const String bluetooth = 'bluetooth';
  static const String batteryCell = 'batteryCell';
  static const String map = 'map';
  static const String privacy = 'privacy';
  static const String manufacturePage = 'manufacturePage';
  static const String paramsettings = "paramsettings";
  static const String basicsettings = "basicsettings";
  static const String systemparams = "systemparams";
  static const String socparams = "socparams";
  static const String protectparams = "protectparams";
  static const String funcparams = "funcparams";
  static const String warnparams = "warnparams";
  static const String runningstate = "runningstate";
  static const String alarminfo = "alarminfo";
  static const String otaupgrade = "otaupgrade";
  static const String warnprotparams = "warnprotparams";
  static const String adddev = "adddev";
  static const String wificonfig = "wificonfig";
  static const String wificonfigfind = "wificonfigfind";
  static const String devwificonfig = "devwificonfig";
  static const String accountsecurity = "accountsecurity";
  static const String faqpage = "faqpage";
  //PageWConfigFind
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        name: login,
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const LoginPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/home',
        name: home,
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const HomePage(),
          state,
        ),
        routes: [
          // 嵌套路由示例
          GoRoute(
            path: 'adddev',
            name: adddev,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: AddDevicePage()),
              state,
            ),
          ),
          GoRoute(
            path: 'firmware',
            name: firmware,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              //const FirmwarePage(),
              FirmwarePage(),
              state,
            ),
          ),
          GoRoute(
            path: 'bluetooth',
            name: bluetooth,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              const BluetoothPage(),
              state,
            ),
          ),
          /*
          GoRoute(
            path: 'battery-cell',
            name: batteryCell,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              const BatteryCellPage(),
              state,
            ),
          ),
          */
          GoRoute(
            path: 'map',
            name: map,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: MapPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'paramsettings',
            name: paramsettings,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: ParamSettingsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'basicsettings',
            name: basicsettings,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: BasicSettingsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'systemparams',
            name: systemparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: SystemParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'socparams',
            name: socparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: SocParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'protectparams',
            name: protectparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: ProtectParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'warnparams',
            name: warnparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: WarnParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'warnprotparams',
            name: warnprotparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: WarnProtectParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: 'funcparams',
            name: funcparams,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              ProviderScope(child: FuncParamsPage()),
              state,
            ),
          ),
          GoRoute(
            path: '/runningstate',
            name: runningstate,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              RunningStatePage(),
              state,
            ),
          ),
          GoRoute(
            path: 'alarminfo',
            name: alarminfo,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              AlarmInfoPage(),
              state,
            ),
          ),
          GoRoute(
            path: 'otaupgrade',
            name: otaupgrade,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              OtaUpgradPage(),
              state,
            ),
          ),
          GoRoute(
            path: 'wificonfig',
            name: wificonfig,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              WifiConfigPage(),
              state,
            ),
          ),
          GoRoute(
            path: 'wificonfigfind',
            name: wificonfigfind,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              PageWConfigFind(),
              state,
            ),
          ),
          GoRoute(
            path: 'accountsecurity',
            name: accountsecurity,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              AccountSecurity(),
              state,
            ),
          ),
          GoRoute(
            path: 'faqpage',
            name: faqpage,
            pageBuilder: (context, state) => _buildPageWithAnimation(
              FaqPage(),
              state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/privacy',
        name: privacy,
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const PrivacyPage(),
          state,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: customTitleText(
          state.uri.toString().split('/').last,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('页面未找到'),
            const SizedBox(height: 16),
            Text('路径: ${state.uri.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );

  // 构建带自定义动画的页面
  static CustomTransitionPage _buildPageWithAnimation(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
