import 'package:bms_app/state/app_state.dart';
import 'package:bms_app/ui/page/home/widgets/home_tab_widget.dart';
import 'package:bms_app/ui/page/profile/profile_page.dart';
import 'package:bms_app/ui/page/settings/settings_page.dart';
import 'package:bms_app/ui/page/user/user_page.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(app_stateProvider);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent, 
      bottomNavigationBar: const HomeTabWidget(),
      body: CustomBackground(
          child: SafeArea(
            child: _getPage(pageIndex),
          ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ProfilePage();
      case 1:
        return SettingsPage();
      case 2:
        return UserPage();
      default:
        return ProfilePage();
    }
  }
}
