import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';

import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState(); // 必须首先调用 super.initState()
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStateProvider);
    final roleNumm = userState.role;
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: customTitleText(S.of(context).settingPage),
          centerTitle: true,
          backgroundColor: Colors.transparent, // AppBar 透明
          elevation: 0, // 移除底部阴影，否则会有灰色分层
        ),
        body: CustomBackground(
            child: ListView(
          padding: EdgeInsets.only(bottom: 16),
          children: [
            GFCard(
                color: AppColor.backgroud,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Visibility(
                      //基础设置
                      visible: false,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          context.pushNamed(AppRouter.basicsettings);
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
                                  IconFont.protectparam,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                customText(S.of(context).basicsettings,
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
                    Visibility(
                      //警告保护参数
                      visible: GlobalData.currentDeviceId != null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          context.pushNamed(AppRouter.warnprotparams);
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
                                  IconFont.warnparam,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                customText(S.of(context).warnparam,
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
                    Visibility(
                      //SOC参数
                      visible: GlobalData.currentDeviceId != null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          context.pushNamed(AppRouter.socparams);
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
                                  IconFont.protectparam,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                customText(S.of(context).socparam,
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
                    Visibility(
                      //功能参数
                      visible: GlobalData.currentDeviceId != null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          context.pushNamed(AppRouter.funcparams);
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
                                  IconFont.funcparam,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                customText(S.of(context).funcparam,
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
                    Visibility(
                      //系统设置
                      visible: GlobalData.currentDeviceId != null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async {
                          context.pushNamed(AppRouter.systemparams);
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
                                  IconFont.systemparam,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                customText(S.of(context).systemparam,
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
                )),
          ],
        )));
  }
}
