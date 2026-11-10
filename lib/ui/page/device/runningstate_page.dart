import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/model/batpackinfo.dart';
import 'package:bms_app/model/paramitem.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:bms_app/widgets/verticalbattery.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RunningStatePage extends ConsumerStatefulWidget {
  //const RunningStatePage({Key? key}) : super(key: key);
  @override
  _RunningStatePageState createState() => _RunningStatePageState();
}

class _RunningStatePageState extends ConsumerState<RunningStatePage> {
  bool _isLoaded = false;
  late List<ParamItem> _basicParams;
  late List<ParamItem> _bmsstateParams;
  double soc = 0;
  late ParamItem batstate;
  late ParamItem remainchargetime;
  late ParamItem remaindischargetime;
  //加载中
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      readParams();
    }
  }

  Future<void> initPage() async {
    _basicParams = [
      ParamItem(
          key: "voltage",
          name: S.of(context).totalVol,
          value: ref.watch(bleStateProvider
                  .select((s) => s.batpackinfo.voltage.toString())) +
              "V",
          unit: ""),
      ParamItem(
          key: "current",
          name: S.of(context).cur,
          value: ref.watch(bleStateProvider
                  .select((s) => s.batpackinfo.current.toString())) +
              "mA",
          unit: ""),
      ParamItem(
          key: "temperature",
          name: S.of(context).maxTemp,
          value: ref.watch(bleStateProvider
                  .select((s) => s.batpackinfo.max_temperature.toString())) +
              "°C",
          unit: ""),
    ];
  }

  //读取参数
  Future<void> readParams() async {
    try {
      setState(() {
        _isLoading = true;
        batstate = ParamItem(key: '', name: '', value: '', unit: '');
        _basicParams = [];
        _bmsstateParams = [];
        remainchargetime = ParamItem(key: '', name: '', value: '--', unit: '');
        remaindischargetime =
            ParamItem(key: '', name: '', value: '--', unit: '');
      });
      final apiService = ref.read(apiServiceProvider);
      final paramgrouprec =
          await apiService.getstatuslistgroup(GlobalData.currentDeviceId!);
      final apiparamgroupRes = ApiResponse.fromJson(paramgrouprec);
      final List<dynamic> groups =
          apiparamgroupRes.data["attributesGroups"] ?? [];
      final targetgroup = groups.firstWhere(
          (group) => group['key'] == 'battery_health_state',
          orElse: () => null);

      final attributes = targetgroup["attributes"] ?? [];
      final List<Map<String, String>> groupparams =
          attributes.map<Map<String, String>>((attr) {
        return {
          'key': attr['key']?.toString() ?? '',
          'name': attr['name']?.toString() ?? '',
        };
      }).toList();

      final stategroup = groups.firstWhere(
          (group) => group['key'] == 'battery_general_state',
          orElse: () => null);

      final stateAttributes = stategroup["attributes"] ?? [];
      final List<Map<String, String>> stateGroupParams =
          stateAttributes.map<Map<String, String>>((attr) {
        return {
          'key': attr['key']?.toString() ?? '',
          'name': attr['name']?.toString() ?? '',
        };
      }).toList();

      final rec =
          await apiService.getdeviceBmsInfo(GlobalData.currentDeviceId!);
      final apiRes = ApiResponse.fromJson(rec);
      final devjson = apiRes.data['fields'];

      setState(() {
        var keyjson = BatPackbmsinfo.fromJson(devjson["battery_state"]);
        batstate = ParamItem(
            key: keyjson.nameDispaly,
            name: keyjson.nameDispaly,
            value: keyjson.valueDisplay,
            unit: keyjson.unit);

        keyjson = BatPackbmsinfo.fromJson(devjson["battery_charge_state"]);
        soc = keyjson.value;

        remaindischargetime = ParamItem(
            key: keyjson.nameDispaly,
            name: keyjson.nameDispaly,
            value: keyjson.valueDisplay,
            unit: keyjson.unit);

        keyjson = BatPackbmsinfo.fromJson(
            devjson["battery_remaining_discharge_time"]);
        remaindischargetime = ParamItem(
            key: keyjson.nameDispaly,
            name: keyjson.nameDispaly,
            value: keyjson.valueDisplay,
            unit: keyjson.unit);
        keyjson =
            BatPackbmsinfo.fromJson(devjson["battery_remaining_charge_time"]);
        remainchargetime = ParamItem(
            key: keyjson.nameDispaly,
            name: keyjson.nameDispaly,
            value: keyjson.valueDisplay,
            unit: keyjson.unit);

        groupparams.forEach((param) {
          final key = param['key'];
          if (devjson.containsKey(key)) {
            dynamic paramvalue = devjson[key];
            var bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            _basicParams.add(ParamItem(
              key: key!,
              name: param['name'] ?? '',
              value: bmsinfo.valueDisplay ?? '',
              unit: bmsinfo.unit ?? '',
            ));
          }
        });

        stateGroupParams.forEach((param) {
          final key = param['key'];
          if (devjson.containsKey(key)) {
            dynamic paramvalue = devjson[key];
            var bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            _bmsstateParams.add(ParamItem(
              key: key!,
              name: param['name'] ?? '',
              value: bmsinfo.valueDisplay ?? '',
              unit: bmsinfo.unit ?? '',
            ));
          }
        });
        _isLoaded = true;
      });
    } catch (e) {
      print("readParams->$e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final batpackinfo =
        ref.watch(bleStateProvider.select((s) => s.batpackinfo));
    final isConnect = batpackinfo.isConnected;
    return Scaffold(
        appBar: CustomAppBar(
          isBackButton: true,
          title:
              customTitleText(S.of(context).runstate, color: AppColor.primary),
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              // 下拉触发，执行刷新逻辑：重新读取蓝牙数据 / 请求网络
              if (isConnect) {
                await readParams();
              }
            },
            child: Visibility(
                visible: isConnect,
                child: ListView(
                  padding: EdgeInsets.only(bottom: 16),
                  children: <Widget>[
                    Column(children: [
                      //wifi
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 1,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
                          content: Row(
                            children: [
                              VerticalBatteryWidget(
                                soc: soc,
                                width: 90,
                                height: 160,
                                state: batstate.value,
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                  child: Column(
                                children: [
                                  Wrap(
                                    spacing: 10, // 横向元素间距，替代SizedBox(width:10)
                                    runSpacing: 4, // 换行后两行之间的垂直距离，按需调整
                                    crossAxisAlignment: WrapCrossAlignment
                                        .center, // 垂直居中，和Row默认效果一致
                                    children: [
                                      Text(
                                        remaindischargetime.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        remaindischargetime.value,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                      Text(
                                        remaindischargetime.unit,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  Wrap(
                                    spacing: 10, // 横向元素间距，替代SizedBox(width:10)
                                    runSpacing: 4, // 换行后两行之间的垂直距离，按需调整
                                    crossAxisAlignment: WrapCrossAlignment
                                        .center, // 垂直居中，和Row默认效果一致
                                    children: [
                                      Text(
                                        remainchargetime.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(remainchargetime.value,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColor.primary)),
                                      Text(remainchargetime.unit,
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ],
                              )),
                              /*
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(remaindischargetime.name,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    remaindischargetime.value,
                                    style: const TextStyle(
                                        fontSize: 14, color: AppColor.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  child: Text(remaindischargetime.unit,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(remainchargetime.name,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    remainchargetime.value,
                                    style: const TextStyle(
                                        fontSize: 14, color: AppColor.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  child: Text(remainchargetime.unit,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        )
                        */
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 1,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
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
                                    SizedBox(width: 8),
                                    customText(S.of(context).batpackinfo,
                                        style: TextStyles.textStyle16),
                                  ]),
                              const SizedBox(width: 8),
                              SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _basicParams.length,
                                itemBuilder: (context, index) {
                                  final param = _basicParams[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[600]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Column(children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(param.name,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                param.value,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColor.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 40,
                                              child: Text(param.unit,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  textAlign: TextAlign.center),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 1,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
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
                                    SizedBox(width: 8),
                                    customText(S.of(context).runstate,
                                        style: TextStyles.textStyle16),
                                  ]),
                              const SizedBox(width: 8),
                              SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _bmsstateParams.length,
                                itemBuilder: (context, index) {
                                  final param = _bmsstateParams[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[600]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Column(children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(param.name,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                param.value,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColor.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 40,
                                              child: Text(param.unit,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  textAlign: TextAlign.center),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      //bluetooth
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 0,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
                          content: Column(
                            children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconFont.socparam,
                                      color: AppColor.primary,
                                      size: 30,
                                    ),
                                    SizedBox(width: 8),
                                    customText(S.of(context).capacityinfo,
                                        style: TextStyles.textStyle16),
                                  ]),
                              SizedBox(height: 16),
                              Row(children: [
                                customText(S.of(context).totalBattery,
                                    style: TextStyles.textStyle14),
                                SizedBox(width: 8),
                                customText("${batpackinfo.totalcapaciry}Ah",
                                    style: TextStyles.textStyleVlue),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                customText(S.of(context).remainBattery,
                                    style: TextStyles.textStyle14),
                                SizedBox(width: 8),
                                customText("${batpackinfo.remaincap}Ah",
                                    style: TextStyles.textStyleVlue),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cycleCount,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(batpackinfo.cycle.toString(),
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText("SOC",
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 4),
                                        customText("${batpackinfo.soc}%",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 8),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText("SOH",
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText("${batpackinfo.soh}%",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 0,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
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
                                    SizedBox(width: 8),
                                    customText(S.of(context).batpackinfo,
                                        style: TextStyles.textStyle16),
                                  ]),
                              SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).totalVol,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText("${batpackinfo.voltage}V",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).collectvol,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText("${batpackinfo.collectvol}V",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).loadvol,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText("${batpackinfo.loadvol}V",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cur,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText("${batpackinfo.current}mA",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 0,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
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
                                    SizedBox(width: 8),
                                    customText(S.of(context).batinfo,
                                        style: TextStyles.textStyle16),
                                  ]),
                              SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cellMaxVal,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${batpackinfo.max_voltage}mV",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cellMinVal,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${batpackinfo.min_voltage}mV",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).maxTemp,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${batpackinfo.max_temperature}°C",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).minTemp,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${batpackinfo.min_temperature}°C",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cellVoltdiff,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${(batpackinfo.max_voltage - batpackinfo.min_voltage).toStringAsFixed(1)}mV",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                                SizedBox(width: 4),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        customText(S.of(context).cellTempdiff,
                                            style: TextStyles.textStyle14),
                                        SizedBox(width: 8),
                                        customText(
                                            "${(batpackinfo.max_temperature - batpackinfo.min_temperature).toStringAsFixed(1)}°C",
                                            style: TextStyles.textStyleVlue),
                                      ],
                                    )),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: GlobalData.DeviceConnectType == 0,
                        child: GFCard(
                          color: AppColor.backgroud,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.fromLTRB(10, 16, 10, 0),
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
                                    SizedBox(width: 8),
                                    customText(S.of(context).bmsstateinfo,
                                        style: TextStyles.textStyle16),
                                  ]),
                              SizedBox(height: 16),
                              Row(children: [
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: AppColor.normal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        customText(S.of(context).chargeMOS,
                                            style: TextStyles.textStyle14),
                                      ],
                                    )),
                                Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: AppColor.normal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        customText(S.of(context).dischargeMOS,
                                            style: TextStyles.textStyle14),
                                      ],
                                    )),
                              ]),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ],
                ))));
  }
}
