import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/providers/locale_provider.dart';
import 'package:bms_app/state/app_state.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/bottomMenuBar/tabItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/customWidgets.dart';

class HomeTabWidget extends ConsumerWidget {
  const HomeTabWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(app_stateProvider);
    ref.watch(localeProvider);
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarTheme.color,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, offset: Offset(0, -.1), blurRadius: 0),
        ],
        
      ),
      
      child: CustomBackground(child:  Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _icon(context, ref, null, 0,
              isCustomIcon: true,
              icon: pageIndex == 0 ? IconFont.batminitor : IconFont.batminitor2,
              size: pageIndex == 0 ? 24 : 24,
              text:S.of(context).batminitor,),
              
          _icon(context, ref, null, 1,
              isCustomIcon: true,
              icon: pageIndex == 1 ? AppIcon.cog : AppIcon.cog_outline,
              size: pageIndex == 1 ? 26 : 24,
              text:S.of(context).settings,),
          _icon(context, ref, null, 2,
              isCustomIcon: true,
              icon: pageIndex == 2 ? AppIcon.person : AppIcon.person_outline,
              size: 32,
              text:S.of(context).userPage,),
        ],
      ),)
    );
  }

  Widget _icon(
    BuildContext context,
    WidgetRef ref,
    IconData? iconData,
    int index, {
    bool isCustomIcon = false,
    IconData? icon,
    String ? text,
    double? size,
  }) {
    if (isCustomIcon) {
      assert(icon != null);
    } else {
      assert(iconData != null);
    }

    final current = ref.read(app_stateProvider);

    return Expanded(
      child: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: ANIM_DURATION),
          curve: Curves.easeIn,
          alignment: const Alignment(0, ICON_ON),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: ANIM_DURATION),
            opacity: ALPHA_ON,
            child:  InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                ref.read(app_stateProvider.notifier).setPageIndex = index;
              },
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                        isCustomIcon
                        ? customIcon(
                            context,
                            icon: icon!,
                            size: size ?? 22,
                            isTwitterIcon: true,
                            isEnable: index == current,
                          )
                        : Icon(
                            iconData,
                            color: index == current
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).textTheme.bodySmall!.color,
                          ),
                      //const SizedBox(height: 1), // 自由调整间距
                      customText(text,style: TextStyles.textStyle14),
                ],
              )
            ),
          ),
        ),
      ),
    );
  }
}
