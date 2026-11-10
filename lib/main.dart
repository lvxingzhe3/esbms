import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'generated/l10n.dart';
import 'global.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String userLanguage = await _getUserLanguage();
  GlobalData.LoadtIime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  //HttpOverrides.global = MyHttpOverrides();
  runApp(ProviderScope(child: MyApp(language: userLanguage)));
}

Future<String> _getUserLanguage() async {
  final String? cachedLang = await SharedPreferenceHelper().getLang();
  return cachedLang ?? 'zh';
}

class MyApp extends StatelessWidget {
  final String language;

  const MyApp({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '昔诺达 esBMS',
      onGenerateTitle: (context) => S.of(context).title,
      theme: _buildAppTheme(context),
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback: _localeResolutionCallback,
      locale: Locale(language),
    );
  }

  // 提取主题构建逻辑
  ThemeData _buildAppTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.mulishTextTheme(
      Theme.of(context).textTheme,
    );
    // 覆盖全部文字颜色为白色，适配深色渐变背景
    final whiteTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: Colors.white),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: Colors.white),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: Colors.white),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: Colors.white),
      headlineMedium:
          baseTextTheme.headlineMedium?.copyWith(color: Colors.white),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: Colors.white),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: Colors.white),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: Colors.white),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: Colors.white70),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: Colors.white),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: Colors.white60),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: Colors.white),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: Colors.white70),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: Colors.white60),
    );
    return AppTheme.appTheme.copyWith(
      textTheme: whiteTextTheme,
      // Scaffold背景设透明，用来承载全局渐变
      scaffoldBackgroundColor: Colors.transparent,
      // AppBar：标题、返回图标全部白色
      appBarTheme: const AppBarTheme(
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
      ),
      // 底部导航栏样式（匹配截图）
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF20E0A0), // 选中绿色
        unselectedItemColor: Colors.white60,
      ),
      // 图标全局白色
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // 常量化 delegates 列表
  static const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // 提取 locale 解析逻辑
  static Locale? _localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale?.languageCode == 'en') {
      return const Locale('en', 'US');
    }
    return locale;
  }
}
