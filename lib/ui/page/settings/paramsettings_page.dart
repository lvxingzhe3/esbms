import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:go_router/go_router.dart';
import 'package:bms_app/state/user_state.dart';

class ParamSettingsPage extends ConsumerStatefulWidget {
  const ParamSettingsPage({Key? key}) : super(key: key);

  @override
  _ParamSettingsPageState createState() => _ParamSettingsPageState();
}

// 主页面
class _ParamSettingsPageState extends ConsumerState<ParamSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userState=ref.watch(userStateProvider);
    final roleNumm=userState.role;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(S.of(context).paramsettings,
            color: AppColor.primary),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 16),
        children: [
              GFCard(
                color: AppColor.backgroud,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      GestureDetector(//基础设置
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
                                customText(S.of(context).basicsettings,
                                    style: TextStyles.textStyle14),
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
          
                      Visibility(//系统设置
                        visible: roleNumm>0&&roleNumm<=2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                          context.pushNamed(AppRouter.systemparams);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: AppColor.darkGrey))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  customText(S.of(context).systemparam,
                                      style: TextStyles.textStyle14),
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
                      Visibility(//保护参数
                        visible: roleNumm>0&&roleNumm<=2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                          context.pushNamed(AppRouter.protectparams);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: AppColor.darkGrey))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  customText(S.of(context).protectparam,
                                      style: TextStyles.textStyle14),
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
                      Visibility(//警告参数
                        visible: roleNumm>0&&roleNumm<=2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                          context.pushNamed(AppRouter.warnparams);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: AppColor.darkGrey))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  customText(S.of(context).warnparam,
                                      style: TextStyles.textStyle14),
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
                      Visibility(//功能参数
                        visible: roleNumm>0&&roleNumm<=2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                          context.pushNamed(AppRouter.funcparams);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: AppColor.darkGrey))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  customText(S.of(context).funcparam,
                                      style: TextStyles.textStyle14),
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
                )
              ),
        ],
      )
    );
  }

}
