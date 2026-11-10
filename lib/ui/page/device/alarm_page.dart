import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmInfoPage extends ConsumerStatefulWidget {
  const AlarmInfoPage({super.key});

  @override
  ConsumerState<AlarmInfoPage> createState() => _AlarmInfoPageState();
}

class _AlarmInfoPageState extends ConsumerState<AlarmInfoPage> {
  final List<AlarmItem> _alarmList = [];

  /// 获取uint32所有为1的bit下标
  List<int> getActiveBits(int value) {
    List<int> bits = [];
    // 4字节，0‑31位
    for (int i = 0; i < 32; i++) {
      int mask = 1 << i;
      if ((value & mask) != 0) {
        bits.add(i);
      }
    }
    return bits;
  }

  Map<int, String> getWarnBitDesc(BuildContext context) {
    return {
      0: S.of(context).overcharge,
      1: S.of(context).overdischarge,
      2: S.of(context).allovercharge,
      3: S.of(context).alloverdischarge,
      4: S.of(context).overchargecur,
      5: S.of(context).overchargecur2,
      6: S.of(context).overdischargecur,
      7: S.of(context).overdischargecur2,
      8: S.of(context).chargehightemp,
      9: S.of(context).chargelowtemp,
      10: S.of(context).dischargehightemp,
      11: S.of(context).dischargelowtemp,
      12: S.of(context).evnhightemp,
      13: S.of(context).evnlowtemp,
      14: S.of(context).moshightemp,
      15: S.of(context).soclow,
      16: S.of(context).sochigh,
      17: S.of(context).sohlow,
      18: S.of(context).chargevoldif,
      19: S.of(context).dischargevoldif,
      20: S.of(context).chargetempdif,
      21: S.of(context).dischargetempdif,
      22: S.of(context).temprise,
    };
  }

  Map<int, String> getFaultBitDesc(BuildContext context) {
    return {
      0: S.of(context).bordshort,
      1: S.of(context).reverse,
      2: S.of(context).batabnormal,
      3: S.of(context).currentabnormal,
      4: S.of(context).ntcabnormal,
      5: S.of(context).afeabnormal,
      6: S.of(context).chargemosabnormal,
      7: S.of(context).dischargemosabnormal,
      8: S.of(context).chargelimitcurabnormal,
      9: S.of(context).predischargeabnormal,
      10: S.of(context).fanabnormal,
      11: S.of(context).riseabnormal,
      12: S.of(context).systemabnormal,
      13: S.of(context).hardwareabnormal,
    };
  }

  /// 获取告警提示
  List<String> getAlarmText(int alarmValue, int type, BuildContext context) {
    List<String> result = [];
    final bits = getActiveBits(alarmValue);
    final warnMap = getWarnBitDesc(context);
    final faultMap = getFaultBitDesc(context);
    for (var b in bits) {
      String? desc;
      if (type == 2) {
        desc = faultMap[b];
      } else {
        desc = warnMap[b];
      }
      if (desc != null) {
        result.add(desc);
      } else {
        result.add("bit$b");
      }
    }
    return result;
  }

  /// 解析告警数据
  void parseAlarmData(int ababnormal, int alarm, int protect) {
    List<String> abnormals = [];
    List<String> alarms = [];
    List<String> protects = [];

    if (ababnormal > 0) {
      abnormals = getAlarmText(ababnormal, 2, context);
    }
    if (alarm > 0) {
      alarms = getAlarmText(alarm, 1, context);
    }
    if (protect > 0) {
      protects = getAlarmText(protect, 1, context);
    }

    // 重置列表，防止重复追加
    _alarmList.clear();
    for (var item in abnormals) {
      _alarmList.add(
          AlarmItem(key: "", name: "", info: item, level: 2, createdtime: ''));
    }
    for (var item in alarms) {
      _alarmList.add(
          AlarmItem(key: "", name: "", info: item, level: 1, createdtime: ''));
    }
    for (var item in protects) {
      _alarmList.add(
          AlarmItem(key: "", name: "", info: item, level: 0, createdtime: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听蓝牙bms数据
    final batpackinfo =
        ref.watch(bleStateProvider.select((s) => s.batpackinfo));
    // 当bms告警字段变化时，解析数据
    parseAlarmData(batpackinfo.bms_abnormal, batpackinfo.bms_alarm,
        batpackinfo.bms_protect);
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Stack(
        children: [
          GFCard(
              color: AppColor.backgroud,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
              //padding: EdgeInsets.zero, // 清除GFCard内部content的边距
              clipBehavior: Clip.hardEdge,
              content: _alarmList.isNotEmpty
                  ? ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _alarmList
                          .map((model) => CellItem(model: model))
                          .toList(),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(S.of(context).noalarm),
                    )),
          _alarmList.isNotEmpty
              ? const Positioned(
                  top: 18, // 距离卡片顶部
                  left: 25, // 距离卡片左侧
                  child: Icon(
                    IconFont.warninfo,
                    size: 15,
                    color: Colors.orange,
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}

class CellItem extends StatelessWidget {
  final dynamic model;
  const CellItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0, top: 0),
      child: Flex(
        direction: Axis.horizontal,
        children: <Widget>[
          SizedBox(width: 10),
          if (model.level == 2)
            Icon(
              Icons.priority_high,
              color: Colors.red,
              size: 24,
            )
          else if (model.level == 1)
            Icon(
              Icons.error_outlined,
              color: Colors.orange,
              size: 24,
            )
          else
            Icon(
              Icons.alarm,
              color: Colors.amber,
              size: 24,
            ),
          SizedBox(width: 5),
          customText('${model.info}',
              style: TextStyles.textStyle14, textAlign: TextAlign.left),
          //customText('${model.createdtime}'),
        ],
      ),
    );
  }
}

/// 告警数据模型
class AlarmItem {
  String key;
  String name;
  String info;
  String createdtime;
  int level;

  AlarmItem(
      {required this.key,
      required this.name,
      required this.info,
      required this.createdtime,
      this.level = 0});
}
