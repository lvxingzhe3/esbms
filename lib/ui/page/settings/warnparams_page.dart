import 'dart:async';

import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/model/bmscmd.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/event/ble_event.dart';

class WarnParamsPage extends ConsumerStatefulWidget {
  const WarnParamsPage({Key? key}) : super(key: key);

  @override
  _WarnParamsPageState createState() => _WarnParamsPageState();
}

// 主页面
class _WarnParamsPageState extends ConsumerState<WarnParamsPage> {
  // 参数数据
  late List<ParamItem> _params;
  StreamSubscription? _subscription;
  // 存储每个输入框的控制器
  final Map<int, TextEditingController> _controllers = {};
  @override
  void initState() {
    super.initState();
    // ✅ 订阅蓝牙数据事件
    _subscription = eventBus.on<BleDataEvent>().listen((event) {
      // 在 UI 中更新数据
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //参数列表
    _params = [
      ParamItem(
          name: S.of(context).overcharge,
          value: '0',
          unit: 'mV',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overchargedelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarnDelay),
      ParamItem(
          name: S.of(context).overchargelift,
          value: '0',
          unit: 'mV',
          Cmd: BmsCmd.overChargeWarnLift),
      ParamItem(
          name: S.of(context).overchargeliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarnLiftDelay),
      ParamItem(
          name: S.of(context).overdischarge,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargedelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargelift,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargeliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecur,
          value: '0',
          unit: 'mA',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecurdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).allovercharge,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverchargedelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverchargelift,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverchargeliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverdischarge,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverdischargedelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverdischargelift,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).alloverdischargeliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overchargecur,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overchargecurdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overchargecurlift,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overchargecurliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecur,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecurdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecurlift,
          value: '0',
          unit: 'V',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).overdischargecurliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargehightemp,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargehightempdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargehightemplift,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargehightempliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargelowtemp,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargelowtempdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargelowtemplift,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).dischargelowtempliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargehightemp,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargehightempdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargehightemplift,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargehightempliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargelowtemp,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargelowtempdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargelowtemplift,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).chargelowtempliftdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).moshightemp,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).moshightempdelay,
          value: '0',
          unit: 'ms',
          Cmd: BmsCmd.overChargeWarn),
      ParamItem(
          name: S.of(context).moshightemplift,
          value: '0',
          unit: '℃',
          Cmd: BmsCmd.overChargeWarn),
    ];
    // 初始化控制器
    for (int i = 0; i < _params.length; i++) {
      _controllers[i] = TextEditingController(text: _params[i].value);
    }
    readParams();
  }

  @override
  void dispose() {
    // 释放控制器
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _subscription?.cancel();
    super.dispose();
  }

  ///蓝牙发送并返回
  Future<List<int>?> writeAndRead({
    required List<int> sendBytes,
    int timeoutMs = 500,
  }) async {
    final completer = Completer<List<int>>();
    try {
      final writeChar = ref.read(bleStateProvider).characteristic;
      final recChar = ref.read(bleStateProvider).reccharacteristic;
      if (writeChar == null || recChar == null) return null;
      late StreamSubscription sub;
      sub = recChar.onValueReceived.listen((data) {
        completer.complete(data);
        sub.cancel();
      });
      // 超时
      Future.delayed(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          sub.cancel();
          print('writeAndRead timeout error');
          return null;
        }
      });
      // 下发命令
      await writeChar.write(sendBytes, withoutResponse: true);
    } catch (e) {
      print("writeAndRead->$e");
    }

    return await completer.future;
  }

  final TextEditingController _editController = TextEditingController();
  //设置参数弹框
  Future<void> _onSettingPressed(int index) async {
    final newValue = _controllers[index]?.text ?? '';
    setState(() {
      _params[index].value = newValue;
    });
    _editController.text = newValue;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: Text('${_params[index].name}'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText: 'value',
              hintStyle: TextStyles.textStyleLight,
              //border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: customText(S.of(context).cancel,
                  style: TextStyles.textStyle14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, // 正常背景色
                foregroundColor: Colors.white, // 文字/图标颜色
                elevation: 5, // 阴影高度，数值越大阴影越明显
                shadowColor: AppColor.primary.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newValue = _editController.text.trim();
                if (newValue.isNotEmpty) {
                  sendParamCmd(index, newValue);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No Value')),
                  );
                }
              },
              child: customText(S.of(context).confirm,
                  style: TextStyles.textStyle14),
            ),
          ],
        );
      },
    );
  }

  //读取参数
  Future<void> readParams() async {
    List<int> address = intTo2BytesBigEndian(BmsCmd.overChargeWarn);
    List<int> combCmd = [
      BmsCmd.cmdAddress,
      BmsCmd.readKeep,
      address[0],
      address[1],
      0x00,
      0x04
    ];
    List<int> crcCmd = calculateCRC16(combCmd);
    List<int> cmdOfSetCode = [...combCmd, ...crcCmd];
    List<int>? recvBytes = await writeAndRead(sendBytes: cmdOfSetCode);
    if (recvBytes != null &&
        recvBytes.length >= 5 &&
        recvBytes[0] == BmsCmd.cmdAddress) {
      var rec = recvBytes.skip(3).take(2).toList();
      int recvalue = twoBytesToIntBigEndian(rec);
      _params[0].value = recvalue.toString();

      rec = recvBytes.skip(5).take(2).toList();
      recvalue = twoBytesToIntBigEndian(rec);
      _params[1].value = recvalue.toString();

      rec = recvBytes.skip(7).take(2).toList();
      recvalue = twoBytesToIntBigEndian(rec);
      _params[2].value = recvalue.toString();

      rec = recvBytes.skip(9).take(2).toList();
      recvalue = twoBytesToIntBigEndian(rec);
      _params[3].value = recvalue.toString();
      setState(() {
        _controllers[0]?.text = _params[0].value;
        _controllers[1]?.text = _params[1].value;
        _controllers[2]?.text = _params[2].value;
        _controllers[3]?.text = _params[3].value;
      });
    }
  }

  //修改参数
  Future<void> sendParamCmd(int index, String value) async {
    int cmd = _params[index].Cmd;
    List<int> address = intTo2BytesBigEndian(cmd);
    int intvalue = int.tryParse(value) ?? 0;
    List<int> valuearr = intTo2BytesBigEndian(intvalue);
    List<int> combCmd = [
      BmsCmd.cmdAddress,
      BmsCmd.writeKeep,
      address[0],
      address[1],
      valuearr[0],
      valuearr[1]
    ];
    List<int> crcCmd = calculateCRC16(combCmd);
    List<int> cmdOfSetCode = [...combCmd, ...crcCmd];
    List<int>? recvBytes = await writeAndRead(sendBytes: cmdOfSetCode);
    if (recvBytes != null &&
        recvBytes.length >= 5 &&
        recvBytes[0] == BmsCmd.cmdAddress) {
      _params[index].value = value;
      setState(() {
        _controllers[index]?.text = _params[index].value;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Parameter setting failed!'),
        duration: Duration(seconds: 1), // 持续时间，可根据需要调整
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          isBackButton: true,
          title:
              customTitleText(S.of(context).warnparam, color: AppColor.primary),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                await readParams();
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ========== 顶部标题行 ==========
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color.fromARGB(255, 19, 89, 175),
              child: Row(
                children: [
                  // 参数名
                  Expanded(
                    flex: 2,
                    child: Text(
                      S.of(context).paramname,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // 参数值
                  Expanded(
                    flex: 3,
                    child: Text(
                      S.of(context).paramvalue,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // 单位
                  Expanded(
                    flex: 1,
                    child: Text(
                      S.of(context).unit,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 操作（设置按钮）
                  SizedBox(
                    width: 80,
                    child: Text(
                      S.of(context).operation,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // ========== 参数列表 ==========
            Expanded(
              child: ListView.builder(
                itemCount: _params.length,
                itemBuilder: (context, index) {
                  final param = _params[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          // 参数名
                          Expanded(
                            flex: 2,
                            child: Text(
                              param.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          // 参数值输入框
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _controllers[index],
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.blue, // 设置输入文字颜色
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                              onSubmitted: (_) => _onSettingPressed(index),
                            ),
                          ),
                          // 单位（固定宽度，居中）
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              param.unit,
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // 设置按钮（固定宽度 72）
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: ElevatedButton(
                              onPressed: () => _onSettingPressed(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(S.of(context).set),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }
}

/// 参数数据模型
class ParamItem {
  String name;
  String value;
  String unit;
  int Cmd;

  ParamItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.Cmd,
  });
}
