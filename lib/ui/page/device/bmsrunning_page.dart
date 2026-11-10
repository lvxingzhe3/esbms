import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BmsRunningStatePage extends ConsumerStatefulWidget {
  const BmsRunningStatePage({super.key});
  @override
  ConsumerState createState() => _BmsRunningStatePageState();
}

class _BmsRunningStatePageState extends ConsumerState<BmsRunningStatePage> {
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

  Map<int, String> getBmsStateBitDesc(BuildContext context) {
    return {
      0: S.of(context).invertercom,
      1: S.of(context).hostcom,
      2: S.of(context).mergecom,
      3: S.of(context).forbidcharge,
      4: S.of(context).forbiddischarge,
      5: S.of(context).forcechargeenable,
      6: S.of(context).fullcharge,
      7: S.of(context).predischarge,
      8: S.of(context).chargeraccess,
      9: S.of(context).loadaccess,
      10: S.of(context).raiseflag,
      11: S.of(context).release,
      12: S.of(context).uploadflag,
    };
  }

  /// 获取bms状态提示
  List<String> getBmsStateText(int alarmValue, BuildContext context) {
    List<String> result = [];
    final bits = getActiveBits(alarmValue);
    final faultMap = getBmsStateBitDesc(context);
    for (var b in bits) {
      String? desc;
      desc = faultMap[b];
      if (desc != null) {
        result.add(desc);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isConnect = ref.watch(
        bleStateProvider.select((s) => s.batpackinfo?.isConnected ?? false));

    // 不连接时直接返回空，不渲染滚动组件
    if (!isConnect) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ===== Wifi 电池包信息卡片 =====
          if (GlobalData.DeviceConnectType == 1)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final basicParams = ref.watch(bleStateProvider
                    .select((s) => s.batpackinfo?.basicParams ?? []));
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(IconFont.batpack,
                              color: AppColor.primary, size: 30),
                          const SizedBox(width: 8),
                          customText(S.of(context).batpackinfo,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: List.generate(basicParams.length, (index) {
                          final param = basicParams[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[600]!, width: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: Text(param.name,
                                              style: const TextStyle(
                                                  fontSize: 14))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(param.value,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColor.primary))),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 40,
                                        child: Text(param.unit,
                                            style:
                                                const TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                );
              }),
            ),

          // ===== Wifi 运行状态卡片 =====
          if (GlobalData.DeviceConnectType == 1)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final bmsstateParams = ref.watch(bleStateProvider
                    .select((s) => s.batpackinfo?.bmsstateParams ?? []));
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(IconFont.runstate,
                              color: AppColor.primary, size: 30),
                          const SizedBox(width: 8),
                          customText(S.of(context).runstate,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: List.generate(bmsstateParams.length, (index) {
                          final param = bmsstateParams[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[600]!, width: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: Text(param.name,
                                              style: const TextStyle(
                                                  fontSize: 14))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(param.value,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColor.primary))),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 40,
                                        child: Text(param.unit,
                                            style:
                                                const TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                );
              }),
            ),

          // ===== Wifi Bms状态卡片 =====
          if (GlobalData.DeviceConnectType == 1)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final bmsstate = ref.watch(
                    bleStateProvider.select((s) => s.batpackinfo.bms_state));
                List<String> bmsStates = getBmsStateText(bmsstate, context);
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  // 改用 shrinkWrap ListView，避免Column溢出
                  content: bmsStates.isNotEmpty
                      ? Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(IconFont.state,
                                    color: AppColor.primary, size: 30),
                                const SizedBox(width: 8),
                                customText(S.of(context).bmsstateinfo,
                                    style: TextStyles.textStyle16),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: bmsStates
                                  .map((model) => Column(
                                        children: [
                                          Text(model),
                                          SizedBox(height: 8)
                                        ],
                                      ))
                                  .toList(),
                            )
                          ],
                        )
                      : SizedBox.shrink(),
                );
              }),
            ),

          // ========== 蓝牙卡片 ==========
          if (GlobalData.DeviceConnectType == 0)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final pack = ref.watch(bleStateProvider.select((s) {
                  final info = s.batpackinfo;
                  return (
                    totalcapaciry: info?.totalcapaciry ?? 0,
                    remaincap: info?.remaincap ?? 0,
                    cycle: info?.cycle ?? 0,
                    soc: info?.soc ?? 0,
                    soh: info?.soh ?? 0,
                  );
                }));
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(IconFont.socparam,
                              color: AppColor.primary, size: 30),
                          const SizedBox(width: 8),
                          customText(S.of(context).capacityinfo,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        customText(S.of(context).totalBattery,
                            style: TextStyles.textStyle14),
                        const SizedBox(width: 8),
                        customText("${pack.totalcapaciry}mAh",
                            style: TextStyles.textStyleVlue),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        customText(S.of(context).remainBattery,
                            style: TextStyles.textStyle14),
                        const SizedBox(width: 8),
                        customText("${pack.remaincap}mAh",
                            style: TextStyles.textStyleVlue),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cycleCount,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText(pack.cycle.toString(),
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText("SOC", style: TextStyles.textStyle14),
                              const SizedBox(width: 4),
                              customText("${pack.soc}%",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText("SOH", style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${pack.soh}%",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
            ),

          // ========== 电压电流卡片 ==========
          if (GlobalData.DeviceConnectType == 0)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final data = ref.watch(bleStateProvider.select((s) {
                  final info = s.batpackinfo;
                  return (
                    voltage: info?.voltage ?? 0,
                    collectvol: info?.collectvol ?? 0,
                    loadvol: info?.loadvol ?? 0,
                    current: info?.current ?? 0,
                  );
                }));
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            IconFont.batpack,
                            color: AppColor.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          customText(S.of(context).batpackinfo,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).totalVol,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.voltage}V",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).collectvol,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.collectvol}V",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).loadvol,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.loadvol}V",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cur,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.current}mA",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
            ),

          // ========== 单体电压温度卡片 ==========
          if (GlobalData.DeviceConnectType == 0)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final data = ref.watch(bleStateProvider.select((s) {
                  final info = s.batpackinfo;
                  return (
                    max_voltage: info?.max_voltage ?? 0,
                    min_voltage: info?.min_voltage ?? 0,
                    max_temperature: info?.max_temperature ?? 0,
                    min_temperature: info?.min_temperature ?? 0,
                  );
                }));
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            IconFont.batcell,
                            color: AppColor.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          customText(S.of(context).batinfo,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cellMaxVal,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.max_voltage}mV",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cellMinVal,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.min_voltage}mV",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).maxTemp,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.max_temperature}°C",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).minTemp,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText("${data.min_temperature}°C",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cellVoltdiff,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText(
                                  "${(data.max_voltage - data.min_voltage).toStringAsFixed(1)}mV",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(S.of(context).cellTempdiff,
                                  style: TextStyles.textStyle14),
                              const SizedBox(width: 8),
                              customText(
                                  "${(data.max_temperature - data.min_temperature).toStringAsFixed(1)}°C",
                                  style: TextStyles.textStyleVlue),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
            ),

          // ========== BMS MOS状态卡片 ==========
          if (GlobalData.DeviceConnectType == 0)
            RepaintBoundary(
              child: Consumer(builder: (context, ref, child) {
                final data = ref.watch(bleStateProvider.select((s) {
                  final info = s.batpackinfo;
                  return (
                    chargeMOS: info?.chargeMOS ?? false,
                    dischargeMOS: info?.dischargeMOS ?? false,
                  );
                }));
                Color chargeColor =
                    data.chargeMOS ? AppColor.normal : Colors.grey;
                Color dischargeColor =
                    data.dischargeMOS ? AppColor.normal : Colors.grey;
                return GFCard(
                  color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  content: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            IconFont.state,
                            color: AppColor.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          customText(S.of(context).bmsstateinfo,
                              style: TextStyles.textStyle16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: chargeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              customText(S.of(context).chargeMOS,
                                  style: TextStyles.textStyle14),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: dischargeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              customText(S.of(context).dischargeMOS,
                                  style: TextStyles.textStyle14),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
