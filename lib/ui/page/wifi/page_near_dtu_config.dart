/*
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_settings/app_settings.dart';
import 'package:crclib/catalog.dart';
import 'package:crclib/crclib.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart' hide RefreshCallback;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pinyin/pinyin.dart';
import 'package:sise_solar/ssli/device_feature.dart';
import 'package:sise_solar/ssli/proto.dart';
import 'package:sise_solar/ssli/ssli_manager.dart';
import 'package:sise_solar/ssli/udp_helper.dart';
import 'package:sise_solar/ssli/wifi_config.dart';
import 'package:sise_solar/ui/dialog/dialog_loading.dart';
import 'package:sise_solar/ui/page/page_device.dart';
import 'package:sise_solar/ui/page/wifi_config/page_diagnose.dart';
import 'package:sise_solar/ui/panel/panel_add_subtraction_box.dart';
import 'package:sise_solar/ui/panel/panel_button_with_index.dart';
import 'package:sise_solar/ui/panel/panel_pfv2_logic_2.dart';
import 'package:sise_solar/ui/panel/panel_pfv2_physic.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../../../../generated/l10n.dart';
import '../../../../ssli/eutil.dart';
import '../../../../ssli/prof.dart';

import '../../item/my_dropdown_textfield.dart';
import '../../item/my_scaffold.dart';
import '../../panel/fronus/panel_list_check.dart';
import '../../panel/fronus/panel_list_textfield.dart';
import '../../ui_config.dart';
import '../../widget_helper.dart';

class PageNearDtuConfig extends StatefulWidget {
  String _dtuId;
  bool _wifiConnected; //判断当前是wifi配网还是蓝牙配网
  String? _lastConnected;

  PageNearDtuConfig(
      {super.key, required String dtuId, lastConnected, wifiConnected = false})
      : this._dtuId = dtuId,
        this._lastConnected = lastConnected,
        this._wifiConnected = wifiConnected;

  @override
  State<PageNearDtuConfig> createState() => _PageNearDtuConfigState();
}

class _PageNearDtuConfigState extends State<PageNearDtuConfig> {
  final _ctrlSsid = SingleValueDropDownController();
  final _txtKey = TextEditingController();
  String? ssidValue;
  bool _hideKey = true;
  List<String> _ssidList = [];
  bool _deviceConnected = false;
  bool _deviceFault = false;
  Timer? wifiStateTimer;
  bool _timeCancel = false;
  _dlgInfoConnect? dlgInfo; //= _dlgIn foConnect();
  bool _checkDhcpEn = true;
  final _txtCtrlIp = TextEditingController();
  final _txtCtrlSubnet = TextEditingController();
  final _txtCtrlGw = TextEditingController();
  final _txtCtrlDns = TextEditingController();
  bool _showNetSet = false;
  bool _hasLostConnected = false; //判断设备是否断开连接
  bool _lastWifiState = false; //判断上一次wifi的状态，用来监控wifi是连接/断开网络
  String? _lastWifiSSID; //上一次wifi的SSID，用来监控连接的Wi-Fi是否改变

  int _currentIndex = 0;
  List<String> _labels = ["数据", "控制", "告警", "调试"];
  int? verCode;
  String? protocolNo;
  String? detectCIHex;
  String? detectCP;
  Map<String, dynamic>? gatherProtocol;
  String? gatherSingleDevEventsCIHex;
  String? gatherSingleDevEventsCN;
  List<String?> gatherSingleDevPropsCIHexList = [];
  List<String?> gatherSingleDevPropsCNList = [];
  List<String?> gatherSingleDevPropsCOList = [];
  List<int?> baudRateL = [0];
  List<int?> dataBitL = [0];
  List<String?> parityBitL = [""];
  List<int?> stopBitL = [0];
  DateTime? latestUpdated; //用于数据页面
  DateTime? latestUpdated2; //用于告警页面
  FlowFeature? _fSolar;
  FlowFeature? _fGrid;
  FlowFeature? _fLoad;
  FlowFeature? _fBattery;
  String? valueDisplayUnitInverter;
  List<List<FeatureGroup>> featureGroupListFrags =
      []; //用于记录各条命令获取来的featureGroupList
  //List<FeatureGroup> featureGroupList = []; //用于数据页面
  List<FeatureGroup> featureGroupList2 = []; //用于控制页面
  List<FeatureGroup> featureGroupList3 = []; //用于有序的数据页面
  Map<String, FeatureAttribute> featureAttributes = {}; //配合featureGroupList3使用
  List<Alarm> listAlarm = [];
  bool? autoAdaptive;
  bool? isBleKeyEnable;
  bool? applied;
  bool? isMainThreadWorking;
  bool instantRefresh = true; //即时刷新subData页面
  bool preprocess = false; //网络信息预处理
  bool did = false;
  late Completer apply;
  Completer? thread;
  Completer? waitForNextRound;
  late Widget subDebug;
  List<String> debugSettings = [
    "",
    "",
    "",
    "",
    "",
    ""
  ]; //= ["文本","无","无","文本","无","无"];
  bool firstRound = true; // 首轮
  Map<String, bool> alarmKey = {};

  void wifi_check() async {
    if (widget._wifiConnected == false) return;
    while (_timeCancel == false) {
      await Future.delayed(Duration(seconds: 2));
      bool wifiState = await WiFiForIoTPlugin.isConnected();
      String? tmp = await WiFiForIoTPlugin.getSSID();
      if (_lastWifiState == wifiState && _lastWifiSSID == tmp) {
        _lastWifiState = wifiState;
        _lastWifiSSID = tmp;
        continue;
      } else {
        _lastWifiState = wifiState;
        _lastWifiSSID = tmp;
      }
      if (wifiState == false) {
        _hasLostConnected = true;
        _showInfo();
      } else {
        if (/*widget._wifiConnected==true && */ tmp !=
            Prof.instance.prefixSSID + widget._dtuId) {
          _hasLostConnected = true;
          _showInfo();
        } else {
          _hideInfo();
          String? ip = await WiFiForIoTPlugin.getIP();
          if (ip != null && ip != "0.0.0.0" && _hasLostConnected) {
            UdpHelper.getInstance().doInit();
            _deviceConnected = true;
          }
          if (mounted)
            setState(() {
              _hasLostConnected = false;
            });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    subDebug = _subDebug(debugSettings, baudRateL, dataBitL, parityBitL,
        stopBitL, applyAndWait, threadComplete);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showDialog(
          context: context,
          builder: (BuildContext _) {
            return DialogLoading(
              false,
              onWillPop: () {
                //点击返回键退出页面
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              onTap: () {
                if (mounted) {
                } else {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(S.of(context).double_tap_to_exit /*"双击屏幕退出当前页面"*/),
                  duration: const Duration(milliseconds: 800),
                ));
              },
              onDoubleTap: () {
                //双击屏幕退出页面
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            );
          });
    });
    Future.delayed(Duration.zero, () async {
      await Proto.nearCheckIn(
              SSLiManager.instance.getToken() ?? "", widget._dtuId)
          .then((rplData) {
        verCode = rplData["gatherProtocol"]?["verCode"];
        protocolNo = rplData["gatherProtocol"]?["protocolNo"];
        autoAdaptive = rplData["gatherProtocol"]?["autoAdaptive"];
        print(
            "verCode:$verCode protocolNo:$protocolNo autoAdaptive:$autoAdaptive");
      });
      if (autoAdaptive == true) {
        await Proto.nearDetectGatherProtocol(
                SSLiManager.instance.getToken() ?? "", widget._dtuId, "", "")
            .then((rplData) {
          detectCIHex = decodeToHex(rplData["detectCmd"]?["cmdIn"]);
          detectCP = rplData["detectCmd"]?["cmdPath"];
          baudRateL[0] = rplData["uart"]?["baudRate"];
          dataBitL[0] = rplData["uart"]?["dataBit"];
          parityBitL[0] = rplData["uart"]?["parityBit"];
          stopBitL[0] = rplData["uart"]?["stopBit"];
        });
      }
      if (verCode == null || protocolNo == null) {
        setState(() {
          preprocess = true;
        });
        return;
      }
      Proto.nearGetFeatureGroup(SSLiManager.instance.getToken() ?? "",
              widget._dtuId, protocolNo ?? "", verCode ?? 0,
              category: 3)
          .then((rpl) {
        if (rpl.containsKey("errMsg") == false) {
          List<dynamic>? list = rpl['attributesGroups'];
          if (list != null && list.length > 0) {
            for (int i = 0; i < list.length; i++) {
              Map<String, dynamic> map = list[i];
              FeatureGroup? fg = FeatureGroup.fromJson(map, category: 3);
              if (fg != null && fg.isSetupGroup()) {
                print(
                    "fgkey:${fg.fgKey} attributes.length:${fg.attributes.length}");
                featureGroupList2.add(fg);
              }
            }
          }
          print("featureGroupList2.length:${featureGroupList2.length}");
          /*print("featureGroupList.length:${featureGroupList.length}");
          if (featureGroupList.length == 1) {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageSetupControl(deviceInfo: widget._deviceInfo, featureGroup: featureGroupList[0]);
            }));
          }else if (mounted) setState(() {});*/
        }
      });

      ///333
      Proto.nearGetFeatureGroup(SSLiManager.instance.getToken() ?? "",
              widget._dtuId, protocolNo ?? "", verCode ?? 0,
              category: 1)
          .then((rpl) {
        if (rpl.containsKey("errMsg") == false) {
          List<dynamic>? list = rpl['attributesGroups'];
          if (list != null && list.length > 0) {
            for (int i = 0; i < list.length; i++) {
              Map<String, dynamic> map = list[i];
              FeatureGroup? fg = FeatureGroup.fromJson(map);
              if (fg != null && fg.isStateGroup()) {
                featureGroupList3.add(fg);
                fg.attributes.forEach((fa) {
                  featureAttributes[fa.key] = fa;
                });
              }
              if (true) {
                //适配特定协议
                if (fg != null &&
                    !fg.isStateGroup() &&
                    (fg.name == "更多" || fg.name == "more")) {
                  featureGroupList3.add(fg);
                  fg.attributes.forEach((fa) {
                    featureAttributes[fa.key] = fa;
                  });
                }
              }
            }
          }
          print("featureGroupList3.length:${featureGroupList3.length}");
        }
      });

      gatherProtocol = await Proto.nearGatherProtocol(
          SSLiManager.instance.getToken() ?? "",
          widget._dtuId,
          protocolNo ?? "",
          verCode ?? 0);
      if (gatherProtocol != null &&
          gatherProtocol!["gatherSingleDevEvents"] != null &&
          gatherProtocol!["gatherSingleDevEvents"].isNotEmpty) {
        gatherSingleDevEventsCIHex =
            decodeToHex(gatherProtocol!["gatherSingleDevEvents"][0]["cmdIn"]);
        gatherSingleDevEventsCN =
            gatherProtocol!["gatherSingleDevEvents"][0]["cmdNo"];
      }
      if (gatherProtocol != null &&
          gatherProtocol!["gatherSingleDevProps"] != null) {
        for (int i = 1;
            i <= gatherProtocol!["gatherSingleDevProps"].length;
            i++) {
          gatherSingleDevPropsCIHexList.add(decodeToHex(
              gatherProtocol!["gatherSingleDevProps"][i - 1]["cmdIn"]));
          gatherSingleDevPropsCNList
              .add(gatherProtocol!["gatherSingleDevProps"][i - 1]["cmdNo"]);
          gatherSingleDevPropsCOList.add("");
          featureGroupListFrags.add(<FeatureGroup>[]);
        }
      }
      if (gatherProtocol != null && gatherProtocol!["uart"] != null) {
        baudRateL[0] = gatherProtocol!["uart"]["baudRate"];
        dataBitL[0] = gatherProtocol!["uart"]["dataBit"];
        parityBitL[0] = gatherProtocol!["uart"]["parityBit"];
        stopBitL[0] = gatherProtocol!["uart"]["stopBit"];
      }
      setState(() {
        preprocess = true;
      });
    });

    print("WiFiConfig initState:");
    ssidValue = widget._lastConnected ?? "";

    Future.delayed(Duration.zero, () async {
      bool bState = false;
      String? defaultSSID = Prof.instance.defaultSSIDConfig;
      if (defaultSSID != null) {
        ssidValue = defaultSSID;
        String? key = await Prof.instance.getKeyBySSID(defaultSSID);
        if (key != null) {
          _txtKey.text = key;
        }
        bState = true;
      }

      List<String> list = await Prof.instance.getSSIDList();
      if (list.length > 0) {
        _ssidList = list;
        bState = true;
      }
      if (mounted && bState == true) setState(() {});
    });
    wifi_check();

    WiFiConfig.instance.doSetActionDtuId(widget._dtuId);
    if (widget._wifiConnected == false) {
      WiFiConfig.instance
          .streamSetDtuIdWithBleConnect(widget._dtuId)
          .listen((event) {
        if (mounted) {
          setState(() {
            if (event == "connect") {
              _deviceConnected = true;
              _hasLostConnected = false;
            } else if (event == "disconn") {
              _deviceConnected = false;
              _hasLostConnected = true;
            } else if (event == "fault") {
              _deviceFault = true;
              _hasLostConnected = false;
            } else if (event == "connecting") {
              _deviceConnected = false;
              _hasLostConnected = false;
            }
          });
        }
      });
    } else {
      _deviceConnected = true;
      _deviceFault = false;
      _hasLostConnected = false;
    }

    WiFiConfig.instance.streamBleState().listen((state) {
      //检测蓝牙打开关闭状态
      if (state == false) {
        _hasLostConnected = false;
        _deviceConnected = false;
      }
    });
  }

  @override
  void dispose() {
    print("WiFiConfig dispose:");
    _txtCtrlIp.dispose();
    _txtCtrlSubnet.dispose();
    _txtCtrlGw.dispose();
    _txtCtrlDns.dispose();
    _ctrlSsid.dispose();
    _txtKey.dispose();
    _timeCancel = true;
    WiFiConfig.instance.doBleStopConnect();
    super.dispose();
  }

  List<DropDownValueModel> showDropDown() {
    if (_ssidList.length == 0) {
      _ctrlSsid.clearDropDown();
      return [];
    } else {
      List<DropDownValueModel> list = [];
      for (int i = 0; i < _ssidList.length; i++) {
        String ssid = _ssidList[i];
        list.add(DropDownValueModel(name: ssid, value: i.toString()));
      }
      return list;
    }
  }

  void doDeleteSSID(int index) async {
    if (index < _ssidList.length) {
      String ssid = _ssidList[index];
      await Prof.instance.removeSSIDandKey(ssid);
      _ssidList = await Prof.instance.getSSIDList();
      if (mounted) setState(() {});
    }
  }

  FocusNode textFieldFocusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    _labels = [
      S.of(context).data,
      S.of(context).control,
      S.of(context).alarm,
      S.of(context).debug
    ];
    if (debugSettings[0] == "") {
      debugSettings[0] = S.of(context).text;
      debugSettings[1] = S.of(context).no;
      debugSettings[2] = S.of(context).no;
      debugSettings[3] = S.of(context).text;
      debugSettings[4] = S.of(context).no;
      debugSettings[5] = S.of(context).no;
    }
    List<Widget>? actions;
    if (_currentIndex == 0) {
      actions = WidgetHelper.showHomeActions(
          (isBleKeyEnable == false)
              ? [
                  HomeAction(
                      svgFile: "assets/icon_lock.svg",
                      label: S.of(context).set_Password /*"设置密码"*/,
                      key: "set"),
                  HomeAction(
                      svgFile: "assets/icon_safety.svg",
                      label: S.of(context).forget_pwd /*"忘记密码"*/,
                      key: "forget"),
                  HomeAction(
                      svgFile: "assets/icon_lock.svg",
                      label: "恢复出厂设置",
                      key: "reset"),
                  //HomeAction(svgFile: "assets/fronus/编辑.svg", label: "诊断", key: "diagnose"),
                ]
              : [
                  HomeAction(
                      svgFile: "assets/icon_safety.svg",
                      label: S.of(context).forget_pwd /*"忘记密码"*/,
                      key: "forget"),
                ], (key) async {
        if (key == "set") await setPassword();
        if (key == "change") {
          late bool result;
          late String key;
          Completer completer = Completer();
          if (mounted) {
          } else {
            return;
          }
          await WidgetHelper.showNormalHintDialog(context,
              title: "重置密码",
              hintText: "请输入不小于8位的密码",
              contentHeight: 55, ascertain: (_) {
            key = _;
            completer.complete();
          }).then((value) async {
            if (value == false) return;
            showDialog(
                context: context,
                builder: (BuildContext _) {
                  return DialogLoading(false);
                });
            await completer.future;
            await applyAndWait(); //等待主线程暂停
            result = await WiFiConfig.instance.doSetBleKey(true, key: key);
            print("result:${result}");
            if (result == false) {
              Navigator.of(context).pop(); //关闭转圈
              WidgetHelper.showAlertDialog(context, "设置失败", null);
              thread!.complete(); //该线程结束
              return;
            }
            isBleKeyEnable = true;
            print("修改密码成功，重新验证密码");
            await WiFiConfig.instance.doVerifyBleKey(key);
            Navigator.of(context).pop(); //关闭转圈
            WidgetHelper.showAlertDialog(context, "设置成功", null);
            thread!.complete(); //该线程结束
          });
          print("isBleKeyEnable:${isBleKeyEnable}");
        }
        if (key == "forget") {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return PageResetBleKey();
          }));
        }
        if (key == "reset") {
          await applyAndWait(); //等待主线程暂停
          await WiFiConfig.instance.resetDevice().then((value) {
            if (value == true)
              WidgetHelper.showAlertDialog(context, "指令发送成功", null);
            if (value == false)
              WidgetHelper.showAlertDialog(context, "指令发送失败", null);
          });
          thread!.complete(); //该线程结束
        }
        if (key == "diagnose") {
          if (!_hasLostConnected && !_deviceFault && _deviceConnected) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageDiagnose(
                dtuId: widget._dtuId,
                editable: false,
                wifiConnected: widget._wifiConnected,
              );
            }));
          } else {
            WidgetHelper.showAlertDialog(
                context, S.of(context).connect_tips, null);
          }
        }
      }, icon: Icons.menu);
      actions = null; //临时隐藏密码功能
    }
    if (_currentIndex == 3) {
      actions = [
        InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageDebugSetting(debugSettings);
            }));
          },
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.more_horiz,
              color: SSLi.themeOtherItemColor("icon_reverse"),
            ),
          ),
        )
      ];
    }
    if (!_hasLostConnected && !_deviceFault && _deviceConnected && preprocess) {
      //print("连接成功");
      if (did == true) {
      } else {
        did = true;
        Future.delayed(Duration.zero, () async {
          //todo 解决重联重新验证密码问题

          if (mounted) {
          } else {
            return;
          }
          isBleKeyEnable = await WiFiConfig.instance.doCheckBleKeyEnable();
          if (isBleKeyEnable == false) {
            if (mounted) {
            } else {
              return;
            }
            Navigator.of(context).pop(); //关闭转圈
            /* 临时
            WidgetHelper.showNormalNonInputDialog(context,
                title: S.of(context).please_note/*"温馨提示"*/,
                hint: Column(
                  children: [
                    Text(
                        "        " + S.of(context).set_password_tip1.replaceAll(' ', '\u{000A0}')/*"可设置管理密码，设置后再通过蓝牙直连对设备做控制时需要密码才能正常使用。"*/,
                        style: SSLi.textStyleLittleWithColor("white20")),
                    Text("\n"+S.of(context).set_password_tip2.replaceAll(' ', '\u{000A0}')/*"您也可以在监控页面重新设置或修改管理密码。"*/,
                        style: SSLi.textStyleLittleWithColor("white80")),
                  ],
                ),
                contentHeight: SSLiLanguage.sharedInstance().isZh?110:150,
                cancel: S.of(context).ignore/*"忽略"*/,
                ascertain: S.of(context).Go_to_set_up/*"去设置"*/)
                .then((value) {
                  if (value == false) return;
                  setPassword();
                });
            */
          }
          if (isBleKeyEnable == null) {
            //存在蓝牙密码
            String? savedKey = await Prof.instance.getBleKey(widget._dtuId);
            print("savedKey:${savedKey}");
            bool quit = false;
            bool result = false;
            bool firstTime = true;
            bool didSavePwd = false;
            late String key;

            while (result == false) {
              Completer completer = Completer();
              if (savedKey == null) {
                if (mounted) {
                } else {
                  return;
                }
                await WidgetHelper.showNormalHintDialog(context,
                    title: S.of(context).verify_password /*"验证密码"*/,
                    hintText: firstTime
                        ? S
                            .of(context)
                            .input_password_no_less_than_8_digits /*"请输入不小于8位的密码"*/
                        : S.of(context).verification_failed /*"验证失败，请重新输入"*/,
                    obscureText: true,
                    contentHeight: 80,
                    hint: StatefulBuilder(
                        builder: (BuildContext context, StateSetter _setState) {
                      return Row(
                        children: [
                          SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                  value: didSavePwd,
                                  onChanged: (value) {
                                    _setState(() {
                                      didSavePwd = !didSavePwd;
                                    });
                                  })),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            S.of(context).remember_password /*"记住密码"*/,
                            style: TextStyle(fontSize: 14),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                      return PageResetBleKey();
                                    }));
                                  },
                                  child: Text(
                                    "${S.of(context).forget_pwd /*"忘记密码"*/}?"
                                        .replaceAll(' ', '\u{000A0}'),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                            ),
                          )
                        ],
                      );
                    }),
                    barrierDismissible: false,
                    //禁止点击弹窗外部以取消
                    ascertain: (_) {
                      key = _;
                      completer.complete();
                    }).then((value) async {
                  if (value == false) {
                    Navigator.of(context).pop(); //关闭转圈
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); //退出搜索设备页面
                    quit = true;
                    return; //跳出then函数
                  }
                  await completer.future;
                  if (key.isEmpty || key.length < 8 || key.length > 16) {
                    await WidgetHelper.showAlertDialog(context,
                        S.of(context).input_8_16_digits /*"密码长度"*/, null);
                    result = false;
                  } else
                    result = await WiFiConfig.instance.doVerifyBleKey(key);
                  firstTime = false;
                });
                if (quit == true) return; //跳出Future函数
              }

              if (savedKey != null) {
                if (savedKey.isEmpty ||
                    savedKey.length < 8 ||
                    savedKey.length > 16) {
                  await WidgetHelper.showAlertDialog(context,
                      S.of(context).input_8_16_digits /*"密码长度"*/, null);
                  result = false;
                } else
                  result = await WiFiConfig.instance.doVerifyBleKey(savedKey);
                if (result == false)
                  await Prof.instance.deleteBleKey(widget._dtuId);
                savedKey = null;
                firstTime = false;
              }
              print("result:${result}");
            }
            if (mounted) {
            } else {
              return;
            }
            Navigator.of(context).pop(); //关闭转圈
            if (didSavePwd == true)
              await Prof.instance.setBleKey(widget._dtuId, key);
            isBleKeyEnable = true;
            await WiFiConfig.instance.doSetBleKey(false).then((value) {
              //验证成功后取消用户的密码 临时
              if (value == true) isBleKeyEnable = false;
            });
          }
          print("isBleKeyEnable:${isBleKeyEnable}");

          if (mounted) setState(() {});
          await Future.delayed(const Duration(seconds: 1)); //等待重建完成

          if (autoAdaptive == true && detectCIHex != null && detectCP != null) {
            bool failed = false;
            while (true) {
              if (applied == true) {
                applied = false;
                apply.complete();
                await thread!.future;
              }
              if (mounted) {
              } else {
                return;
              }
              await WiFiConfig.instance
                  .doGetUartDiagnose(
                      uartCmd: detectCIHex!,
                      baudRate: baudRateL[0] ?? 0,
                      dataBit: dataBitL[0] ?? 0,
                      parityBit: parityBitL[0] ?? "",
                      stopBit: stopBitL[0] ?? 0)
                  .then((rpl) async {
                if (rpl == null) {
                  failed = true;
                  return;
                }
                await Proto.nearDetectGatherProtocol(
                        SSLiManager.instance.getToken() ?? "",
                        widget._dtuId,
                        encodeToBase64(rpl["Rsp"]) ?? "",
                        detectCP!)
                    .then((rplData) {
                  if (rpl.containsKey("errMsg")) {
                    failed = true;
                    return;
                  }
                  verCode = rplData["gatherProtocol"]?["verCode"];
                  protocolNo = rplData["gatherProtocol"]?["protocolNo"];
                  if (verCode != null && protocolNo != null) return;
                  detectCIHex = decodeToHex(rplData["detectCmd"]?["cmdIn"]);
                  detectCP = rplData["detectCmd"]?["cmdPath"];
                  baudRateL[0] = rplData["uart"]?["baudRate"];
                  dataBitL[0] = rplData["uart"]?["dataBit"];
                  parityBitL[0] = rplData["uart"]?["parityBit"];
                  stopBitL[0] = rplData["uart"]?["stopBit"];
                });
              });
              if (failed == true) break;
              if (verCode != null && protocolNo != null) break;
            }
            if (verCode == null || protocolNo == null) {
              print("侦测采集协议失败");
              /*
              if( mounted){} else{ return;}
              WidgetHelper.showAlertDialog(context, "侦测采集协议失败", null)
                  .then((value) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              });
              */
              // return;
            }
            Proto.nearGetFeatureGroup(SSLiManager.instance.getToken() ?? "",
                    widget._dtuId, protocolNo ?? "", verCode ?? 0,
                    category: 3)
                .then((rpl) {
              if (rpl.containsKey("errMsg") == false) {
                List<dynamic>? list = rpl['attributesGroups'];
                if (list != null && list.length > 0) {
                  for (int i = 0; i < list.length; i++) {
                    Map<String, dynamic> map = list[i];
                    FeatureGroup? fg = FeatureGroup.fromJson(map, category: 3);
                    if (fg != null && fg.isSetupGroup()) {
                      print(
                          "fgkey:${fg.fgKey} attributes.length:${fg.attributes.length}");
                      featureGroupList2.add(fg);
                    }
                  }
                }
                print("featureGroupList2.length:${featureGroupList2.length}");
                /*print("featureGroupList.length:${featureGroupList.length}");
          if (featureGroupList.length == 1) {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageSetupControl(deviceInfo: widget._deviceInfo, featureGroup: featureGroupList[0]);
            }));
          }else if (mounted) setState(() {});*/
              }
            });
            Proto.nearGetFeatureGroup(SSLiManager.instance.getToken() ?? "",
                    widget._dtuId, protocolNo ?? "", verCode ?? 0,
                    category: 1)
                .then((rpl) {
              if (rpl.containsKey("errMsg") == false) {
                List<dynamic>? list = rpl['attributesGroups'];
                if (list != null && list.length > 0) {
                  for (int i = 0; i < list.length; i++) {
                    Map<String, dynamic> map = list[i];
                    FeatureGroup? fg = FeatureGroup.fromJson(map);
                    if (fg != null && fg.isStateGroup()) {
                      featureGroupList3.add(fg);
                      fg.attributes.forEach((fa) {
                        featureAttributes[fa.key] = fa;
                      });
                    }
                    if (true) {
                      //适配特定协议
                      if (fg != null &&
                          !fg.isStateGroup() &&
                          (fg.name == "更多" || fg.name == "more")) {
                        featureGroupList3.add(fg);
                        fg.attributes.forEach((fa) {
                          featureAttributes[fa.key] = fa;
                        });
                      }
                    }
                  }
                }
                print("featureGroupList3.length:${featureGroupList3.length}");
              }
            });
            gatherProtocol = await Proto.nearGatherProtocol(
                SSLiManager.instance.getToken() ?? "",
                widget._dtuId,
                protocolNo ?? "",
                verCode ?? 0);
            if (gatherProtocol != null &&
                gatherProtocol!["gatherSingleDevEvents"] != null &&
                gatherProtocol!["gatherSingleDevEvents"].isNotEmpty) {
              gatherSingleDevEventsCIHex = decodeToHex(
                  gatherProtocol!["gatherSingleDevEvents"][0]["cmdIn"]);
              gatherSingleDevEventsCN =
                  gatherProtocol!["gatherSingleDevEvents"][0]["cmdNo"];
            }
            if (gatherProtocol != null &&
                gatherProtocol!["gatherSingleDevProps"] != null) {
              for (int i = 1;
                  i <= gatherProtocol!["gatherSingleDevProps"].length;
                  i++) {
                gatherSingleDevPropsCIHexList.add(decodeToHex(
                    gatherProtocol!["gatherSingleDevProps"][i - 1]["cmdIn"]));
                gatherSingleDevPropsCNList.add(
                    gatherProtocol!["gatherSingleDevProps"][i - 1]["cmdNo"]);
                gatherSingleDevPropsCOList.add("");
                featureGroupListFrags.add(<FeatureGroup>[]);
              }
            }
            if (gatherProtocol != null && gatherProtocol!["uart"] != null) {
              baudRateL[0] = gatherProtocol!["uart"]["baudRate"];
              dataBitL[0] = gatherProtocol!["uart"]["dataBit"];
              parityBitL[0] = gatherProtocol!["uart"]["parityBit"];
              stopBitL[0] = gatherProtocol!["uart"]["stopBit"];
            }
          }

          //isMainThreadWorking = false; return; //for test
          //以下为周期性重复的部分

          while (mounted) {
            print("loop start");
            print("instantRefresh:${instantRefresh}");

            isMainThreadWorking = true;
            if (thread != null && !thread!.isCompleted) {
              print("次线程运行中");
              await thread!.future; //有次线程运行中就等待其完成
              print("次线程结束");
            }

            if (gatherSingleDevEventsCIHex != null) {
              print("GatherSingleDevEvents");
              if (applied == true) {
                print("次线程申请");
                applied = false;
                apply.complete();
                await thread!.future;
                print("次线程结束");
              }
              if (mounted) {
              } else {
                return;
              }
              await WiFiConfig.instance
                  .doGetUartDiagnose(
                uartCmd: gatherSingleDevEventsCIHex!,
                baudRate: baudRateL[0] ?? 0,
                dataBit: dataBitL[0] ?? 0,
                parityBit: parityBitL[0] ?? "",
                stopBit: stopBitL[0] ?? 0,
                cmdType: "gatherSingleDevEvents",
                cmdNo: gatherSingleDevEventsCN ?? "",
              )
                  .then((rplData) async {
                if (rplData == null) return;
                latestUpdated2 = DateTime.now();
                await Proto.nearParseEvent(
                        SSLiManager.instance.getToken() ?? "",
                        widget._dtuId,
                        protocolNo ?? "",
                        verCode ?? 0,
                        gatherSingleDevEventsCN ?? "",
                        encodeToBase64(rplData["Rsp"]) ?? "")
                    .then((rplData2) {
                  if (rplData2["data"] is! List) return;
                  listAlarm.clear(); //
                  rplData2["data"].forEach((element) {
                    Alarm? alarm = Alarm.fromJson(element);
                    if (alarm != null) listAlarm.add(alarm);
                  });
                  print("listAlarm.length:${listAlarm.length}");
                });
              });
            }

            if (mounted) setState(() {});
            //await Future.delayed(const Duration(seconds: 1)); //等待重建完成

            Map<int, List<dynamic>> groups = {};
            for (int j = 1; j <= gatherSingleDevPropsCIHexList.length; j++) {
              //for( int j = 1; j <= math.min( 10, gatherSingleDevPropsCIHexList.length); j++){//for test
              print(
                  "GatherSingleDevProps: $j / ${gatherSingleDevPropsCIHexList.length}");
              String? gatherSingleDevPropsCIHex =
                  gatherSingleDevPropsCIHexList[j - 1];
              String? gatherSingleDevPropsCN =
                  gatherSingleDevPropsCNList[j - 1];
              if (applied == true) {
                print("次线程申请");
                applied = false;
                apply.complete();
                await thread!.future;
                print("次线程结束");
              }
              if (mounted) {
              } else {
                return;
              }
              await WiFiConfig.instance
                  .doGetUartDiagnose(
                uartCmd: gatherSingleDevPropsCIHex ?? "",
                baudRate: baudRateL[0] ?? 0,
                dataBit: dataBitL[0] ?? 0,
                parityBit: parityBitL[0] ?? "",
                stopBit: stopBitL[0] ?? 0,
                cmdType: "gatherSingleDevProps",
                cmdNo: gatherSingleDevPropsCN ?? "",
              )
                  .then((rplData) async {
                if (rplData == null) return;
                if (instantRefresh == true ||
                    (instantRefresh == false &&
                        j == gatherSingleDevPropsCIHexList.length)) {
                  latestUpdated = DateTime.now();
                  gatherSingleDevPropsCOList[j - 1] =
                      encodeToBase64(rplData["Rsp"]) ?? "";
                  await Proto.nearParseEnergyFlow(
                          SSLiManager.instance.getToken() ?? "",
                          widget._dtuId,
                          protocolNo ?? "",
                          verCode ?? 0,
                          firstRound
                              ? gatherSingleDevPropsCNList.sublist(0, j - 1 + 1)
                              : gatherSingleDevPropsCNList, //gatherSingleDevPropsCN ?? "",
                          firstRound
                              ? gatherSingleDevPropsCOList.sublist(0, j - 1 + 1)
                              : gatherSingleDevPropsCOList //encodeToBase64(rplData["Rsp"]) ?? ""
                          )
                      .then((rpl) {
                    if (rpl.containsKey("errMsg") == false) {
                      FlowFeature? fSolar =
                          FlowFeature.fromMap(rpl, "pvPanelFlow");
                      if (fSolar?.unit == "watt") {
                        fSolar?.unit = "W";
                      }
                      FlowFeature? fGrid = FlowFeature.fromMap(rpl, "gridFlow");
                      FlowFeature? fLoad = FlowFeature.fromMap(rpl, "loadFlow");
                      FlowFeature? fBattery =
                          FlowFeature.fromMap(rpl, "batteryFlow");
                      if (fSolar != null) _fSolar = fSolar;
                      if (fGrid != null) _fGrid = fGrid;
                      if (fLoad != null) _fLoad = fLoad;
                      if (fBattery != null) _fBattery = fBattery;

                      print("_flSolar:" + _fSolar.toString());
                      print("_flGrid:" + _fGrid.toString());
                      print("_flLoad:" + _fLoad.toString());
                      print("_flBattery:" + _fBattery.toString());
                    }
                  });
                }
                await Proto.nearParseState(
                        SSLiManager.instance.getToken() ?? "",
                        widget._dtuId,
                        protocolNo ?? "",
                        verCode ?? 0,
                        gatherSingleDevPropsCN ?? "",
                        encodeToBase64(rplData["Rsp"]) ?? "")
                    .then((rpl) {
                  if (instantRefresh == false) {
                    if (rpl.containsKey("errMsg") == false) {
                      List<dynamic>? list = rpl['groups'];
                      if (list != null && list.length > 0) {
                        groups[j] = list;
                      }
                    }
                  } else {
                    if (rpl.containsKey("errMsg") == false) {
                      //featureGroupListFrags[j - 1].clear();
                      List<dynamic>? list = rpl['groups'];
                      if (list != null && list.length > 0) {
                        for (int i = 0; i < list.length; i++) {
                          Map<String, dynamic> map = list[i];
                          FeatureGroup? fg = FeatureGroup.fromJson(map);
                          if (fg != null && fg.isStateGroup()) {
                            //fg.name += "${j-1}";
                            //featureGroupList.add(fg);
                            //featureGroupListFrags[j - 1].add(fg);
                            fg.attributes.forEach((fa) {
                              if (fa.key == "workingMode")
                                valueDisplayUnitInverter = fa.valueDisplay;
                              if (featureAttributes.containsKey(fa.key))
                                featureAttributes[fa.key]!.valueDisplay =
                                    fa.valueDisplay;
                            });
                          }
                          if (fg != null &&
                              !fg.isStateGroup() &&
                              (fg.name == "更多" || fg.name == "more")) {
                            //fg.name += "${j-1}";
                            //featureGroupList.add(fg);
                            //featureGroupListFrags[j - 1].add(fg);
                            fg.attributes.forEach((fa) {
                              if (fa.key == "workingMode")
                                valueDisplayUnitInverter = fa.valueDisplay;
                              if (featureAttributes.containsKey(fa.key))
                                featureAttributes[fa.key]!.valueDisplay =
                                    fa.valueDisplay;
                            });
                          }
                        }
                      }
                    }
                    //print("featureGroupListFrags[${j - 1}].length:${featureGroupListFrags[j - 1].length}");
                  }
                });
              });
              if (instantRefresh == false &&
                  j == gatherSingleDevPropsCIHexList.length) {
                groups.forEach((j_, list) {
                  //featureGroupListFrags[j_ - 1].clear();
                  //if (list != null && list.length > 0) {
                  if (true) {
                    for (int i = 0; i < list.length; i++) {
                      Map<String, dynamic> map = list[i];
                      FeatureGroup? fg = FeatureGroup.fromJson(map);
                      if (fg != null && fg.isStateGroup()) {
                        //fg.name += "${j-1}";
                        //featureGroupList.add(fg);
                        //featureGroupListFrags[j_ - 1].add(fg);
                        fg.attributes.forEach((fa) {
                          if (fa.key == "workingMode")
                            valueDisplayUnitInverter = fa.valueDisplay;
                          if (featureAttributes.containsKey(fa.key))
                            featureAttributes[fa.key]!.valueDisplay =
                                fa.valueDisplay;
                        });
                      }
                      if (fg != null &&
                          !fg.isStateGroup() &&
                          (fg.name == "更多" || fg.name == "more")) {
                        //fg.name += "${j-1}";
                        //featureGroupList.add(fg);
                        //featureGroupListFrags[j_ - 1].add(fg);
                        fg.attributes.forEach((fa) {
                          if (fa.key == "workingMode")
                            valueDisplayUnitInverter = fa.valueDisplay;
                          if (featureAttributes.containsKey(fa.key))
                            featureAttributes[fa.key]!.valueDisplay =
                                fa.valueDisplay;
                        });
                      }
                    }
                  }
                });
              }
              if (mounted) setState(() {});
              //await Future.delayed(const Duration(seconds: 1)); //等待重建完成
            }
            firstRound = false;

            isMainThreadWorking = false;
            if (applied == true) {
              print("次线程申请");
              applied = false;
              apply.complete();
              print("次线程开始运行");
              //await thread.future;
            }

            waitForNextRound = Completer(); //在此以下的情况subData页面的下拉刷新才有意义
            instantRefresh = false;
            if (mounted) setState(() {});
            await Future.delayed(const Duration(seconds: 1)); //等待重建完成
            print("loop end");
            //等待60秒后开启下一轮或者用户手动下拉刷新开启下一轮
            await Future.any([
              Future.delayed(const Duration(seconds: 60), () {}),
              waitForNextRound!.future
            ]);
            if (!waitForNextRound!.isCompleted) waitForNextRound!.complete();
            waitForNextRound = null;
          }
        });
      }
    }
    return MyScaffold(
        appBar: WidgetHelper.itemAppBar(
          title: (_hasLostConnected
              ? S.of(context).unconnected
              : (_deviceFault
                  ? S.of(context).device_err
                  : (_deviceConnected
                      ? widget._dtuId
                      : S.of(context).connecting))),
          actions: actions,
          backgroundColor:
              _currentIndex == 0 ? Colors.white : Colors.transparent,
        ),
        body: showBody(),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: SSLi.themeBottomNavigatorColor,
          unselectedItemColor:
              const Color(0xFFBBBBBB), //SSLi.themeOtherItemColor('light'),
          selectedItemColor:
              const Color(0xFF1B64F7), //SSLi.themeOtherItemColor('theme_text'),
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              label: _labels[0],
              icon: SvgPicture.asset(
                "assets/近端数采/数据-灰.svg",
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                "assets/近端数采/数据-蓝.svg",
                width: 24,
              ),
            ),
            BottomNavigationBarItem(
              label: _labels[1],
              icon: SvgPicture.asset(
                "assets/近端数采/控制-灰.svg",
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                "assets/近端数采/控制-蓝.svg",
                width: 24,
              ),
            ),
            BottomNavigationBarItem(
              label: _labels[2],
              icon: SvgPicture.asset(
                "assets/近端数采/告警-灰.svg",
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                "assets/近端数采/告警-蓝.svg",
                width: 24,
              ),
            ),
            BottomNavigationBarItem(
              label: _labels[3],
              icon: SvgPicture.asset(
                "assets/近端数采/调试-灰.svg",
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                "assets/近端数采/调试-灰.svg",
                width: 24,
                color: const Color(0xFF1B64F7),
              ),
            ),
          ],
        ));
  }

  Widget showBody() {
    if (_currentIndex == 0) {
      return _subData(
        latestUpdated: latestUpdated,
        fSolar: _fSolar,
        fGrid: _fGrid,
        fLoad: _fLoad,
        fBattery: _fBattery,
        featureGroupListFrags: featureGroupListFrags,
        featureGroupList3: featureGroupList3,
        refreshCallback: subDataRefreshCallback,
        valueDisplayUnitInverter: valueDisplayUnitInverter,
      );
    }
    if (_currentIndex == 1) {
      return _subControl(
          featureGroupList2,
          [verCode],
          [protocolNo],
          widget._dtuId,
          baudRateL,
          dataBitL,
          parityBitL,
          stopBitL,
          applyAndWait,
          threadComplete);
    }
    if (_currentIndex == 2) {
      return _subAlarm(listAlarm, latestUpdated2, alarmKey);
    }
    if (_currentIndex == 3) {
      return subDebug;
    }
    return const SizedBox.shrink();
  }

  List<Widget> showDhcp() {
    List<Widget> list = [];
    list.add(
      FronusPanelListCheck(
          label: "DHCP",
          checked: _checkDhcpEn,
          onTap: (checked) {
            if (mounted)
              setState(() {
                _checkDhcpEn = checked;
              });
          }),
    );
    list.add(
      Divider(
        height: 2,
        thickness: 1,
        color: SSLi.themeOtherItemColor("light"),
      ),
    );
    if (!_checkDhcpEn) {
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlIp,
          label: S.of(context).ip_address,
          hint: S.of(context).info_input_ip /*"请输入IP地址"*/,
          labelStyle: SSLi.textStyleLittle,
          textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlSubnet,
          label: S.of(context).subnet,
          hint: S.of(context).info_input_subnet /*"请输入子网掩码"*/,
          labelStyle: SSLi.textStyleLittle,
          textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlGw,
          label: S.of(context).gateway,
          hint: S.of(context).info_input_gateway /*"请输入网关地址"*/,
          labelStyle: SSLi.textStyleLittle,
          textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlDns,
          label: S.of(context).dns,
          hint: S.of(context).info_input_dns /*"请输入DNS服务器地址"*/,
          labelStyle: SSLi.textStyleLittle,
          textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
    }
    list.add(SizedBox(
      height: 5,
    ));
    list.add(Text(
      S
          .of(context)
          .info_setup_dhcp /*"如果确定路由器已关闭DHCP功能，请手动设置IP地址等网络参数，否则保持DHCP使能不变。"*/,
      style: SSLi.textStyleLittleMoreLight,
    ));
    return list;
  }

  void doUnfocus(context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showWaiting(context, ssid, key) {
    // Prof.instance.addSSIDandKey(ssid, key);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _dlgWaiting(
            ssid: ssid,
            wkey: key,
            dtuId: widget._dtuId,
          );
        }).then((value) {
      if (value == true) {
        //Navigator.popUntil(context, ModalRoute.withName("/"));
        Navigator.of(context).pop(true);
      }
    });
  }

  void _showInfo() async {
    if (widget._wifiConnected == false) return;
    // print("_showInfo:1");
    if (dlgInfo != null) return;
    // print("_showInfo:2");
    if (mounted)
      setState(() {
        _deviceConnected = true;
        _deviceFault = false;
      });
    dlgInfo = _dlgInfoConnect(widget._dtuId);
    dlgInfo!.bshow = true;
    // await Future.delayed(Duration(seconds: 6));
    if (mounted && dlgInfo != null) {
      // print("_showInfo:3");
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return dlgInfo!;
          }).then((value) {
        dlgInfo = null;
      });
    }
  }

  void _hideInfo() {
    // print("_hideInfo:1");
    if (dlgInfo != null && dlgInfo!.bshow == true) {
      // print("_hideInfo:2");
      if (dlgInfo!.bshow == true) {
        // print("_hideInfo:3");
        if (mounted)
          setState(() {
            _deviceConnected = false;
            _deviceFault = false;
          });
        dlgInfo!.doHide();
      }
    }
  }

  String? decodeToHex(String? base64Encoded) {
    if (base64Encoded == null) return null;
    List<int> decodedBytes = base64.decode(base64Encoded);
    String hexString = bytesToHex(decodedBytes).toUpperCase();
    return hexString;
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  String? encodeToBase64(String? hexString) {
    if (hexString == null) return null;
    final List<int> result = [];
    try {
      for (int i = 0; i < hexString.length; i += 2) {
        result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
      }
    } catch (e) {
      return null;
    }
    return base64.encode(result);
  }

  Future<void> applyAndWait() async {
    print("applyAndWait invoked");
    thread = Completer();
    if (isMainThreadWorking == false) return;
    apply = Completer();
    applied = true;
    await apply.future;
    return;
  }

  void threadComplete() {
    print("threadComplete invoked");
    thread!.complete();
  }

  Future<void> setPassword() async {
    late bool result;
    late String key;
    Completer completer = Completer();
    if (mounted) {
    } else {
      return;
    }
    await WidgetHelper.showNormalHintDialog(context,
        title: S.of(context).security_settings /*"安全设置"*/,
        hintText: S
            .of(context)
            .input_password_no_less_than_8_digits /*"请输入不小于8位的密码"*/,
        obscureText: true,
        contentHeight: SSLiLanguage.sharedInstance().isZh ? 90 : 100,
        hint: Stack(
          children: [
            Text(
                "      " +
                    S
                        .of(context)
                        .set_password_tip /*"设置密码后，对设备做控制时需要输入密码才能使用"*/,
                style: SSLi.textStyleLittleWithColor("white20")),
            Icon(
              Icons.error,
              size: 18,
              color: Colors.amber,
            )
          ],
        ), ascertain: (_) {
      key = _;
      completer.complete();
    }).then((value) async {
      if (value == false) return;
      showDialog(
          context: context,
          builder: (BuildContext _) {
            return DialogLoading(false);
          });
      await completer.future;
      if (key.isEmpty || key.length < 8 || key.length > 16) {
        Navigator.of(context).pop(); //关闭转圈
        WidgetHelper.showAlertDialog(
            context, S.of(context).input_8_16_digits /*"密码长度"*/, null);
        return;
      }
      await applyAndWait(); //等待主线程暂停
      result = await WiFiConfig.instance.doSetBleKey(true, key: key);
      print("result:${result}");
      if (result == false) {
        Navigator.of(context).pop(); //关闭转圈
        WidgetHelper.showAlertDialog(
            context, S.of(context).setup_failed /*"设置失败"*/, null);
        thread!.complete(); //该线程结束
        return;
      }
      isBleKeyEnable = true;
      print("修改密码成功，重新验证密码");
      await WiFiConfig.instance.doVerifyBleKey(key);
      Navigator.of(context).pop(); //关闭转圈
      WidgetHelper.showAlertDialog(
          context, S.of(context).setup_worked /*"设置成功"*/, null);
      thread!.complete(); //该线程结束
    });
    if (mounted) setState(() {});
    print("isBleKeyEnable:${isBleKeyEnable}");
  }

  Future<void> subDataRefreshCallback() async {
    if (waitForNextRound != null && !waitForNextRound!.isCompleted) {
    } else
      return;
    print("subDataRefreshCallback invoked");
    instantRefresh = true;
    waitForNextRound!.complete();
  }
}

class _dlgInfoConnect extends StatefulWidget {
  //wifi断开时的弹窗
  bool bshow = false;
  String dtuId;
  _dlgInfoConnect(this.dtuId);

  _dlgInfoConnectState state = _dlgInfoConnectState();
  void doHide() {
    state.doHide();
  }

  @override
  State<_dlgInfoConnect> createState() => state;
}

class _dlgInfoConnectState extends State<_dlgInfoConnect> {
  BuildContext? thisContext;

  void doHide() {
    if (thisContext != null && widget.bshow == true) {
      // _bshow= false;
      Navigator.of(thisContext!).pop();
    }
  }

  @override
  void dispose() {
    widget.bshow = false;
    thisContext = null;
    print("_hideInfo:dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    thisContext = context;
    return SimpleDialog(
      children: [
        Container(
          padding: EdgeInsets.only(left: SSLi.sidePad, right: SSLi.sidePad),
          height: 150,
          width: 280,
          color: Colors.white,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 10,
            ),
            Text(
              S.of(context).info_reconnect /*"模块连接已断开，请重新连接"*/,
              style: SSLi.textStyleNormalWithColor("white20"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              Prof.instance.prefixSSID + widget.dtuId,
              style: SSLi.textStyleNormalWithColor("white20"),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(thisContext!).pop();
                          },
                          child: Text(
                            S.of(context).back /*返回*/,
                            style: SSLi.textStyleNormalWithColor("button_text"),
                          ),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(70, 40),
                              backgroundColor:
                                  SSLi.themeOtherItemColor("button_normal"))),
                      ElevatedButton(
                          onPressed: () {
                            AppSettings.openAppSettings(
                                type: AppSettingsType.wifi);
                          },
                          child: Text(
                            S.of(context).connect /*"连接"*/,
                            style: SSLi.textStyleNormalWithColor("button_text"),
                          ),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(70, 40),
                              backgroundColor:
                                  SSLi.themeOtherItemColor("button_normal"))),
                    ]))
          ]),
        )
      ],
    );
  }
}

class _dlgWaiting extends StatefulWidget {
  String _dtuId;
  String _ssid;
  String _wkey;
  _dlgWaiting(
      {super.key,
      required String dtuId,
      required String ssid,
      required String wkey})
      : this._dtuId = dtuId,
        this._ssid = ssid,
        this._wkey = wkey;

  @override
  State<_dlgWaiting> createState() => _dlgWaitingState();
}

class _dlgWaitingState extends State<_dlgWaiting> {
  int _timeSec = 0;
  Timer? _timerWaiting;
  // WifiConfigSoftAP? _wifiConfig;
  bool isRunning = true;
  bool isConfigOK = false;
  bool isCanceled = false;
  double _percent = 0;
  String? _word;

  Future<void> waitForFinish() async {
    if (WiFiConfig.instance.WiFiConfigOngoing == true) {
      WiFiConfig.instance.cancelWiFiConfig();
    } else {
      return;
    }
    while (WiFiConfig.instance.WiFiConfigOngoing == true) {
      await Future.delayed(Duration(milliseconds: 500));
    }
    await Future.delayed(Duration(milliseconds: 500));
    print("waitForFinish");
  }

  void doConfigProcess() async {
    _hconnTime = 0;
    if (mounted)
      setState(() {
        _percent = 0.1;
      }); // 连接建立
    await waitForFinish(); // 等待前一次配网结束
    /*
    Map<String,dynamic> rplData;
    rplData = await Proto.nearCheckIn( SSLiManager.instance.getToken()?? "", widget._dtuId);
    print("rplData:$rplData");
    rplData = await Proto.nearGatherProtocol( SSLiManager.instance.getToken()?? "", widget._dtuId,"AW938596",9);
    print("rplData:$rplData");
    await Proto.nearDetectGatherProtocol( SSLiManager.instance.getToken()?? "", widget._dtuId,"","");
    return;
    */
    WiFiConfig.instance
        .streamWiFiConfig(ssid: widget._ssid, key: widget._wkey)
        .listen((msg) {
      print("msg.step:${msg.step} msg.code:${msg.code}");
      if (!mounted) {
        // WiFiConfig.instance.doStop();
        isRunning = false;
        isConfigOK = false;
        return;
      }

      // if (isRunning==false) return;
      String wd = WiFiConfig.instance.wordFromCode(context, msg.code ?? 0);
      if (_word != wd && wd.isNotEmpty) {
        if (mounted)
          setState(() {
            _word = wd;
          });
      }
      if (msg.step == 0) {
        // WiFiConfig.instance.doStop();
        isRunning = false;
        isConfigOK = false;
        if (mounted)
          setState(() {
            _percent = 0.0;
          });
      } else if (msg.step == 1) {
        // percent 30%;  wifi命令下发完成
        if (_percent < 0.3) {
          if (mounted)
            setState(() {
              _percent = 0.3;
            });
        }
      } else if (msg.step == 2) {
        // percent 60%; 模块正在连接
        if (_percent < 0.6) {
          if (mounted)
            setState(() {
              _percent = 0.6;
            });
        }
      } else if (msg.step == 3) {
        // percent 90%; 模块连接Wi-Fi
        if (msg.code == 300) {
          // HConn
          if (_percent < 0.9) {
            _hconnTime = DateTime.now().millisecondsSinceEpoch;
            print("set _hconnTime=$_hconnTime");
            if (mounted)
              setState(() {
                _percent = 0.9;
              });
          }
        } else {
          if (_percent < 0.8) {
            if (mounted)
              setState(() {
                _percent = 0.8;
              });
          }
        }
      } else if (msg.step == 4) {
        // percent 100%;  模块连接云服务
        // WiFiConfig.instance.doStop();
        isRunning = false;
        if (msg.code == 400 || msg.code == 403) {
          isConfigOK = true;
          if (mounted)
            setState(() {
              _percent = 1.0;
            });
        } else {
          isConfigOK = false;
          if (mounted)
            setState(() {
              _percent = 0.0;
            });
        }
      } else if (msg.step == 5) {
        // canceled
        // WiFiConfig.instance.doStop();
        if (isRunning == true) {
          isRunning = false;
          isConfigOK = false;
          isCanceled = msg.code == 500 ? true : false;
          setState(() {
            _percent = 0.0;
          });
        }
      }
    });
  }

  int _hconnTime = 0;
  @override
  void initState() {
    super.initState();
    _timerWaiting = Timer.periodic(Duration(seconds: 1), (timer) {
      _timeSec++;
      int now = DateTime.now().millisecondsSinceEpoch;
      // print("set _hconnTime=$_hconnTime::now=$now");
      // 超时时设置配网失败，以免stream跑崩的情况下，配网不能停止
      if (_hconnTime > 0 && now - _hconnTime > 5000) {
        WiFiConfig.instance.cancelWiFiConfig(timeout: true);
        isRunning = false;
        isConfigOK = true;
        _percent = 1.0;
      }
      /*
      if (_timeSec>=60){
        WiFiConfig.instance.cancelWiFiConfig(timeout: true);
        isRunning= false;
        isConfigOK= false;
        _percent=0.0;
        if (_hconnTime>0){
          isConfigOK= true;
          _percent=1.0;
        }
      }
      */
      if (mounted)
        setState(() {});
      else
        timer.cancel();
    });
    _percent = 0;
    isRunning = true;
    isConfigOK = false;
    isCanceled = false;
    doConfigProcess();
  }

  @override
  void dispose() {
    _timerWaiting?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Container(
          padding: EdgeInsets.only(left: SSLi.sidePad, right: SSLi.sidePad),
          width: 300,
          height: 260,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(height: 10,),
              // isRunning?CircularProgressIndicator(color: SSLi.themeOtherItemColor("button_normal"),):SizedBox(height: 30,),
              CircularPercentIndicator(
                progressColor: SSLi.themeOtherItemColor("button_normal"),
                center: Text((_percent * 100).round().toString() + " %"),
                percent: _percent,
                lineWidth: 2,
                radius: 50.0,
              ),
              SizedBox(
                height: 10,
              ),
              Text(isRunning
                  ? (S.of(context).info_wait_for_config /*"正在配网，请稍等..."*/ +
                      _timeSec.toString())
                  : isConfigOK
                      ? (S.of(context).info_success_wifi_config /*"配网成功"*/)
                      : isCanceled
                          ? (S.of(context).info_cancel_wifi_config /*"配网取消"*/)
                          : (S.of(context).info_fail_wifi_config /*"配网失败"*/)),
              SizedBox(
                height: 5,
              ),
              Text(
                _word ?? "",
                style: SSLi.textStyleLittleMoreWithColor("white60"),
              ),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.only(left: 40, right: 40),
                child: ElevatedButton(
                    onPressed: () {
                      if (isRunning == false) {
                        Navigator.of(context).pop(isConfigOK);
                      } else {
                        WiFiConfig.instance.cancelWiFiConfig();
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      isRunning
                          ? S.of(context).cancel_config /*"取消配网"*/
                          : S.of(context).back /*返回*/,
                      style: SSLi.textStyleNormalWithColor("button_text"),
                    ),
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 46),
                        backgroundColor:
                            SSLi.themeOtherItemColor("button_normal"))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _subData extends StatefulWidget {
  DateTime? latestUpdated;
  FlowFeature? fSolar;
  FlowFeature? fGrid;
  FlowFeature? fLoad;
  FlowFeature? fBattery;
  String? valueDisplayUnitInverter;
  List<List<FeatureGroup>> featureGroupListFrags;
  //List<FeatureGroup> featureGroupList;
  List<FeatureGroup> featureGroupList3;
  RefreshCallback refreshCallback;
  _subData({
    required this.latestUpdated,
    required this.fSolar,
    required this.fGrid,
    required this.fLoad,
    required this.fBattery,
    required this.featureGroupListFrags,
    required this.featureGroupList3,
    required this.refreshCallback,
    this.valueDisplayUnitInverter,
  });
  @override
  State<_subData> createState() => _subDataState();
}

class _subDataState extends State<_subData> {
  bool _showPhysic = false;
  bool _working = true;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.refreshCallback,
      child: ListView(
        children: [
          Container(
            color: Colors.white,
            child: _showPhysic
                ? PanelPFV2Physic(
                    solarValue: widget.fSolar,
                    gridValue: widget.fGrid,
                    loadValue: widget.fLoad,
                    batteryValue: widget.fBattery,
                    batteryPercent: 100,
                    valueDisplayUnitInverter: widget.valueDisplayUnitInverter,
                    onTap: (zoneId) async {
                      if (zoneId == "logic") {
                        _showPhysic = false;
                        if (mounted) setState(() {});
                      }
                    },
                    working: _working)
                : PanelPFV2Logic(
                    solarValue: widget.fSolar,
                    gridValue: widget.fGrid,
                    loadValue: widget.fLoad,
                    batteryValue: widget.fBattery,
                    batteryPercent: 100,
                    onTap: (zoneId) async {
                      if (zoneId == "physic") {
                        _showPhysic = true;
                        if (mounted) setState(() {});
                      }
                    },
                    working: _working),
          ),
          Stack(
            children: [
              Container(
                color: Colors.white,
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text("time",
                      style: SSLiTextStyles.douyinSansBold(
                          fontSize: 16, color: const Color(0xFF666666))),
                )),
              ),
              Container(
                decoration: BoxDecoration(
                    color: SSLi.themeBackgroundColor,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                      (widget.latestUpdated == null)
                          ? S.of(context).no_data_available /*"暂无数据"*/
                          : removeLastDot(widget.latestUpdated.toString()),
                      style: SSLiTextStyles.douyinSansBold(
                          fontSize: 16, color: const Color(0xFF666666))),
                )),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          ...generateExpansionTile3()
        ],
      ),
    );
  }

  String removeLastDot(String input) {
    int lastDotIndex = input.lastIndexOf('.');

    if (lastDotIndex != -1) {
      return input.substring(0, lastDotIndex);
    } else {
      // 如果没有找到小数点，返回原始字符串
      return input;
    }
  }

  List<Widget> generateExpansionTile() {
    List<Widget> listCard = [];
    widget.featureGroupListFrags.forEach((featureGroupList) {
      featureGroupList.forEach((fg) {
        List<Widget> list = [];
        fg.attributes.forEach((fa) {
          list.add(Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fa.name, style: SSLi.textStyleNormal),
                Text(
                  "${fa.valueDisplay} ${fa.unit}",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                )
              ],
            ),
          ));
        });
        listCard.add(Card(
          shadowColor: Colors.transparent,
          color: SSLi.themeSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.5),
          ),
          child: Theme(
            data: ThemeData(
              dividerColor: Colors.transparent, // 设置分割线为透明
            ),
            child: ExpansionTile(
              title: Text(fg.name, style: SSLi.textStyleNormal),
              //initiallyExpanded:false, //初始状态
              children: list,
            ),
          ),
        ));
      });
    });
    return listCard;
  }

  List<Widget> generateExpansionTile2() {
    List<Widget> listCard = [];
    Map<String, List<Widget>> lists = {};
    widget.featureGroupListFrags.forEach((featureGroupList) {
      featureGroupList.forEach((fg) {
        if (lists[fg.name] == null) lists[fg.name] = [];
        fg.attributes.forEach((fa) {
          lists[fg.name]!.add(Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fa.name, style: SSLi.textStyleLittle),
                Text(
                  "${fa.valueDisplay} ${fa.unit}",
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                )
              ],
            ),
          ));
          lists[fg.name]!.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Divider(
                height: 1,
                color: Color(0xFFADADAD),
              ),
            ),
          );
        });
      });
    });
    String? more;
    List<Widget>? listMore;
    lists.forEach((name, list) {
      list.removeLast();
      if (name == "更多" || name == "more" || name == "More") {
        more = name;
        listMore = list;
      } else
        listCard.add(Card(
          shadowColor: Colors.transparent,
          color: SSLi.themeSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.5),
          ),
          child: Theme(
            data: ThemeData(
              dividerColor: Colors.transparent, // 设置分割线为透明
            ),
            child: ExpansionTile(
              title: Text(name, style: SSLi.textStyleNormal),
              //initiallyExpanded:false, //初始状态
              children: list,
            ),
          ),
        ));
    });
    if (more != null && listMore != null)
      listCard.add(Card(
        shadowColor: Colors.transparent,
        color: SSLi.themeSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.5),
        ),
        child: Theme(
          data: ThemeData(
            dividerColor: Colors.transparent, // 设置分割线为透明
          ),
          child: ExpansionTile(
            title: Text(more!, style: SSLi.textStyleNormal),
            //initiallyExpanded:false, //初始状态
            children: listMore!,
          ),
        ),
      ));
    return listCard;
  }

  List<Widget> generateExpansionTile3() {
    List<Widget> listCard = [];
    Map<String, List<Widget>> lists = {};
    Map<String, String?> key = {};
    widget.featureGroupList3.forEach((fg) {
      if (lists[fg.name] == null) {
        lists[fg.name] = [];
        key[fg.name] = fg.fgKey;
      }
      fg.attributes.forEach((fa) {
        lists[fg.name]!.add(Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fa.name,
                  style: SSLiTextStyles.pingFangMedium(
                      fontSize: 14, color: const Color(0xFF666666))),
              Text(
                fa.valueDisplay == "null"
                    ? "--"
                    : "${fa.valueDisplay} ${fa.unit ?? ""}",
                style: SSLiTextStyles.pingFangBold(
                    fontSize: 14, color: const Color(0xFF333333)),
              )
            ],
          ),
        ));
        lists[fg.name]!.add(
          const Divider(
            indent: 20,
            endIndent: 20,
            height: 1,
            color: Color(0xFFF7F7F7),
            thickness: 1,
          ),
        );
      });
    });
    String? more;
    List<Widget>? listMore;
    lists.forEach((name, list) {
      if (list.isNotEmpty) list.removeLast();
      if (name == "更多" || name == "more" || name == "More") {
        more = name;
        listMore = list;
      } else {
        listCard.add(Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Card(
            margin: EdgeInsets.zero,
            shadowColor: Colors.transparent,
            color: SSLi.themeSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Theme(
              data: ThemeData(
                dividerColor: Colors.transparent, // 设置分割线为透明
              ),
              child: ExpansionTile(
                leading: getIcon(key[name]),
                title: Text(name,
                    style: SSLiTextStyles.pingFangBold(
                        fontSize: 16, color: const Color(0xFF333333))),
                iconColor: ExpansionTileTheme.of(context).collapsedIconColor ??
                    Theme.of(context).unselectedWidgetColor,
                //initiallyExpanded:false, //初始状态
                children: list,
              ),
            ),
          ),
        ));
        listCard.add(const SizedBox(
          height: 10,
        ));
      }
    });
    if (more != null && listMore != null) {
      listCard.add(Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Card(
          margin: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          color: SSLi.themeSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Theme(
            data: ThemeData(
              dividerColor: Colors.transparent, // 设置分割线为透明
            ),
            child: ExpansionTile(
              leading: SvgPicture.asset(
                "assets/近端数采/其他.svg",
                width: 32,
              ),
              title: Text(more!,
                  style: SSLiTextStyles.pingFangBold(
                      fontSize: 16, color: const Color(0xFF333333))),
              iconColor: ExpansionTileTheme.of(context).collapsedIconColor ??
                  Theme.of(context).unselectedWidgetColor,
              //initiallyExpanded:false, //初始状态
              children: listMore!,
            ),
          ),
        ),
      ));
      listCard.add(const SizedBox(
        height: 10,
      ));
    }
    return listCard;
  }

  Widget? getIcon(String? key) {
    if (key == null) return null;
    if (key.toLowerCase().contains("battery"))
      return SvgPicture.asset(
        "assets/近端数采/电池.svg",
        width: 32,
      );
    if (key.toLowerCase().contains("grid"))
      return SvgPicture.asset(
        "assets/近端数采/电网.svg",
        width: 32,
      );
    if (key.toLowerCase().contains("load"))
      return SvgPicture.asset(
        "assets/近端数采/负载.svg",
        width: 32,
      );
    if (key.toLowerCase().contains("pv"))
      return SvgPicture.asset(
        "assets/近端数采/光伏板.svg",
        width: 32,
      );
    if (key.toLowerCase().contains("inverter"))
      return Image.asset(
        "assets/逻辑图图标/逆变器@2x.png",
        width: 32,
      );
    return null;
  }
}

class _subAlarm extends StatefulWidget {
  List<Alarm> listAlarm;
  DateTime? latestUpdated;
  Map<String, bool> alarmKey;
  _subAlarm(this.listAlarm, this.latestUpdated, this.alarmKey);
  @override
  State<_subAlarm> createState() => _subAlarmState();
}

class _subAlarmState extends State<_subAlarm> {
  @override
  Widget build(BuildContext context) {
    return widget.listAlarm.isNotEmpty
        ? ListView(children: [
            ...List.generate(widget.listAlarm.length, (index) {
              Alarm alarm = widget.listAlarm[index];
              if (alarm.key == null) return const SizedBox.shrink();
              if (alarm.isProcessed == false) {
                widget.alarmKey[alarm.key!] = false;
              } else {
                if (widget.alarmKey.containsKey(alarm.key!)) {
                } else {
                  return const SizedBox.shrink();
                }
              }
              return Column(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.only(left: 15, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                alarm.level == 3
                                    ? const Color(0x1AF44327)
                                    : const Color(0x1AFFC120),
                                alarm.level == 3
                                    ? const Color(0x00F44327)
                                    : const Color(0x00FFC120),
                              ],
                              begin: Alignment.centerLeft, // 渐变起点
                              end: Alignment.centerRight, // 渐变终点
                            ),
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                height: 36,
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Icon(
                                Icons.warning_rounded,
                                color: alarm.level == 3
                                    ? const Color(0xFFFF0000)
                                    : Colors.amber /*与未处理颜色一致*/,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                S.of(context).alarm_description +
                                    ": " /*"告警描述"*/,
                                style: SSLiTextStyles.pingFangMedium(
                                    fontSize: 12,
                                    color: const Color(0xFF666666)),
                              ),
                              Text(
                                alarm.description ?? "",
                                style: SSLiTextStyles.pingFangBold(
                                    fontSize: 12,
                                    color: const Color(0xFF333333)),
                              ),
                              const Spacer(),
                              Container(
                                width: 56,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: alarm.isProcessed == false
                                      ? const Color(0x1AF44327)
                                      : alarm.isProcessed == true
                                          ? const Color(0x1A999999)
                                          : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Align(
                                  child: Text(
                                    alarm.isProcessed == false
                                        ? S.of(context).unprocessed /*未处理*/
                                        : alarm.isProcessed == true
                                            ? S.of(context).processed /*已处理*/
                                            : S.of(context).ignored /*已忽略*/,
                                    style: alarm.isProcessed == false
                                        ? SSLiTextStyles.pingFangBold(
                                            fontSize: 12,
                                            color: const Color(
                                                0xFFF44327)) /*SSLi.textStyleLittleMoreWeightWithColor("fault")*/
                                        : alarm.isProcessed == true
                                            ? SSLiTextStyles.pingFangBold(
                                                fontSize: 12,
                                                color: const Color(
                                                    0xFF999999)) /*SSLi.textStyleLittleMoreWeightWithColor("light")*/
                                            : SSLiTextStyles.pingFangBold(
                                                fontSize:
                                                    12) /*SSLi.textStyleLittleMoreLightWeight*/,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              alarm.isProcessed == false
                                  ? "${S.of(context).occurrence_time}: "
                                  : "${S.of(context).end_time}: ",
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 12, color: const Color(0xFF666666)),
                            ),
                            Text(
                              alarm.isProcessed == false
                                  ? "${alarm.localCreatedAt}"
                                  : "${alarm.localDisappearedAt}",
                              style: SSLiTextStyles.pingFangBold(
                                  fontSize: 12, color: const Color(0xFF333333)),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              );
            })
          ])
        : Center(
            child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Transform.scale(
                  scale: 0.75, child: Image.asset("assets/无告警.png")),
              Text(
                S.of(context).alarms_tip,
                style: TextStyle(fontSize: 16, color: Colors.orange),
              ),
            ],
          ));
  }

  String removeLastDot(String input) {
    int lastDotIndex = input.lastIndexOf('.');

    if (lastDotIndex != -1) {
      return input.substring(0, lastDotIndex);
    } else {
      // 如果没有找到小数点，返回原始字符串
      return input;
    }
  }
}

class _subControl extends StatefulWidget {
  List<FeatureGroup> featureGroupList;
  List<int?> verCodeL;
  List<String?> protocolNoL;
  String dtuId;
  List<int?> baudRateL;
  List<int?> dataBitL;
  List<String?> parityBitL;
  List<int?> stopBitL;
  Function applyAndWait;
  Function threadComplete;
  _subControl(
      this.featureGroupList,
      this.verCodeL,
      this.protocolNoL,
      this.dtuId,
      this.baudRateL,
      this.dataBitL,
      this.parityBitL,
      this.stopBitL,
      this.applyAndWait,
      this.threadComplete);
  @override
  State<_subControl> createState() => _subControlState();
}

class _subControlState extends State<_subControl> {
  FeatureGroup? getFeatureGroup(String key) {
    for (int i = 0; i < widget.featureGroupList.length; i++) {
      if (widget.featureGroupList[i].fgKey == key) {
        print(
            "fgKey=${widget.featureGroupList[i].fgKey},name=${widget.featureGroupList[i].name},attr num=${widget.featureGroupList[i].attributes.length}");
        return widget.featureGroupList[i];
      }
    }
    return null;
  }

  List<Widget> showList() {
    List<Widget> list = [];
    list.add(const SizedBox(
      height: 5,
    ));
    for (int i = 0; i < widget.featureGroupList.length; i++) {
      FeatureGroup fg = widget.featureGroupList[i];
      list.add(Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageControl(
                  widget.featureGroupList[i],
                  widget.verCodeL,
                  widget.protocolNoL,
                  widget.dtuId,
                  widget.baudRateL,
                  widget.dataBitL,
                  widget.parityBitL,
                  widget.stopBitL,
                  widget.applyAndWait,
                  widget.threadComplete);
            }));
          },
          child: Ink(
            height: 54,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[300]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                Text(
                  fg.name,
                  style: SSLiTextStyles.pingFangBold(
                      fontSize: 16, color: const Color(0xFF333333)),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_right,
                  size: 18,
                  color: Color(0xFFBBBBBB),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ),
        ),
      ));
      list.add(const SizedBox(
        height: 10,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return (widget.featureGroupList.isEmpty)
        ? Center(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                ),
                Image.asset(
                  "assets/缺省页-暂未添加设置项@2x.png",
                  height: 100,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  S.of(context).no_settings_added_yet /*"暂未添加设置项"*/,
                  style: SSLiTextStyles.pingFangSemibold(
                      fontSize: 18, color: const Color(0xFF333333)),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: showList(),
            ),
          );
  }
}

class PageControl extends StatefulWidget {
  FeatureGroup? featureGroup;
  List<int?> verCodeL;
  List<String?> protocolNoL;
  String dtuId;
  List<int?> baudRateL;
  List<int?> dataBitL;
  List<String?> parityBitL;
  List<int?> stopBitL;
  Function applyAndWait;
  Function threadComplete;
  PageControl(
      this.featureGroup,
      this.verCodeL,
      this.protocolNoL,
      this.dtuId,
      this.baudRateL,
      this.dataBitL,
      this.parityBitL,
      this.stopBitL,
      this.applyAndWait,
      this.threadComplete);
  @override
  State<PageControl> createState() => _PageControlState();
}

class _PageControlState extends State<PageControl> {
  List<Widget> listViewList = [];
  List<String> valueList = [];
  late BuildContext buildContext;
  int currentPage = 0;
  int count = 0; //请求次数
  int fail = 0; //请求失败次数
  String result = ""; //请求失败结果
  PageController controller = PageController();
  bool requestEnd = true; //请求锁
  bool isKeyboardVisible = false;
  int listenId = 0;
  // late FocusScopeNode currentFocus;
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  Map<int, double> delta = {};
  Map<int, int> decimalPlace = {};
  Timer? timer; // NumberControllerWidget

  @override
  void initState() {
    super.initState();
    if (widget.featureGroup == null) return;
    for (int i = 0; i < widget.featureGroup!.attributes.length; i++) {
      valueList.add("");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.featureGroup == null) return;
      count = 0;
      fail = 0;
      result = "";
      var len = 10;
      if (currentPage ==
          (widget.featureGroup!.attributes.length / 10).floor()) {
        len = widget.featureGroup!.attributes.length % 10;
      }
      if (true /*key == "read"*/) {
        int page = currentPage;
        if (!requestEnd) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).try_again_later, null);
          return;
        }
        int canNotRead = 0;
        for (int i = page * 10; i < len + page * 10; i++) {
          if (widget.featureGroup!.attributes[i].operationMode == 2)
            canNotRead++;
        }
        if (canNotRead == len) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).no_read_items, null);
          return;
        }
        requestEnd = false;
        /*for (int i=page*10; i<len+page*10; i++) {
            await read(i,true,len+page*10-1);
          }*/
        _nearWaitingContent? content;
        content = _nearWaitingContent(
          title: S.of(context).batch_reading,
          featureGroup: widget.featureGroup,
          requestEnd: requestEnd,
          count: count,
          fail: fail,
          result: result,
          valueList: valueList,
          refresh: () {
            print("refresh invoked");
            //requestEnd = content!.requestEnd;
            //count = content!.count;
            //fail = content!.fail;
            //result = content!.result;
            if (mounted) setState(() {});
          },
          unlock: () {
            requestEnd = true;
          },
          isBatch: true,
          start: page * 10,
          end: len + page * 10,
          rw: "read",
          verCodeL: widget.verCodeL,
          protocolNoL: widget.protocolNoL,
          dtuId: widget.dtuId,
          baudRateL: widget.baudRateL,
          dataBitL: widget.dataBitL,
          parityBitL: widget.parityBitL,
          stopBitL: widget.stopBitL,
          applyAndWait: widget.applyAndWait,
          threadComplete: widget.threadComplete,
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: content,
                contentPadding: const EdgeInsets.only(
                  left: 24.0,
                  top: 20.0,
                  right: 24.0,
                  bottom: 0,
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(S.of(context).close))
                ],
              );
            }).then((value) {
          if (mounted) setState(() {});
        });
      } else if (false /*key == "write"*/) {
        if (!requestEnd) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).try_again_later, null);
          return;
        }
        WidgetHelper.showConfirmDialog(
                context,
                S.of(context).sure_to_continue_modify,
                S.of(context).after_confirmation_to_modify)
            .then((value) async {
          if (value == true) {
            if (!requestEnd) {
              WidgetHelper.showAlertDialog(
                  buildContext, S.of(context).try_again_later, null);
              return;
            }
            int nullCount = 0;
            int page = currentPage;
            for (int i = page * 10; i < len + page * 10; i++) {
              if (valueList[i] == "") nullCount++;
            }
            if (nullCount == len) {
              WidgetHelper.showAlertDialog(
                  buildContext, S.of(context).ensure_one_data, null);
              return;
            }
            requestEnd = false;
            /*for (int i=page*10; i<len+page*10; i++) {
                await write(i,true,len+page*10-1);
              }*/
            _nearWaitingContent? content;
            content = _nearWaitingContent(
              title: S.of(context).batch_deliverying,
              featureGroup: widget.featureGroup,
              requestEnd: requestEnd,
              count: count,
              fail: fail,
              result: result,
              valueList: valueList,
              refresh: () {
                print("refresh invoked");
                //requestEnd = content!.requestEnd;
                //count = content!.count;
                //fail = content!.fail;
                //result = content!.result;
                if (mounted) setState(() {});
              },
              unlock: () {
                requestEnd = true;
              },
              isBatch: true,
              start: page * 10,
              end: len + page * 10,
              rw: 'write',
              verCodeL: widget.verCodeL,
              protocolNoL: widget.protocolNoL,
              dtuId: widget.dtuId,
              baudRateL: widget.baudRateL,
              dataBitL: widget.dataBitL,
              parityBitL: widget.parityBitL,
              stopBitL: widget.stopBitL,
              applyAndWait: widget.applyAndWait,
              threadComplete: widget.threadComplete,
            );
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: content,
                    contentPadding: const EdgeInsets.only(
                      left: 24.0,
                      top: 20.0,
                      right: 24.0,
                      bottom: 0,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(S.of(context).close))
                    ],
                  );
                }).then((value) {
              if (mounted) setState(() {});
            });
          }
        });
      }
    });
    // // 创建 KeyboardVisibilityController 实例
    // _keyboardVisibilitySubscription = KeyboardVisibilityController().onChange.listen((bool visible) {
    //   if (mounted) {
    //     setState(() {
    //     if (!visible && isKeyboardVisible) {
    //       if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    //         FocusManager.instance.primaryFocus?.unfocus();
    //       }
    //     }
    //     isKeyboardVisible = visible;
    //   });
    //   }
    // });
  }

  @override
  void dispose() {
    //   FocusManager.instance.primaryFocus?.unfocus();
    // _keyboardVisibilitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // currentFocus = FocusScope.of(context);
    buildContext = context;
    listViewList = [];
    return MyScaffold(
        // resizeToAvoidBottomInset: true,
        appBar: WidgetHelper.itemAppBar(
            title: S.of(context).equipment_control,
            context: context,
            actions: _showActions(context)),
        body: widget.featureGroup == null ||
                widget.featureGroup?.attributes.isEmpty == true
            ? Center(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 200,
                    ),
                    SvgPicture.asset(
                        "assets/fronus/controlpage_without_data.svg",
                        width: 100,
                        height: 100),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      S.of(context).no_data_add,
                      style: TextStyle(fontSize: 16, color: Colors.orange),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child:
                    // FocusMonitoring(child:
                    Column(children: [
                  /*const SizedBox(height: 30),
      Row(children: [
        Container(
            width: (MediaQuery.of(context).size.width)*2/5,
            height: 20,
            alignment: const Alignment(0, 0),
            child: Text(S.of(context).name, style: SSLi.textStyleNormal,)
        ),
        Container(
            width: (MediaQuery.of(context).size.width)*3/10,
            height: 20,
            alignment: const Alignment(0, 0),
            child: Text(S.of(context).setup, style: SSLi.textStyleNormal)
        ),
        Container(
            width: (MediaQuery.of(context).size.width)*3/10,
            height: 20,
            alignment: const Alignment(0, 0),
            child: Text(S.of(context).operation, style: SSLi.textStyleNormal)
        ),
      ]),
      const SizedBox(height: 5),
      const Divider(height: 1),*/
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        children: GridViewItems(),
                        onPageChanged: (int index) {
                          currentPage = index;
                          if (mounted) setState(() {});
                        }),
                    // Swiper(
                    //   scrollDirection: Axis.horizontal,
                    //   // 横向
                    //   itemBuilder: (BuildContext context, int index) {
                    //     return listViewItems()[index];
                    //   },
                    //   itemCount: listViewItems().length,
                    //   pagination: SwiperPagination(),
                    //   autoplay: false,
                    //   onIndexChanged: (index) {
                    //     currentPage = index;
                    //   }
                    // ),
                  ),
                  const SizedBox(height: 30),
                ]),
                // )
              ));
  }

  List<Widget> _showActions(context) {
    return WidgetHelper.showHomeActions(icon: Icons.more_horiz, [
      HomeAction(
          svgFile: "assets/fronus/batch_search.svg",
          label: S.of(context).batch_read,
          key: "read"),
      // HomeAction(svgFile: "assets/fronus/batch_delivery.svg", label: S.of(context).batch_delivery, key: "write"),
    ], (key) async {
      if (widget.featureGroup == null) return;
      count = 0;
      fail = 0;
      result = "";
      var len = 10;
      if (currentPage ==
          (widget.featureGroup!.attributes.length / 10).floor()) {
        len = widget.featureGroup!.attributes.length % 10;
      }
      if (key == "read") {
        int page = currentPage;
        if (!requestEnd) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).try_again_later, null);
          return;
        }
        int canNotRead = 0;
        for (int i = page * 10; i < len + page * 10; i++) {
          if (widget.featureGroup!.attributes[i].operationMode == 2)
            canNotRead++;
        }
        if (canNotRead == len) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).no_read_items, null);
          return;
        }
        requestEnd = false;
        /*for (int i=page*10; i<len+page*10; i++) {
            await read(i,true,len+page*10-1);
          }*/
        _nearWaitingContent? content;
        content = _nearWaitingContent(
          title: S.of(context).batch_reading,
          featureGroup: widget.featureGroup,
          requestEnd: requestEnd,
          count: count,
          fail: fail,
          result: result,
          valueList: valueList,
          refresh: () {
            print("refresh invoked");
            //requestEnd = content!.requestEnd;
            //count = content!.count;
            //fail = content!.fail;
            //result = content!.result;
            if (mounted) setState(() {});
          },
          unlock: () {
            requestEnd = true;
          },
          isBatch: true,
          start: page * 10,
          end: len + page * 10,
          rw: "read",
          verCodeL: widget.verCodeL,
          protocolNoL: widget.protocolNoL,
          dtuId: widget.dtuId,
          baudRateL: widget.baudRateL,
          dataBitL: widget.dataBitL,
          parityBitL: widget.parityBitL,
          stopBitL: widget.stopBitL,
          applyAndWait: widget.applyAndWait,
          threadComplete: widget.threadComplete,
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: content,
                contentPadding: const EdgeInsets.only(
                  left: 24.0,
                  top: 20.0,
                  right: 24.0,
                  bottom: 0,
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(S.of(context).close))
                ],
              );
            }).then((value) {
          if (mounted) setState(() {});
        });
      } else if (key == "write") {
        if (!requestEnd) {
          WidgetHelper.showAlertDialog(
              buildContext, S.of(context).try_again_later, null);
          return;
        }
        WidgetHelper.showConfirmDialog(
                context,
                S.of(context).sure_to_continue_modify,
                S.of(context).after_confirmation_to_modify)
            .then((value) async {
          if (value == true) {
            if (!requestEnd) {
              WidgetHelper.showAlertDialog(
                  buildContext, S.of(context).try_again_later, null);
              return;
            }
            int nullCount = 0;
            int page = currentPage;
            for (int i = page * 10; i < len + page * 10; i++) {
              if (valueList[i] == "") nullCount++;
            }
            if (nullCount == len) {
              WidgetHelper.showAlertDialog(
                  buildContext, S.of(context).ensure_one_data, null);
              return;
            }
            requestEnd = false;
            /*for (int i=page*10; i<len+page*10; i++) {
                await write(i,true,len+page*10-1);
              }*/
            _nearWaitingContent? content;
            content = _nearWaitingContent(
              title: S.of(context).batch_deliverying,
              featureGroup: widget.featureGroup,
              requestEnd: requestEnd,
              count: count,
              fail: fail,
              result: result,
              valueList: valueList,
              refresh: () {
                print("refresh invoked");
                //requestEnd = content!.requestEnd;
                //count = content!.count;
                //fail = content!.fail;
                //result = content!.result;
                if (mounted) setState(() {});
              },
              unlock: () {
                requestEnd = true;
              },
              isBatch: true,
              start: page * 10,
              end: len + page * 10,
              rw: 'write',
              verCodeL: widget.verCodeL,
              protocolNoL: widget.protocolNoL,
              dtuId: widget.dtuId,
              baudRateL: widget.baudRateL,
              dataBitL: widget.dataBitL,
              parityBitL: widget.parityBitL,
              stopBitL: widget.stopBitL,
              applyAndWait: widget.applyAndWait,
              threadComplete: widget.threadComplete,
            );
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: content,
                    contentPadding: const EdgeInsets.only(
                      left: 24.0,
                      top: 20.0,
                      right: 24.0,
                      bottom: 0,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(S.of(context).close))
                    ],
                  );
                }).then((value) {
              if (mounted) setState(() {});
            });
          }
        });
      }
    });
  }

  List<Widget> listViewItems() {
    List<Widget> ListArr = [];
    if (widget.featureGroup?.attributes.isNotEmpty == true) {
      List<Widget> columnList = [];
      for (int i = 0; i < widget.featureGroup!.attributes.length; i++) {
        FeatureAttribute attr = widget.featureGroup!.attributes[i];
        columnList.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(children: [
                        TextSpan(
                            text: attr.name +
                                (attr.unit == null || attr.unit == ""
                                    ? ""
                                    : "(${attr.unit!})"),
                            style: SSLi.textStyleLittleMore),
                      ])),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*const SizedBox(width: 15),
                Container(
                    width: (MediaQuery
                        .of(context)
                        .size
                        .width - 20) * 2 / 5 - 10,
                    height: 60,
                    alignment: const Alignment(0, 0),
                    child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                            children: [
                              TextSpan(text: attr.name +
                                  (attr.unit == null || attr.unit == ""
                                      ? ""
                                      : "(${attr.unit!})"),
                                  style: SSLi.textStyleLittleMore),
                              // TextSpan(text: attr.hint == null ? "" : "\n${S
                              //     .of(context)
                              //     .range}${attr.hint}",
                              //     style: SSLi.textStyleLittleMore),
                            ]
                        ))
                ),
                const SizedBox(width: 15),*/
                  //const SizedBox(width: 12),
                  setUpWidget(attr, i),
                  //const SizedBox(width: 10),
                  /*IconButtonWithIndex(
                  iconSize: 20,
                  icon: SvgPicture.asset(
                      "assets/fronus/batch_search.svg", width: 20,
                      height: 20,
                      color: attr.operationMode != 2 ? SSLi.themeOtherItemColor(
                          'theme_text') : SSLi.themeOtherItemColor('light')),
                  onPressed: attr.operationMode != 2 ? (index) async {
                    /*popup = dialogWaiting(S.of(context).reading);
                    Navigator.push(buildContext, popup!);
                    popup?.isPush = true;
                    read(index, false, index);*/
                    WaitingContent? content;
                    content = WaitingContent(title: S.of(context).reading,featureGroup: widget._featureGroup, deviceInfo: widget._deviceInfo, requestEnd: requestEnd, count: count, fail: fail, result: result, valueList: valueList,
                      refresh: (){
                      print("refresh invoked");
                      //requestEnd = content!.requestEnd;
                      //count = content!.count;
                      //fail = content!.fail;
                      //result = content!.result;
                      if(mounted) setState(() {});
                      },unlock: (){requestEnd = true;},
                      index: index, isBatch: false, total: index,
                      rw: "read",
                    );
                    showDialog(context: context, builder: (BuildContext context){
                      return AlertDialog(
                        content: content,
                        contentPadding: const EdgeInsets.only(
                          left: 24.0,
                          top: 20.0,
                          right: 24.0,
                          bottom: 0,
                        ),
                        actions: [TextButton(onPressed: (){
                          Navigator.of(context).pop();
                        }, child: Text(S.of(context).close))],
                      );
                    });
                  } : null,
                  index: i,
                ),
                IconButtonWithIndex(
                  iconSize: 20,
                  icon: SvgPicture.asset(
                      "assets/fronus/batch_delivery.svg", width: 20,
                      height: 20,
                      color: attr.operationMode != 1 ? SSLi.themeOtherItemColor(
                          'theme_text') : SSLi.themeOtherItemColor('light')),
                  onPressed: attr.operationMode != 1 ? (index) async {
                    if (valueList[index] == "") {
                      WidgetHelper.showAlertDialog(
                          context, S.of(context).please_enter_value, null).then((value) {
                        return;
                      });
                    } else {
                      WidgetHelper.showConfirmDialog(context, S
                          .of(context)
                          .sure_to_continue_modify, S
                          .of(context)
                          .after_confirmation_to_modify).then((value) {
                        if (value == true) {
                          if (valueList[index] == "") {
                            WidgetHelper.showAlertDialog(context, S.of(context).ensure_one_data, null);
                            return;
                          }
                          /*popup = dialogWaiting(S.of(context).deliverying);
                          Navigator.push(buildContext, popup!);
                          popup?.isPush = true;
                          write(index, false, index);*/
                          WaitingContent? content;
                          content = WaitingContent(title: S.of(context).deliverying,featureGroup: widget._featureGroup, deviceInfo: widget._deviceInfo, requestEnd: requestEnd, count: count, fail: fail, result: result, valueList: valueList,
                            refresh: (){
                              print("refresh invoked");
                              //requestEnd = content!.requestEnd;
                              //count = content!.count;
                              //fail = content!.fail;
                              //result = content!.result;
                              if(mounted) setState(() {});
                            },unlock: (){requestEnd = true;},
                            index: index, isBatch: false, total: index,
                            rw:'write'
                          );
                          showDialog(context: context, builder: (BuildContext context){
                            return AlertDialog(
                              content: content,
                              contentPadding: const EdgeInsets.only(
                                left: 24.0,
                                top: 20.0,
                                right: 24.0,
                                bottom: 0,
                              ),
                              actions: [TextButton(onPressed: (){
                                Navigator.of(context).pop();
                              }, child: Text(S.of(context).close))],
                            );
                          });
                        }
                      });
                    }
                  } : null,
                  index: i,
                ),*/
                  ElevatedButtonWithIndex(
                    width: 36,
                    height: 36,
                    icon: SvgPicture.asset("assets/fronus/batch_search.svg",
                        width: 20,
                        height: 20,
                        color: attr.operationMode != 2
                            ? SSLi.themeOtherItemColor('button_text')
                            : SSLi.themeOtherItemColor('light')),
                    onPressed: attr.operationMode != 2
                        ? (index) async {
                            /*popup = dialogWaiting(S.of(context).reading);
                    Navigator.push(buildContext, popup!);
                    popup?.isPush = true;
                    read(index, false, index);*/
                            if (!requestEnd) {
                              WidgetHelper.showAlertDialog(buildContext,
                                  S.of(context).try_again_later, null);
                              return;
                            }
                            requestEnd = false;
                            _nearWaitingContent? content;
                            content = _nearWaitingContent(
                              title: S.of(context).reading,
                              featureGroup: widget.featureGroup,
                              requestEnd: requestEnd,
                              count: count,
                              fail: fail,
                              result: result,
                              valueList: valueList,
                              refresh: () {
                                print("refresh invoked");
                                //requestEnd = content!.requestEnd;
                                //count = content!.count;
                                //fail = content!.fail;
                                //result = content!.result;
                                if (mounted) setState(() {});
                              },
                              unlock: () {
                                requestEnd = true;
                              },
                              index: index,
                              isBatch: false,
                              total: index,
                              rw: "read",
                              verCodeL: widget.verCodeL,
                              protocolNoL: widget.protocolNoL,
                              dtuId: widget.dtuId,
                              baudRateL: widget.baudRateL,
                              dataBitL: widget.dataBitL,
                              parityBitL: widget.parityBitL,
                              stopBitL: widget.stopBitL,
                              applyAndWait: widget.applyAndWait,
                              threadComplete: widget.threadComplete,
                            );
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: content,
                                    contentPadding: const EdgeInsets.only(
                                      left: 24.0,
                                      top: 20.0,
                                      right: 24.0,
                                      bottom: 0,
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(S.of(context).close))
                                    ],
                                  );
                                }).then((value) {
                              if (mounted) setState(() {});
                            });
                          }
                        : null,
                    index: i,
                  ),
                  SizedBox(
                    height: 36,
                    child: VerticalDivider(
                      color: SSLi.themeOtherItemColor('button_text')
                          .withOpacity(0.85),
                      width: 0.25,
                    ),
                  ),
                  ElevatedButtonWithIndex(
                    width: 36,
                    height: 36,
                    icon: SvgPicture.asset("assets/fronus/batch_delivery.svg",
                        width: 20,
                        height: 20,
                        color: attr.operationMode != 1
                            ? SSLi.themeOtherItemColor('button_text')
                            : SSLi.themeOtherItemColor('light')),
                    onPressed: attr.operationMode != 1
                        ? (index) async {
                            if (valueList[index] == "") {
                              WidgetHelper.showAlertDialog(context,
                                      S.of(context).please_enter_value, null)
                                  .then((value) {
                                return;
                              });
                            } else {
                              WidgetHelper.showConfirmDialog(
                                      context,
                                      S.of(context).sure_to_continue_modify,
                                      S
                                          .of(context)
                                          .after_confirmation_to_modify)
                                  .then((value) {
                                if (value == true) {
                                  if (valueList[index] == "") {
                                    WidgetHelper.showAlertDialog(context,
                                        S.of(context).ensure_one_data, null);
                                    return;
                                  }
                                  /*popup = dialogWaiting(S.of(context).deliverying);
                          Navigator.push(buildContext, popup!);
                          popup?.isPush = true;
                          write(index, false, index);*/
                                  if (!requestEnd) {
                                    WidgetHelper.showAlertDialog(buildContext,
                                        S.of(context).try_again_later, null);
                                    return;
                                  }
                                  requestEnd = false;
                                  _nearWaitingContent? content;
                                  content = _nearWaitingContent(
                                    title: S.of(context).deliverying,
                                    featureGroup: widget.featureGroup,
                                    requestEnd: requestEnd,
                                    count: count,
                                    fail: fail,
                                    result: result,
                                    valueList: valueList,
                                    refresh: () {
                                      print("refresh invoked");
                                      //requestEnd = content!.requestEnd;
                                      //count = content!.count;
                                      //fail = content!.fail;
                                      //result = content!.result;
                                      if (mounted) setState(() {});
                                    },
                                    unlock: () {
                                      requestEnd = true;
                                    },
                                    index: index,
                                    isBatch: false,
                                    total: index,
                                    rw: 'write',
                                    verCodeL: widget.verCodeL,
                                    protocolNoL: widget.protocolNoL,
                                    dtuId: widget.dtuId,
                                    baudRateL: widget.baudRateL,
                                    dataBitL: widget.dataBitL,
                                    parityBitL: widget.parityBitL,
                                    stopBitL: widget.stopBitL,
                                    applyAndWait: widget.applyAndWait,
                                    threadComplete: widget.threadComplete,
                                  );
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: content,
                                          contentPadding: const EdgeInsets.only(
                                            left: 24.0,
                                            top: 20.0,
                                            right: 24.0,
                                            bottom: 0,
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child:
                                                    Text(S.of(context).close))
                                          ],
                                        );
                                      }).then((value) {
                                    if (mounted) setState(() {});
                                  });
                                }
                              });
                            }
                          }
                        : null,
                    index: i,
                  ),
                ],
              ),
            ],
          ),
        );
        //columnList.add(const Divider(height: 1));
        columnList.add(SizedBox(
          height: 22,
        ));
        if (i % 10 == 9 || i == widget.featureGroup!.attributes.length - 1) {
          ListArr.add(ListView(
            children: columnList,
          ));
          columnList = [];
        }
      }
    }
    return ListArr;
  }

  List<Widget> GridViewItems() {
    List<Widget> ListArr = [];
    if (widget.featureGroup?.attributes.isNotEmpty == true) {
      List<Widget> columnList = [];
      for (int i = 0; i < widget.featureGroup!.attributes.length; i++) {
        FeatureAttribute attr = widget.featureGroup!.attributes[i];
        columnList.add(
          LayoutBuilder(builder: (buildContext, constraintType) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[300]!,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: constraintType.maxHeight * (30 / 110),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: setUpWidget(attr, i)),
                      /*
                        ElevatedButtonWithIndex(
                          width: 36,
                          height: 36,
                          icon: SvgPicture.asset(
                              "assets/fronus/batch_search.svg",
                              width: 20,
                              height: 20,
                              color: attr.operationMode != 2 ? SSLi.themeOtherItemColor(
                                  'button_text') : SSLi.themeOtherItemColor('light')),
                          onPressed: attr.operationMode != 2 ? (index) async {
                            /*popup = dialogWaiting(S.of(context).reading);
                          Navigator.push(buildContext, popup!);
                          popup?.isPush = true;
                          read(index, false, index);*/
                            if (!requestEnd) {
                              WidgetHelper.showAlertDialog(buildContext, S.of(context).try_again_later, null);
                              return;
                            }
                            requestEnd = false;
                            _nearWaitingContent? content;
                            content = _nearWaitingContent(title: S.of(context).reading,featureGroup: widget.featureGroup, requestEnd: requestEnd, count: count, fail: fail, result: result, valueList: valueList,
                              refresh: (){
                                print("refresh invoked");
                                //requestEnd = content!.requestEnd;
                                //count = content!.count;
                                //fail = content!.fail;
                                //result = content!.result;
                                if(mounted) setState(() {});
                              },unlock: (){requestEnd = true;},
                              index: index, isBatch: false, total: index,
                              rw: "read", verCodeL: widget.verCodeL, protocolNoL: widget.protocolNoL, dtuId: widget.dtuId,
                              baudRateL: widget.baudRateL, dataBitL: widget.dataBitL, parityBitL: widget.parityBitL, stopBitL: widget.stopBitL,
                              applyAndWait: widget.applyAndWait, threadComplete: widget.threadComplete,
                            );
                            showDialog(context: context, builder: (BuildContext context){
                              return AlertDialog(
                                content: content,
                                contentPadding: const EdgeInsets.only(
                                  left: 24.0,
                                  top: 20.0,
                                  right: 24.0,
                                  bottom: 0,
                                ),
                                actions: [TextButton(onPressed: (){
                                  Navigator.of(context).pop();
                                }, child: Text(S.of(context).close))],
                              );
                            }).then((value) {
                              if (mounted) setState(() {});
                            });
                          } : null,
                          index: i,
                        ),
                        SizedBox(
                          height: 36,
                          child: VerticalDivider(
                            color: SSLi.themeOtherItemColor('button_text').withOpacity(0.85),
                            width: 0.25,
                          ),
                        ),
                        ElevatedButtonWithIndex(
                          width: 36,
                          height: 36,
                          icon: SvgPicture.asset(
                              "assets/fronus/batch_delivery.svg",
                              width: 20,
                              height: 20,
                              color: attr.operationMode != 1 ? SSLi.themeOtherItemColor(
                                  'button_text') : SSLi.themeOtherItemColor('light')),
                          onPressed: attr.operationMode != 1 ? (index) async {
                            if (valueList[index] == "") {
                              WidgetHelper.showAlertDialog(
                                  context, S.of(context).please_enter_value, null).then((value) {
                                return;
                              });
                            } else {
                              WidgetHelper.showConfirmDialog(context, S
                                  .of(context)
                                  .sure_to_continue_modify, S
                                  .of(context)
                                  .after_confirmation_to_modify).then((value) {
                                if (value == true) {
                                  if (valueList[index] == "") {
                                    WidgetHelper.showAlertDialog(context, S.of(context).ensure_one_data, null);
                                    return;
                                  }
                                  /*popup = dialogWaiting(S.of(context).deliverying);
                                Navigator.push(buildContext, popup!);
                                popup?.isPush = true;
                                write(index, false, index);*/
                                  if (!requestEnd) {
                                    WidgetHelper.showAlertDialog(buildContext, S.of(context).try_again_later, null);
                                    return;
                                  }
                                  requestEnd = false;
                                  _nearWaitingContent? content;
                                  content = _nearWaitingContent(title: S.of(context).deliverying,featureGroup: widget.featureGroup, requestEnd: requestEnd, count: count, fail: fail, result: result, valueList: valueList,
                                    refresh: (){
                                      print("refresh invoked");
                                      //requestEnd = content!.requestEnd;
                                      //count = content!.count;
                                      //fail = content!.fail;
                                      //result = content!.result;
                                      if(mounted) setState(() {});
                                    },unlock: (){requestEnd = true;},
                                    index: index, isBatch: false, total: index,
                                    rw:'write', verCodeL: widget.verCodeL, protocolNoL: widget.protocolNoL, dtuId: widget.dtuId,
                                    baudRateL: widget.baudRateL, dataBitL: widget.dataBitL, parityBitL: widget.parityBitL, stopBitL: widget.stopBitL,
                                    applyAndWait: widget.applyAndWait, threadComplete: widget.threadComplete,
                                  );
                                  showDialog(context: context, builder: (BuildContext context){
                                    return AlertDialog(
                                      content: content,
                                      contentPadding: const EdgeInsets.only(
                                        left: 24.0,
                                        top: 20.0,
                                        right: 24.0,
                                        bottom: 0,
                                      ),
                                      actions: [TextButton(onPressed: (){
                                        Navigator.of(context).pop();
                                      }, child: Text(S.of(context).close))],
                                    );
                                  }).then((value) {
                                    if (mounted) setState(() {});
                                  });
                                }
                              });
                            }
                          } : null,
                          index: i,
                        ),
                        */
                    ],
                  ),
                  SizedBox(
                    height: constraintType.maxHeight * (8 / 110),
                  ),
                  Center(
                    child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(children: [
                          TextSpan(
                              text: attr.name +
                                  (attr.unit == null || attr.unit == ""
                                      ? ""
                                      : "(${attr.unit!})"),
                              style: SSLiTextStyles.pingFangBold(
                                  fontSize: 13,
                                  color: const Color(0xFF999999))),
                        ])),
                  ),
                ],
              ),
            );
          }),
        );
        if (i % 10 == 9 || i == widget.featureGroup!.attributes.length - 1) {
          ListArr.add(Padding(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * (15 / 375),
                right: MediaQuery.of(context).size.width * (15 / 375)),
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: MediaQuery.of(context).size.width * (15 / 375),
                crossAxisSpacing:
                    MediaQuery.of(context).size.width * (15 / 375),
                childAspectRatio: 165 / 110, // 宽度比高度
              ),
              children: columnList,
            ),
          ));
          columnList = [];
        }
      }
    }
    return ListArr;
  }

  Widget setUpWidget(FeatureAttribute attr, int index) {
    if (attr.operationMode == 1) {
      return Center(
        child: Text(
          valueList[index].isNotEmpty ? valueList[index] : "    ",
          style: SSLiTextStyles.pingFangSemibold(
              fontSize: 19, color: const Color(0xFF333333)),
        ),
      );
    }
    if (attr.valueType == 0) {
      TextEditingController textController = TextEditingController();
      textController.text = valueList[index];
      return GestureDetector(
        onTap: () {
          WidgetHelper.showHintDialog(
              context,
              valueList[index],
              widget.featureGroup!.attributes[index].name,
              widget.featureGroup!.attributes[index].hint,
              (str) {},
              null, (str) {
            WidgetHelper.showConfirmDialog(
                    context,
                    S.of(context).sure_to_continue_modify,
                    S.of(context).after_confirmation_to_modify)
                .then(
              (value) async {
                if (value == true) {
                  valueList[index] = str;
                  textController.text = str;
                  if (valueList[index] == "") {
                    WidgetHelper.showAlertDialog(
                        context, S.of(context).ensure_one_data, null);
                    return;
                  }
                  /*popup = dialogWaiting(S.of(context).deliverying);
                      Navigator.push(buildContext, popup!);
                      popup?.isPush = true;
                      write(index, false, index);*/
                  if (!requestEnd) {
                    WidgetHelper.showAlertDialog(
                        buildContext, S.of(context).try_again_later, null);
                    return;
                  }
                  requestEnd = false;
                  _nearWaitingContent? content;
                  content = _nearWaitingContent(
                    title: S.of(context).deliverying,
                    featureGroup: widget.featureGroup,
                    requestEnd: requestEnd,
                    count: count,
                    fail: fail,
                    result: result,
                    valueList: valueList,
                    refresh: () {
                      print("refresh invoked");
                      //requestEnd = content!.requestEnd;
                      //count = content!.count;
                      //fail = content!.fail;
                      //result = content!.result;
                      if (mounted) setState(() {});
                    },
                    unlock: () {
                      requestEnd = true;
                    },
                    index: index,
                    isBatch: false,
                    total: index,
                    rw: 'write',
                    verCodeL: widget.verCodeL,
                    protocolNoL: widget.protocolNoL,
                    dtuId: widget.dtuId,
                    baudRateL: widget.baudRateL,
                    dataBitL: widget.dataBitL,
                    parityBitL: widget.parityBitL,
                    stopBitL: widget.stopBitL,
                    applyAndWait: widget.applyAndWait,
                    threadComplete: widget.threadComplete,
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: content,
                          contentPadding: const EdgeInsets.only(
                            left: 24.0,
                            top: 20.0,
                            right: 24.0,
                            bottom: 0,
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(S.of(context).close))
                          ],
                        );
                      }).then((value) {
                    if (mounted) setState(() {});
                  });
                }
              },
            );
          });
        },
        child: Center(
          child: Text(
            valueList[index].isNotEmpty ? valueList[index] : "    ",
            style: SSLiTextStyles.pingFangSemibold(
                fontSize: 19, color: const Color(0xFF333333)),
          ),
        ),
      );
    } else if (attr.valueType == 1) {
      if (valueList[index] != "" && delta[index] == null) {
        delta[index] = 1.0;
        int indexOfPoint = valueList[index].indexOf('.');
        if (indexOfPoint != -1) {
          decimalPlace[index] = valueList[index].length - (indexOfPoint + 1);
          try {
            delta[index] = double.parse(pow(
                    0.1, valueList[index].length - (indexOfPoint + 1))
                .toStringAsFixed(valueList[index].length - (indexOfPoint + 1)));
          } catch (e) {}
        }
      }
      return NumberControllerWidget(
        content: valueList[index],
        // height: 36 + 0.5 + 0.5,
        // iconWidth: 40,
        // width: (MediaQuery.of(context).size.width - 36 - 36 - 12 - 12) - 80 - 1,
        hint: widget.featureGroup!.attributes[index].hint,
        name: widget.featureGroup!.attributes[index].name,
        numText: valueList[index],
        updateValueChanged: (str, isDelivery) {
          if (!isDelivery) {
            // 点击加减号时调用
            timer?.cancel();
            if (str != null) if (str is! String) {
              valueList[index] = str.toString();
              if (str is Decimal &&
                  delta[index] != 1.0 &&
                  decimalPlace[index] != null)
                valueList[index] = str.toStringAsFixed(decimalPlace[index]!);
            } else {
              valueList[index] = str;
            }
            if (mounted) setState(() {});
            timer = Timer(const Duration(seconds: 3), () async {
              print("自动下发数值");
              if (valueList[index] == "") {
                WidgetHelper.showAlertDialog(
                        context, S.of(context).please_enter_value, null)
                    .then((value) {
                  return;
                });
              } else {
                if (true) {
                  if (valueList[index] == "") {
                    WidgetHelper.showAlertDialog(
                        context, S.of(context).ensure_one_data, null);
                    return;
                  }
                  /*popup = dialogWaiting(S.of(context).deliverying);
                                Navigator.push(buildContext, popup!);
                                popup?.isPush = true;
                                write(index, false, index);*/
                  if (!requestEnd) {
                    WidgetHelper.showAlertDialog(
                        buildContext, S.of(context).try_again_later, null);
                    return;
                  }
                  requestEnd = false;
                  _nearWaitingContent? content;
                  content = _nearWaitingContent(
                    title: S.of(context).deliverying,
                    featureGroup: widget.featureGroup,
                    requestEnd: requestEnd,
                    count: count,
                    fail: fail,
                    result: result,
                    valueList: valueList,
                    refresh: () {
                      print("refresh invoked");
                      //requestEnd = content!.requestEnd;
                      //count = content!.count;
                      //fail = content!.fail;
                      //result = content!.result;
                      if (mounted) setState(() {});
                    },
                    unlock: () {
                      requestEnd = true;
                    },
                    index: index,
                    isBatch: false,
                    total: index,
                    rw: 'write',
                    verCodeL: widget.verCodeL,
                    protocolNoL: widget.protocolNoL,
                    dtuId: widget.dtuId,
                    baudRateL: widget.baudRateL,
                    dataBitL: widget.dataBitL,
                    parityBitL: widget.parityBitL,
                    stopBitL: widget.stopBitL,
                    applyAndWait: widget.applyAndWait,
                    threadComplete: widget.threadComplete,
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: content,
                          contentPadding: const EdgeInsets.only(
                            left: 24.0,
                            top: 20.0,
                            right: 24.0,
                            bottom: 0,
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(S.of(context).close))
                          ],
                        );
                      }).then((value) {
                    if (mounted) setState(() {});
                  });
                }
              }
            });
            return;
          }
          WidgetHelper.showConfirmDialog(
                  context,
                  S.of(context).sure_to_continue_modify,
                  S.of(context).after_confirmation_to_modify)
              .then(
            (value) async {
              if (value == true) {
                if (str != null) if (str is! String) {
                  valueList[index] = str.toString();
                  if (str is Decimal &&
                      delta[index] != 1.0 &&
                      decimalPlace[index] != null)
                    valueList[index] =
                        str.toStringAsFixed(decimalPlace[index]!);
                } else {
                  valueList[index] = str;
                }
                if (valueList[index] == "") {
                  WidgetHelper.showAlertDialog(
                      context, S.of(context).ensure_one_data, null);
                  return;
                }
                if (mounted) {
                  setState(() {});
                } //部分地修复输入法bug
                /*popup = dialogWaiting(S.of(context).deliverying);
                Navigator.push(buildContext, popup!);
                popup?.isPush = true;
                write(index, false, index);*/
                if (!requestEnd) {
                  WidgetHelper.showAlertDialog(
                      buildContext, S.of(context).try_again_later, null);
                  return;
                }
                requestEnd = false;
                _nearWaitingContent? content;
                content = _nearWaitingContent(
                  title: S.of(context).deliverying,
                  featureGroup: widget.featureGroup,
                  requestEnd: requestEnd,
                  count: count,
                  fail: fail,
                  result: result,
                  valueList: valueList,
                  refresh: () {
                    print("refresh invoked");
                    //requestEnd = content!.requestEnd;
                    //count = content!.count;
                    //fail = content!.fail;
                    //result = content!.result;
                    if (mounted) setState(() {});
                  },
                  unlock: () {
                    requestEnd = true;
                  },
                  index: index,
                  isBatch: false,
                  total: index,
                  rw: 'write',
                  verCodeL: widget.verCodeL,
                  protocolNoL: widget.protocolNoL,
                  dtuId: widget.dtuId,
                  baudRateL: widget.baudRateL,
                  dataBitL: widget.dataBitL,
                  parityBitL: widget.parityBitL,
                  stopBitL: widget.stopBitL,
                  applyAndWait: widget.applyAndWait,
                  threadComplete: widget.threadComplete,
                );
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: content,
                        contentPadding: const EdgeInsets.only(
                          left: 24.0,
                          top: 20.0,
                          right: 24.0,
                          bottom: 0,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(S.of(context).close))
                        ],
                      );
                    }).then((value) {
                  if (mounted) setState(() {});
                });
              }
            },
          );
        },
        delta: delta[index],
      );
    } else if (attr.valueType == 2) {
      if (valueList[index] == "" || valueList[index] == "null") {
      } else {
        if (attr.doesExistValue(valueList[index])) {
        } else {
          // 清除非法数据
          valueList[index] = "";
        }
      }
      return Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              dynamic v = valueList[index];
              showModalBottomSheet(
                context: context,
                enableDrag: false,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            attr.name,
                            style: SSLiTextStyles.pingFangSemibold(
                                fontSize: 18, color: const Color(0xFF333333)),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Flexible(
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter stateSetter) {
                            return SingleChildScrollView(
                              child: Column(
                                children: List.generate(
                                    attr.enumValueList.length, (i) {
                                  attr.enumValueList[i];
                                  return InkWell(
                                    onTap: (attr.enumValueList[i].value == v)
                                        ? null
                                        : () {
                                            v = attr.enumValueList[i].value;
                                            stateSetter(() {});
                                          },
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: (attr.enumValueList[i].value ==
                                                v)
                                            ? Theme.of(context).highlightColor
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                          child: Text(
                                        attr.enumValueList[i].text,
                                        style: SSLiTextStyles.pingFangSemibold(
                                            fontSize: 16,
                                            color: const Color(0xFF333333)),
                                      )),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                minimumSize: const Size(150, 42),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                S.of(context).cancel /*取消*/,
                                style: SSLiTextStyles.pingFangBold(
                                    fontSize: 16,
                                    color: const Color(0xFF666666)),
                              ),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // valueList[index] = v;
                                // if(mounted) setState((){});
                                if (v == "") {
                                  WidgetHelper.showAlertDialog(
                                          context,
                                          S.of(context).please_enter_value,
                                          null)
                                      .then((value) {
                                    return;
                                  });
                                } else {
                                  WidgetHelper.showConfirmDialog(
                                          context,
                                          S.of(context).sure_to_continue_modify,
                                          S
                                              .of(context)
                                              .after_confirmation_to_modify)
                                      .then((value) {
                                    if (value == true) {
                                      if (v == "") {
                                        WidgetHelper.showAlertDialog(
                                            context,
                                            S.of(context).ensure_one_data,
                                            null);
                                        return;
                                      }
                                      if (!requestEnd) {
                                        WidgetHelper.showAlertDialog(
                                            buildContext,
                                            S.of(context).try_again_later,
                                            null);
                                        return;
                                      }

                                      valueList[index] = v;
                                      if (mounted) setState(() {});

                                      requestEnd = false;
                                      _nearWaitingContent? content;
                                      content = _nearWaitingContent(
                                        title: S.of(context).deliverying,
                                        featureGroup: widget.featureGroup,
                                        requestEnd: requestEnd,
                                        count: count,
                                        fail: fail,
                                        result: result,
                                        valueList: valueList,
                                        refresh: () {
                                          print("refresh invoked");
                                          //requestEnd = content!.requestEnd;
                                          //count = content!.count;
                                          //fail = content!.fail;
                                          //result = content!.result;
                                          if (mounted) setState(() {});
                                        },
                                        unlock: () {
                                          requestEnd = true;
                                        },
                                        index: index,
                                        isBatch: false,
                                        total: index,
                                        rw: 'write',
                                        verCodeL: widget.verCodeL,
                                        protocolNoL: widget.protocolNoL,
                                        dtuId: widget.dtuId,
                                        baudRateL: widget.baudRateL,
                                        dataBitL: widget.dataBitL,
                                        parityBitL: widget.parityBitL,
                                        stopBitL: widget.stopBitL,
                                        applyAndWait: widget.applyAndWait,
                                        threadComplete: widget.threadComplete,
                                      );
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: content,
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                left: 24.0,
                                                top: 20.0,
                                                right: 24.0,
                                                bottom: 0,
                                              ),
                                              actions: [
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text(
                                                        S.of(context).close))
                                              ],
                                            );
                                          }).then((value) {
                                        if (mounted) setState(() {});
                                      });
                                    }
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                side: BorderSide.none,
                                backgroundColor: const Color(0xFF1B64F7),
                                minimumSize: const Size(150, 42),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                S.of(context).ascertain,
                                style: SSLiTextStyles.pingFangBold(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Ink(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: Text(
                    ((valueList[index] == "" || valueList[index] == "null")
                            ? null
                            : attr.getEnumText(valueList[index])) ??
                        "",
                    style: SSLiTextStyles.pingFangSemibold(
                        fontSize: 19, color: const Color(0xFF333333)),
                  )),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF333333),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return Stack(
        children: [
          DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
            value: valueList[index] == "" || valueList[index] == "null"
                ? null
                : valueList[index],
            isExpanded: true,
            isDense: true,
            dropdownDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(0)),
              border: Border.all(width: 0.5, color: Colors.black12),
            ),
            items: showCombStateItems(attr),
            dropdownMaxHeight: 250,
            dropdownElevation: 1,
            customItemsHeights: showCombItemHeights(attr, 12),
            onChanged: (value) {
              if (value != null) valueList[index] = value;
              if (mounted) setState(() {});
            },
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF333333),
            ),
          )),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ((valueList[index] == "" || valueList[index] == "null")
                                ? null
                                : attr.getEnumText(valueList[index])) ??
                            "",
                        style: SSLiTextStyles.pingFangSemibold(
                            fontSize: 19, color: const Color(0xFF333333)),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF333333),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (attr.valueType == 3) {
      TextEditingController textController = TextEditingController();
      textController.text = valueList[index];
      return GestureDetector(
        onTap: () async {
          /*
          DateTime now = DateTime.now();
          DateTime? pickedDateTime = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          */
          DateTime? initDate;
          try {
            initDate = DateTime.parse(valueList[index]);
          } catch (e) {}
          DateTime? pickedDateTime =
              await WidgetHelper.showDatePickerBottomSheet(context,
                  initDate ?? DateTime.now(), DatePickerMode2.yearMonthDay);
          if (pickedDateTime == null) return;
          print(pickedDateTime);
          String v = pickedDateTime.toString().replaceAll(" 00:00:00.000", "");
          if (v == "") {
            WidgetHelper.showAlertDialog(
                    context, S.of(context).please_enter_value, null)
                .then((value) {
              return;
            });
          } else {
            WidgetHelper.showConfirmDialog(
                    context,
                    S.of(context).sure_to_continue_modify,
                    S.of(context).after_confirmation_to_modify)
                .then((value) {
              if (value == true) {
                if (v == "") {
                  WidgetHelper.showAlertDialog(
                      context, S.of(context).ensure_one_data, null);
                  return;
                }
                if (!requestEnd) {
                  WidgetHelper.showAlertDialog(
                      buildContext, S.of(context).try_again_later, null);
                  return;
                }

                valueList[index] = v;
                textController.text = v;
                if (mounted) setState(() {});

                requestEnd = false;
                _nearWaitingContent? content;
                content = _nearWaitingContent(
                  title: S.of(context).deliverying,
                  featureGroup: widget.featureGroup,
                  requestEnd: requestEnd,
                  count: count,
                  fail: fail,
                  result: result,
                  valueList: valueList,
                  refresh: () {
                    print("refresh invoked");
                    //requestEnd = content!.requestEnd;
                    //count = content!.count;
                    //fail = content!.fail;
                    //result = content!.result;
                    if (mounted) setState(() {});
                  },
                  unlock: () {
                    requestEnd = true;
                  },
                  index: index,
                  isBatch: false,
                  total: index,
                  rw: 'write',
                  verCodeL: widget.verCodeL,
                  protocolNoL: widget.protocolNoL,
                  dtuId: widget.dtuId,
                  baudRateL: widget.baudRateL,
                  dataBitL: widget.dataBitL,
                  parityBitL: widget.parityBitL,
                  stopBitL: widget.stopBitL,
                  applyAndWait: widget.applyAndWait,
                  threadComplete: widget.threadComplete,
                );
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: content,
                        contentPadding: const EdgeInsets.only(
                          left: 24.0,
                          top: 20.0,
                          right: 24.0,
                          bottom: 0,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(S.of(context).close))
                        ],
                      );
                    }).then((value) {
                  if (mounted) setState(() {});
                });
              }
            });
          }
        },
        child: Center(
          child: Text(
            valueList[index].isNotEmpty ? valueList[index] : "    ",
            style: SSLiTextStyles.pingFangSemibold(
                fontSize: 19, color: const Color(0xFF333333)),
          ),
        ),
      );
    } else if (attr.valueType == 4) {
      TextEditingController textController = TextEditingController();
      textController.text = valueList[index];
      return GestureDetector(
        onTap: () async {
          DateTime now = DateTime.now();
          DateTime pickedDateTime =
              DateTime(1970, 1, 1, now.hour, now.minute, now.second);
          bool confirm = false;
          await showModalBottomSheet(
            context: context,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            builder: (_) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        attr.name,
                        style: SSLiTextStyles.pingFangSemibold(
                            fontSize: 18, color: const Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.light,
                      ),
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hms,
                        initialTimerDuration: Duration(
                          hours: now.hour,
                          minutes: now.minute,
                          seconds: now.second,
                        ),
                        onTimerDurationChanged: (Duration duration) {
                          pickedDateTime = pickedDateTime.copyWith(
                            hour: duration.inHours,
                            minute: duration.inMinutes % 60,
                            second: duration.inSeconds % 60,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(21),
                          ),
                          minimumSize: const Size(150, 42),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          S.of(context).cancel /*取消*/,
                          style: SSLiTextStyles.pingFangBold(
                              fontSize: 16, color: const Color(0xFF666666)),
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      OutlinedButton(
                        onPressed: () {
                          confirm = true;
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(21),
                          ),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFF1B64F7),
                          minimumSize: const Size(150, 42),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          S.of(context).ascertain,
                          style: SSLiTextStyles.pingFangBold(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              );
            },
          );
          if (!confirm) return;
          print(pickedDateTime);
          String v =
              pickedDateTime.toString().replaceAll(".000", "").substring(11);
          if (v == "") {
            WidgetHelper.showAlertDialog(
                    context, S.of(context).please_enter_value, null)
                .then((value) {
              return;
            });
          } else {
            WidgetHelper.showConfirmDialog(
                    context,
                    S.of(context).sure_to_continue_modify,
                    S.of(context).after_confirmation_to_modify)
                .then((value) {
              if (value == true) {
                if (v == "") {
                  WidgetHelper.showAlertDialog(
                      context, S.of(context).ensure_one_data, null);
                  return;
                }
                if (!requestEnd) {
                  WidgetHelper.showAlertDialog(
                      buildContext, S.of(context).try_again_later, null);
                  return;
                }

                valueList[index] = v;
                textController.text = v;
                if (mounted) setState(() {});

                requestEnd = false;
                _nearWaitingContent? content;
                content = _nearWaitingContent(
                  title: S.of(context).deliverying,
                  featureGroup: widget.featureGroup,
                  requestEnd: requestEnd,
                  count: count,
                  fail: fail,
                  result: result,
                  valueList: valueList,
                  refresh: () {
                    print("refresh invoked");
                    //requestEnd = content!.requestEnd;
                    //count = content!.count;
                    //fail = content!.fail;
                    //result = content!.result;
                    if (mounted) setState(() {});
                  },
                  unlock: () {
                    requestEnd = true;
                  },
                  index: index,
                  isBatch: false,
                  total: index,
                  rw: 'write',
                  verCodeL: widget.verCodeL,
                  protocolNoL: widget.protocolNoL,
                  dtuId: widget.dtuId,
                  baudRateL: widget.baudRateL,
                  dataBitL: widget.dataBitL,
                  parityBitL: widget.parityBitL,
                  stopBitL: widget.stopBitL,
                  applyAndWait: widget.applyAndWait,
                  threadComplete: widget.threadComplete,
                );
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: content,
                        contentPadding: const EdgeInsets.only(
                          left: 24.0,
                          top: 20.0,
                          right: 24.0,
                          bottom: 0,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(S.of(context).close))
                        ],
                      );
                    }).then((value) {
                  if (mounted) setState(() {});
                });
              }
            });
          }
        },
        child: Center(
          child: Text(valueList[index].isNotEmpty ? valueList[index] : "    ",
              style: SSLiTextStyles.pingFangSemibold(
                  fontSize: 19, color: const Color(0xFF333333))),
        ),
      );
    } else if (attr.valueType == 5) {
      TextEditingController textController = TextEditingController();
      textController.text = valueList[index];
      return GestureDetector(
        onTap: () async {
          DateTime now = DateTime.now();
          DateTime? pickedDateTime = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDateTime == null) return;
          pickedDateTime = pickedDateTime.copyWith(
            hour: now.hour,
            minute: now.minute,
            second: now.second,
          );
          print(pickedDateTime);
          if (context.mounted) {
          } else {
            return;
          }
          bool cancel = false;
          await showCupertinoModalPopup(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return AlertDialog(
                content: SizedBox(
                  height: 225,
                  width: 300,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Brightness.light,
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: Duration(
                        hours: now.hour,
                        minutes: now.minute,
                        seconds: now.second,
                      ),
                      onTimerDurationChanged: (Duration duration) {
                        pickedDateTime = pickedDateTime!.copyWith(
                          hour: duration.inHours,
                          minute: duration.inMinutes % 60,
                          second: duration.inSeconds % 60,
                        );
                      },
                    ),
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        cancel = true;
                      },
                      child: Text(S.of(context).cancel /*取消*/)),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(S.of(context).ascertain) /*确定*/),
                ],
                actionsPadding: EdgeInsets.zero,
              );
            },
          );
          if (cancel) return;
          print(pickedDateTime);
          setState(() {
            valueList[index] = pickedDateTime.toString().replaceAll(".000", "");
            textController.text =
                pickedDateTime.toString().replaceAll(".000", "");
          });
        },
        child: Center(
          child: Text(
            valueList[index].isNotEmpty ? valueList[index] : "    ",
            style: SSLiTextStyles.pingFangSemibold(
                fontSize: 19, color: const Color(0xFF333333)),
          ),
        ),
      );
    }
    return const Text("");
  }

  List<DropdownMenuItem<String>> showCombStateItems(FeatureAttribute attr) {
    List<DropdownMenuItem<String>> list = [];
    for (int i = 0; i < attr.enumValueList.length; i++) {
      AttributeEnumValue value = attr.enumValueList[i];
      list.add(DropdownMenuItem(
          value: value.value,
          child: Text(
            value.text == "" || value.text == "null" ? "" : value.text,
            textAlign: TextAlign.center,
            style: SSLiTextStyles.pingFangSemibold(
                fontSize: 19, color: const Color(0xFF333333)),
          )));
      if (i != attr.enumValueList.length - 1) {
        list.add(const DropdownMenuItem(
          enabled: false,
          child: Divider(),
        ));
      }
    }
    return list;
  }

  List<double> showCombItemHeights(FeatureAttribute attr, int font) {
    List<double> list = [];
    for (int i = 0; i < attr.enumValueList.length; i++) {
      int tmp = 6;
      double height = attr.enumValueList[i].text.length <= tmp
          ? 40
          : (attr.enumValueList[i].text.length / tmp * (font + 4)).toDouble() <
                  40
              ? 40
              : (attr.enumValueList[i].text.length / tmp * (font + 4))
                  .toDouble();
      list.add(height);
      if (i != attr.enumValueList.length - 1) {
        list.add(4);
      }
    }
    return list;
  }
}

class PageResetBleKey extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        appBar:
            WidgetHelper.itemAppBar(title: S.of(context).forget_pwd /*"忘记密码"*/),
        body: Padding(
          padding: const EdgeInsets.only(top: 32, left: 12, right: 12),
          child: Column(
            children: [
              Text(
                  "        " +
                      S
                          .of(context)
                          .forget_ble_password_tip1 /*"若需要重置密码可在设备通电状态下，点按reload触发重置功能进行密码重置。如下图所示："*/ +
                      "\n\n",
                  style: SSLi.textStyleNormal),
              //Container(width: 300,height: 300, color: Colors.lightBlueAccent,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/reset_password1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Image.asset(
                      'assets/reset_password2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              Text(
                  "\n\n" +
                      "        " +
                      S
                          .of(context)
                          .forget_ble_password_tip2 /*"若不方便操作可发送邮件至：\nmelon@siseli.com 由工作人员协助修改密码。\n请在邮件中备注好使用设备ID。"*/ +
                      "\n",
                  style: SSLi.textStyleNormal),
              Stack(
                children: [
                  Text(
                      "        " +
                          S
                              .of(context)
                              .forget_ble_password_tip3 /*"注意：若设备有配置过Wi-Fi，在触发重置功能后，需重新配置。请谨慎操作！"*/,
                      style: SSLi.textStyleLittleMore),
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.amber,
                  )
                ],
              ),
            ],
          ),
        ));
  }
}

class _nearWaitingContent extends StatefulWidget {
  String title;
  FeatureGroup? featureGroup;
  DeviceInfo? deviceInfo;
  bool requestEnd; //
  int count; //
  int fail; //
  String result; //
  List<String> valueList;
  Function() refresh; //只用于read
  Function() unlock;
  int? index;
  bool isBatch;
  int? total;
  int? start;
  int? end;
  String rw;
  List<int?> verCodeL;
  List<String?> protocolNoL;
  String dtuId;
  List<int?> baudRateL;
  List<int?> dataBitL;
  List<String?> parityBitL;
  List<int?> stopBitL;
  Function applyAndWait;
  Function threadComplete;
  late bool isOffLine;
  _nearWaitingContent(
      {required this.title,
      required this.featureGroup,
      required this.requestEnd,
      required this.count,
      required this.fail,
      required this.result,
      required this.valueList,
      required this.refresh,
      required this.unlock,
      this.index,
      required this.isBatch,
      this.total,
      this.start,
      this.end,
      required this.rw,
      required this.verCodeL,
      required this.protocolNoL,
      required this.dtuId,
      required this.baudRateL,
      required this.dataBitL,
      required this.parityBitL,
      required this.stopBitL,
      required this.applyAndWait,
      required this.threadComplete}) {
    if (deviceInfo != null && deviceInfo!.state == 100)
      isOffLine = true;
    else
      isOffLine = false;
    //isOffLine = false; //for test
    if (isOffLine == true)
      title = SSLiLanguage.sharedInstance().isZh
          ? "设备已离线，请检查设备通电后重试"
          : "The device is offline, please check the device power on and try again";
  }
  @override
  _nearWaitingContentState createState() => _nearWaitingContentState();
}

class _nearWaitingContentState extends State<_nearWaitingContent> {
  late bool loading;
  @override
  void dispose() {
    super.dispose();
    print("dispose invoked");
  }

  @override
  void initState() {
    super.initState();
    if (widget.isOffLine == true) {
      loading = false;
      widget.requestEnd = true;
      widget.unlock();
      print("unlock invoked");
      return;
    }
    loading = true;
    if (widget.rw == "read") {
      if (widget.isBatch == false) {
        read(widget.index!, false, widget.total!);
      } else {
        Future.delayed(Duration.zero, () async {
          for (int i = widget.start!; i < widget.end!; i++) {
            await read(i, true, widget.end! - 1);
          }
        });
      }
    } else {
      if (widget.isBatch == false) {
        write(widget.index!, false, widget.total!);
      } else {
        Future.delayed(Duration.zero, () async {
          for (int i = widget.start!; i < widget.end!; i++) {
            await write(i, true, widget.end! - 1);
          }
        });
      }
    }
  }

  Future<void> read(int index, bool isBatch, int total) async {
    /*if (index%10 == 0 && isBatch) {
      popup = dialogWaiting(S.of(context).batch_reading);
      Navigator.push(buildContext, popup!);
      popup?.isPush = true;
    }*/
    if (widget.featureGroup!.attributes[index].operationMode == 2) {
      if (index == total) {
        /*if (popup?.isPush == true) {
          popup?.pop();
          popup?.isPush == false;
        }*/
        widget.requestEnd = true;
        widget.unlock();
        print("unlock invoked");
        if (isBatch) {
          //WidgetHelper.showAlertDialog(buildContext, "${S.of(context).read_success_total}$widget.count${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}", null);

          if (mounted)
            widget.title =
                "${S.of(context).read_success_total}${widget.count}${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}";
          loading = false;
          if (mounted) setState(() {});
        }
      }
      return;
    }
    Map<String, dynamic>
        rpl = //await Proto.getSetUpMessage(widget.deviceInfo == null ? "" : widget.deviceInfo!.id, widget.featureGroup == null ? "" : widget.featureGroup!.attributes[index].key);
        await getSetUpMessage(widget.featureGroup == null
            ? ""
            : widget.featureGroup!.attributes[index].key);

    if (isBatch == true) {
      widget.count++;
    }
    if (rpl.containsKey("errMsg")) {
      widget.valueList[index] = "";
      widget.fail++;
      if (isBatch == true && mounted)
        widget.result =
            "${widget.result}${widget.fail}. ${widget.featureGroup!.attributes[index].name}${S.of(context).read_fail}\n";
      else {
        //WidgetHelper.showAlertDialog(buildContext, S.of(context).read_fail, rpl['errMsg']);
        if (mounted)
          widget.title = S.of(context).read_fail + '\n\n' + rpl['errMsg'];
        loading = false;
        if (mounted) setState(() {});
      }
    } else {
      if (isBatch == false) {
        //WidgetHelper.showAlertDialog(buildContext, S.of(context).read_success, null);
        if (mounted) widget.title = S.of(context).read_success;
        loading = false;
        if (mounted) setState(() {});
      }
      if (rpl["value"] is String) {
        widget.valueList[index] = rpl["value"];
      } else {
        widget.valueList[index] = rpl["value"].toString();
      }
    }
    if (index == total) {
      /*if (popup?.isPush == true){
        popup?.pop();
      }*/
      widget.requestEnd = true;
      widget.unlock();
      print("unlock invoked");
      if (isBatch) {
        //WidgetHelper.showAlertDialog(buildContext, "${S.of(context).read_success_total}$widget.count${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}", null);
        if (mounted)
          widget.title =
              "${S.of(context).read_success_total}${widget.count}${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}";
        loading = false;
        if (mounted) setState(() {});
      }
    }
    //if (mounted) _setState(() {});
    widget.refresh();
  }

  Future<void> write(int index, bool isBatch, int total) async {
    /*if (index%10 == 0 && isBatch) {
      popup = dialogWaiting(S.of(context).batch_deliverying, molecule: count, denominator: total%10+1);
      Navigator.push(buildContext, popup!);
      popup?.isPush = true;
    }*/
    if (widget.valueList[index] == "" ||
        widget.featureGroup!.attributes[index].operationMode == 1) {
      if (index == total) {
        /*if (popup?.isPush == true) {
          popup?.pop();
        }*/
        widget.requestEnd = true;
        widget.unlock();
        print("unlock invoked");
        if (isBatch) {
          //WidgetHelper.showAlertDialog(buildContext, "${S.of(context).delivery_success_total}$count${S.of(context).item}，${S.of(context).success}${count - fail}${S.of(context).item}，${S.of(context).fail}$fail${S.of(context).item}\n${result}", null);
          if (mounted)
            widget.title =
                "${S.of(context).delivery_success_total}${widget.count}${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}";
          loading = false;
          if (mounted) setState(() {});
        }
      }
      ;
      return;
    }
    Map<String, dynamic>
        rpl = //await Proto.uploadSetUpMessage(widget.deviceInfo == null ? "" : widget.deviceInfo!.id, widget.featureGroup == null ? "" : widget.featureGroup!.attributes[index].key, widget.valueList[index]);
        await uploadSetUpMessage(
            widget.featureGroup == null
                ? ""
                : widget.featureGroup!.attributes[index].key,
            widget.valueList[index]);
    if (isBatch == true) {
      widget.count++;
      /*popup?.molecule = count;
      popup?.refresh();*/
    }
    if (!rpl.containsKey("errMsg")) {
      if (isBatch == false) {
        //WidgetHelper.showAlertDialog(buildContext, S.of(context).delivery_success, null);
        if (mounted) widget.title = S.of(context).delivery_success;
        loading = false;
        if (mounted) setState(() {});
      }
    } else {
      widget.valueList[index] = "";
      widget.fail++;
      if (isBatch == true && mounted)
        widget.result =
            "${widget.result}${widget.fail}. ${widget.featureGroup!.attributes[index].name}${S.of(context).delivery_fail}\n";
      else {
        //WidgetHelper.showAlertDialog(buildContext, S.of(context).delivery_fail, rpl['errMsg']);
        if (mounted)
          widget.title = S.of(context).delivery_fail + '\n\n' + rpl['errMsg'];
        loading = false;
        if (mounted) setState(() {});
      }
    }
    if (index == total) {
      /*if (popup?.isPush == true) {
        popup?.pop();
      }*/
      widget.requestEnd = true;
      widget.unlock();
      print("unlock invoked");
      if (isBatch) {
        //WidgetHelper.showAlertDialog(buildContext, "${S.of(context).delivery_success_total}$count${S.of(context).item}，${S.of(context).success}${count - fail}${S.of(context).item}，${S.of(context).fail}$fail${S.of(context).item}\n${result}", null);
        if (mounted)
          widget.title =
              "${S.of(context).delivery_success_total}${widget.count}${S.of(context).item}，${S.of(context).success}${widget.count - widget.fail}${S.of(context).item}，${S.of(context).fail}${widget.fail}${S.of(context).item}\n${widget.result}";
        loading = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<Map<String, dynamic>> getSetUpMessage(String key) async {
    Map<String, dynamic> ret = SSLiLanguage.sharedInstance().isZh
        ? {'errMsg': "未知错误"}
        : {'errMsg': "unknown error"};
    await Proto.nearGenerateConfigRead(
            SSLiManager.instance.getToken() ?? "",
            widget.dtuId,
            widget.protocolNoL[0] ?? "",
            widget.verCodeL[0] ?? 0,
            key)
        .then((rplData) async {
      await widget.applyAndWait(); //等待主线程暂停
      await WiFiConfig.instance
          .doGetUartDiagnose(
              uartCmd: decodeToHex(rplData["cmdData"]) ?? "",
              baudRate: widget.baudRateL[0] ?? 0,
              dataBit: widget.dataBitL[0] ?? 0,
              parityBit: widget.parityBitL[0] ?? "",
              stopBit: widget.stopBitL[0] ?? 0)
          .then((rpl) async {
        widget.threadComplete(); //该线程结束
        if (rpl == null) return;
        ret = await Proto.nearParseConfigRead(
            SSLiManager.instance.getToken() ?? "",
            widget.dtuId,
            widget.protocolNoL[0] ?? "",
            widget.verCodeL[0] ?? 0,
            encodeToBase64(rpl["Rsp"]) ?? "",
            key);
      });
    });
    return ret;
  }

  Future<Map<String, dynamic>> uploadSetUpMessage(
      String key, String value) async {
    Map<String, dynamic> ret = SSLiLanguage.sharedInstance().isZh
        ? {'errMsg': "未知错误"}
        : {'errMsg': "unknown error"};
    await Proto.nearGenerateConfigWrite(
            SSLiManager.instance.getToken() ?? "",
            widget.dtuId,
            widget.protocolNoL[0] ?? "",
            widget.verCodeL[0] ?? 0,
            key,
            value)
        .then((rplData) async {
      await widget.applyAndWait(); //等待主线程暂停
      await WiFiConfig.instance
          .doGetUartDiagnose(
              uartCmd: decodeToHex(rplData["cmdData"]) ?? "",
              baudRate: widget.baudRateL[0] ?? 0,
              dataBit: widget.dataBitL[0] ?? 0,
              parityBit: widget.parityBitL[0] ?? "",
              stopBit: widget.stopBitL[0] ?? 0)
          .then((rpl) async {
        widget.threadComplete(); //该线程结束
        if (rpl == null) return;
        ret = await Proto.nearParseConfigWrite(
            SSLiManager.instance.getToken() ?? "",
            widget.dtuId,
            widget.protocolNoL[0] ?? "",
            widget.verCodeL[0] ?? 0,
            encodeToBase64(rpl["Rsp"]) ?? "",
            key);
      });
    });
    return ret;
  }

  String? decodeToHex(String? base64Encoded) {
    if (base64Encoded == null) return null;
    List<int> decodedBytes = base64.decode(base64Encoded);
    String hexString = bytesToHex(decodedBytes).toUpperCase();
    return hexString;
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  String? encodeToBase64(String? hexString) {
    if (hexString == null) return null;
    final List<int> result = [];
    try {
      for (int i = 0; i < hexString.length; i += 2) {
        result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
      }
    } catch (e) {
      return null;
    }
    return base64.encode(result);
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? SizedBox(
            height: 75,
            child: Column(
              children: [
                Spacer(),
                Text(widget.title ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  strokeWidth: 1.0,
                ),
                //Spacer(),
              ],
            ),
          )
        : Text(widget.title ?? "",
            style: const TextStyle(fontSize: 16, color: Colors.black));
  }
}

class _subDebug extends StatefulWidget {
  List<String> records = [];
  TextEditingController controller = TextEditingController();
  bool processing = false;
  List<String> debugSettings;
  List<int?> baudRateL;
  List<int?> dataBitL;
  List<String?> parityBitL;
  List<int?> stopBitL;
  Function applyAndWait;
  Function threadComplete;
  _subDebug(this.debugSettings, this.baudRateL, this.dataBitL, this.parityBitL,
      this.stopBitL, this.applyAndWait, this.threadComplete);
  @override
  State<_subDebug> createState() => _subDebugState();
}

class _subDebugState extends State<_subDebug> {
  late ScrollController scrollController;
  Map<String, Function> functionMap = {
    "Crc-8": Crc8().convert,
    "Crc-8/SaeJ1850": Crc8SaeJ1850().convert,
    "Crc-8/Cdma2000": Crc8Cdma2000().convert,
    "Crc-8/Darc": Crc8Darc().convert,
    "Crc-8/DvbS2": Crc8DvbS2().convert,
    "Crc-8/Ebu": Crc8Ebu().convert,
    "Crc-8/ICode": Crc8ICode().convert,
    "Crc-8/Itu": Crc8Itu().convert,
    "Crc-8/Maxim": Crc8Maxim().convert,
    "Crc-8/Rohc": Crc8Rohc().convert,
    "Crc-8/Wcdma": Crc8Wcdma().convert,
    "Crc-16/Arc": Crc16Arc().convert,
    "Crc-16/AugCcitt": Crc16AugCcitt().convert,
    "Crc-16/Buypass": Crc16Buypass().convert,
    "Crc-16/CcittFalse": Crc16CcittFalse().convert,
    "Crc-16/Cdma2000": Crc16Cdma2000().convert,
    "Crc-16/Dds110": Crc16Dds110().convert,
    "Crc-16/DectR": Crc16DectR().convert,
    "Crc-16/DectX": Crc16DectX().convert,
    "Crc-16/Dnp": Crc16Dnp().convert,
    "Crc-16/En13757": Crc16En13757().convert,
    "Crc-16/GeniBus": Crc16GeniBus().convert,
    "Crc-16/Maxim": Crc16Maxim().convert,
    "Crc-16/Mcrf4xx": Crc16Mcrf4xx().convert,
    "Crc-16/Riello": Crc16Riello().convert,
    "Crc-16/T10Dif": Crc16T10Dif().convert,
    "Crc-16/Teledisk": Crc16Teledisk().convert,
    "Crc-16/Tms37157": Crc16Tms37157().convert,
    "Crc-16/Usb": Crc16Usb().convert,
    "Crc-16/A": Crc16A().convert,
    "Crc-16/Kermit": Crc16Kermit().convert,
    "Crc-16/Modbus": Crc16Modbus().convert,
    "Crc-16/X25": Crc16X25().convert,
    "Crc-16/Xmodem": Crc16Xmodem().convert,
    "Crc-32": Crc32().convert,
    "Crc-32/Bzip2": Crc32Bzip2().convert,
    "Crc-32/C": Crc32C().convert,
    "Crc-32/D": Crc32D().convert,
    "Crc-32/Mpeg2": Crc32Mpeg2().convert,
    "Crc-32/Posix": Crc32Posix().convert,
    "Crc-32/Q": Crc32Q().convert,
    "Crc-32/JamCrc": Crc32JamCrc().convert,
    "Crc-32/Xfer": Crc32Xfer().convert,
  };

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (buildContext, constraintType) {
      print("constraintType.maxWidth:${constraintType.maxWidth}");
      return Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey<String>("debug"), //与SelectableText冲突
              controller: scrollController,
              //reverse: true,
              children: [
                SizedBox(
                  height: 10,
                ), //顶部空隙
                ...List.generate(widget.records.length, (index) {
                  //index = widget.records.length - (index + 1); //配合reverse使用
                  if (widget.records[index][0] == 's') {
                    //send
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF578FFF),
                                    Color(0xFF1B64F7),
                                  ],
                                  begin: Alignment.centerLeft, // 渐变起点
                                  end: Alignment.centerRight, // 渐变终点
                                ),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 15, right: 15, top: 13, bottom: 13),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: constraintType.maxWidth -
                                          15 -
                                          15 -
                                          20 -
                                          50 -
                                          10 -
                                          40),
                                  child: Text(
                                      widget.records[index].substring(1),
                                      style: SSLiTextStyles.pingFangBold(
                                          fontSize: 16, color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            // CircleAvatar(
                            //   child: Icon(Icons.phone_android,color: Colors.white),
                            //   backgroundColor: Colors.blue,
                            //   radius: 25,
                            // ),
                            /*
                              Container(
                                width: 50, height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFADC8FF),
                                      Color(0xFF1B64F7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(child: Text(getFirstAndSecondLetters(), style: SSLiTextStyles.pingFangHeavy(fontSize: 17, color: Colors.white),)),
                              ),
                              */
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Stack(
                                    children: [
                                      // Image(image: AssetImage('assets/station_placehold.jpg')),
                                      showPicture(),
                                    ],
                                  )),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    );
                  }
                  if (widget.records[index][0] == 'r') {
                    //reply
                    return Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            CircleAvatar(
                              child: Image(
                                image: AssetImage("assets/fronus/appLogo.png"),
                              ), //Icon(Icons.bluetooth,color: Colors.white),
                              backgroundColor: Colors.white, //Colors.blue,
                              radius: 25,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 15, right: 15, top: 13, bottom: 13),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: constraintType.maxWidth -
                                          15 -
                                          15 -
                                          20 -
                                          50 -
                                          10 -
                                          40),
                                  child: Text(
                                      widget.records[index].substring(1),
                                      style: SSLiTextStyles.pingFangBold(
                                          fontSize: 16,
                                          color: const Color(0xFF333333))),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    );
                  }
                  if (widget.records[index][0] == 't') {
                    return Column(
                      children: [
                        Center(
                            child: Text(
                          widget.records[index].substring(1),
                          style: SSLiTextStyles.pingFangMedium(
                              fontSize: 12, color: const Color(0xFF999999)),
                        )),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                //SizedBox(height: 10,),//顶部空隙 配合reverse使用
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 10, top: 8, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: 10, top: 0, right: 0, bottom: 0),
                          filled: true,
                          fillColor: SSLi.themeBackgroundColor,
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.controller.text.isEmpty) return;
                        if (widget.processing == true) return;
                        // if(widget.records.isEmpty) widget.records.add("t${removeLastDot(DateTime.now().toString())}");
                        if (widget.records.isEmpty)
                          widget.records.add(
                              "t${DateFormat('yy/MM/dd HH:mm').format(DateTime.now())}");
                        send(widget.controller.text);
                        widget.records.add("s${widget.controller.text}");
                        if (mounted)
                          setState(() {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              //无reverse使用
                              scrollController.jumpTo(
                                  scrollController.position.maxScrollExtent);
                            });
                          });
                        widget.controller.clear();
                        //scrollController.jumpTo(0); //配合reverse使用
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(), // 圆形边框
                        backgroundColor: Color(0xFF1B64F7),
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(38, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      // child: Icon(Icons.ac_unit, color: Colors.white, size: 24,),
                      child: SvgPicture.asset(
                        "assets/发送.svg",
                        width: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    });
  }

  String getFirstAndSecondLetters() {
    String userName =
        PinyinHelper.getShortPinyin(SSLiManager.instance.users?.me.name ?? "")
            .replaceAll(' ', '');
    if (userName.length == 1) return userName.toUpperCase();
    if (userName.length >= 2) return userName.substring(0, 2).toUpperCase();
    return "";
  }

  Widget showPicture() {
    SSLiUsers? users = SSLiManager.instance.users;
    if (users != null) {
      String? _imageResid = users.me.iconResid;
      print("iconResid:" + _imageResid.toString());
      if (_imageResid != null && _imageResid!.isNotEmpty) {
        String? token = SSLiManager.instance.getToken();
        if (token != null) {
          String url = Proto.gly_url +
              "/resource/download/media?resid=" +
              _imageResid! +
              "&save=false&IOT-Token=" +
              token;
          print("url:" + url);
          return Image.network(
            url,
            fit: BoxFit.cover,
          );
        }
      }
    }
    // return Image.asset("assets/fronus/renyuan.png", fit: BoxFit.fitHeight,);
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SSLiTextStyles.hexToColor("#FFADC8FF"),
            SSLiTextStyles.hexToColor("#FF1B64F7"),
          ],
          begin: Alignment.topCenter,
          end: Alignment.centerRight,
        ),
        // color: SSLiTextStyles.hexToColor("#FF1B64F7"), // 背景颜色
        borderRadius: BorderRadius.circular(35.0), // 圆角半径
        border: Border.all(
            color: SSLiTextStyles.hexToColor("#FFFFFFFF"), width: 3.0),
      ),
      child: Center(
          child: Text(
        EUtil.getShowPictureText(SSLiManager.instance.users!.me.name, 2),
        style: SSLiTextStyles.pingFangHeavy(fontSize: 30, color: "#FFFFFFFF"),
      )),
    );
  }

  Future<void> send(String msg) async {
    widget.processing = true;
    CrcValue crcValue;
    String ascii;
    if (widget.debugSettings[0] == "Hex") {
      msg = msg.replaceAll(' ', '');
      ascii = hexToAscii(msg);
    } else {
      ascii = msg;
      msg = msg.runes.map((int rune) {
        return rune.toRadixString(16).toUpperCase();
      }).join('');
    }
    if (functionMap[widget.debugSettings[1]] != null) {
      crcValue = functionMap[widget.debugSettings[1]]!(utf8.encode(ascii));
      print(
          "crcValue:${crcValue} => ${crcValue.toRadixString(16).toUpperCase()}");
      msg = msg + crcValue.toRadixString(16).toUpperCase();
    }
    if (widget.debugSettings[2] == S.of(context).yes /*"有"*/) msg += "0D";
    print("msg:$msg");
    await widget.applyAndWait(); //等待主线程暂停
    await WiFiConfig.instance
        .doGetUartDiagnose(
            uartCmd: msg,
            baudRate: widget.baudRateL[0] ?? 0,
            dataBit: widget.dataBitL[0] ?? 0,
            parityBit: widget.parityBitL[0] ?? "",
            stopBit: widget.stopBitL[0] ?? 0)
        .then((PL) {
      widget.threadComplete(); //该线程结束
      String? rpl = PL?["Rsp"];
      //rpl = "5150495249F8540D";
      if (rpl != null) {
        if (widget.debugSettings[5] == S.of(context).yes /*"有"*/ &&
            rpl.length >= 2) rpl = rpl.substring(0, rpl.length - 2); //去回车符号
        if (widget.debugSettings[4] == "Crc-8" && rpl.length >= 2)
          rpl = rpl.substring(0, rpl.length - 2);
        if (widget.debugSettings[4] == "Crc-16" && rpl.length >= 4)
          rpl = rpl.substring(0, rpl.length - 4);
        if (widget.debugSettings[4] == "Crc-32" && rpl.length >= 8)
          rpl = rpl.substring(0, rpl.length - 8);
        if (widget.debugSettings[3] == S.of(context).text /*"文本"*/)
          rpl = hexToAscii(rpl);
        if (widget.debugSettings[3] == "Hex") rpl = insertSpaces(rpl);
      }
      widget.records.add("r${rpl ?? ""}");
      if (mounted)
        setState(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            //无reverse使用
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
        });
    });
    widget.processing = false;
  }

  String removeLastDot(String input) {
    int lastDotIndex = input.lastIndexOf('.');

    if (lastDotIndex != -1) {
      return input.substring(0, lastDotIndex);
    } else {
      // 如果没有找到小数点，返回原始字符串
      return input;
    }
  }

  String? decodeToHex(String? base64Encoded) {
    if (base64Encoded == null) return null;
    List<int> decodedBytes = base64.decode(base64Encoded);
    String hexString = bytesToHex(decodedBytes).toUpperCase();
    return hexString;
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  String? encodeToBase64(String? hexString) {
    if (hexString == null) return null;
    final List<int> result = [];
    try {
      for (int i = 0; i < hexString.length; i += 2) {
        result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
      }
    } catch (e) {
      return null;
    }
    return base64.encode(result);
  }

  String hexToAscii(String hexString) {
    // 将十六进制字符串拆分成两个字符的列表
    List<String> hexPairs = [];
    for (var i = 0; i < hexString.length; i += 2) {
      if (i == hexString.length - 1) {
        hexPairs.add("0${hexString.substring(i, i + 1)}");
        break;
      }
      hexPairs.add(hexString.substring(i, i + 2));
    }
    print("hexPairs:${hexPairs}");

    // 将每个十六进制字符对转换为对应的 ASCII 字符
    String resultString = "";
    try {
      resultString = hexPairs.map((hex) {
        int charCode = int.parse(hex, radix: 16);
        return String.fromCharCode(charCode);
      }).join('');
    } catch (e) {}

    return resultString;
  }

  String insertSpaces(String inputString) {
    if (inputString.length <= 2) {
      // 字符串长度小于等于2，无需插入空格
      return inputString;
    }

    // 使用 StringBuffer 动态构建结果字符串
    StringBuffer resultBuffer = StringBuffer();

    for (int i = 0; i < inputString.length; i++) {
      if (i > 0 && i % 2 == 0) {
        // 每隔两个数字插入一个空格
        resultBuffer.write(' ');
      }
      resultBuffer.write(inputString[i]);
    }

    return resultBuffer.toString();
  }
}

class PageDebugSetting extends StatefulWidget {
  List<String> debugSettings;
  PageDebugSetting(this.debugSettings);
  @override
  State<PageDebugSetting> createState() => _PageDebugSettingState();
}

class _PageDebugSettingState extends State<PageDebugSetting> {
  List<String> cRCItems = [
    "Crc-8",
    "Crc-8/SaeJ1850",
    "Crc-8/Cdma2000",
    "Crc-8/Darc",
    "Crc-8/DvbS2",
    "Crc-8/Ebu",
    "Crc-8/ICode",
    "Crc-8/Itu",
    "Crc-8/Maxim",
    "Crc-8/Rohc",
    "Crc-8/Wcdma",
    "Crc-16/Arc",
    "Crc-16/AugCcitt",
    "Crc-16/Buypass",
    "Crc-16/CcittFalse",
    "Crc-16/Cdma2000",
    "Crc-16/Dds110",
    "Crc-16/DectR",
    "Crc-16/DectX",
    "Crc-16/Dnp",
    "Crc-16/En13757",
    "Crc-16/GeniBus",
    "Crc-16/Maxim",
    "Crc-16/Mcrf4xx",
    "Crc-16/Riello",
    "Crc-16/T10Dif",
    "Crc-16/Teledisk",
    "Crc-16/Tms37157",
    "Crc-16/Usb",
    "Crc-16/A",
    "Crc-16/Kermit",
    "Crc-16/Modbus",
    "Crc-16/X25",
    "Crc-16/Xmodem",
    "Crc-32",
    "Crc-32/Bzip2",
    "Crc-32/C",
    "Crc-32/D",
    "Crc-32/Mpeg2",
    "Crc-32/Posix",
    "Crc-32/Q",
    "Crc-32/JamCrc",
    "Crc-32/Xfer"
  ];

  String sendFormatValue = "文本";
  List<String> sendFormatItems = ["文本", "Hex"];
  String sendCRCValue = "无";
  List<String> sendCRCItems = ["无"];
  String sendEnterValue = "无";
  List<String> sendEnterItems = ["无", "有"];

  String receiveFormatValue = "文本";
  List<String> receiveFormatItems = ["文本", "Hex"];
  String receiveCRCValue = "无";
  List<String> receiveCRCItems = ["无", "Crc-8", "Crc-16", "Crc-32"];
  String receiveEnterValue = "无";
  List<String> receiveEnterItems = ["无", "有"];

  @override
  void initState() {
    super.initState();
    sendFormatValue = widget.debugSettings[0];
    sendCRCValue = widget.debugSettings[1];
    sendEnterValue = widget.debugSettings[2];
    receiveFormatValue = widget.debugSettings[3];
    receiveCRCValue = widget.debugSettings[4];
    receiveEnterValue = widget.debugSettings[5];
    sendCRCItems.addAll(cRCItems);
  }

  @override
  Widget build(BuildContext context) {
    sendFormatItems = [S.of(context).text, "Hex"];
    sendCRCItems[0] = S.of(context).no;
    sendEnterItems = [S.of(context).no, S.of(context).yes];
    receiveFormatItems = [S.of(context).text, "Hex"];
    receiveCRCItems = [S.of(context).no, "Crc-8", "Crc-16", "Crc-32"];
    receiveEnterItems = [S.of(context).no, S.of(context).yes];
    return MyScaffold(
        appBar: WidgetHelper.itemAppBar(
            title: S.of(context).debug_settings /*"调试设置"*/,
            actions: [
              TextButton(
                  onPressed: () {
                    widget.debugSettings[0] = sendFormatValue;
                    widget.debugSettings[1] = sendCRCValue;
                    widget.debugSettings[2] = sendEnterValue;
                    widget.debugSettings[3] = receiveFormatValue;
                    widget.debugSettings[4] = receiveCRCValue;
                    widget.debugSettings[5] = receiveEnterValue;
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).save /*"保存"*/,
                      style: SSLiTextStyles.pingFangMedium(
                          fontSize: 14, color: const Color(0xFF333333))))
            ]),
        body: Padding(
          padding: const EdgeInsets.only(top: 32, left: 12, right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).sending_settings /*"发送设置"*/,
                          style: SSLiTextStyles.pingFangBold(
                              fontSize: 16, color: const Color(0xFF333333))),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Text(S.of(context).format /*"消息格式"*/,
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return sendFormatItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: sendFormatItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item != sendFormatItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    sendFormatValue, //widget.debugSettings[0],//sendFormatValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    sendFormatValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 16,
                        color: Color(0xFFECECEC),
                        thickness: 1,
                      ),
                      Row(
                        children: [
                          Text("CRC",
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return sendCRCItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: sendCRCItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item != sendCRCItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    sendCRCValue, //widget.debugSettings[1],//sendCRCValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    sendCRCValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 16,
                        color: Color(0xFFECECEC),
                        thickness: 1,
                      ),
                      Row(
                        children: [
                          Text(S.of(context).enter /*"回车符"*/,
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return sendEnterItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: sendEnterItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item != sendEnterItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    sendEnterValue, //widget.debugSettings[2],//sendEnterValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    sendEnterValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).receiving_settings /*"接收设置"*/,
                          style: SSLiTextStyles.pingFangBold(
                              fontSize: 16, color: const Color(0xFF333333))),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Text(S.of(context).format /*"消息格式"*/,
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return receiveFormatItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: receiveFormatItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item !=
                                                  receiveFormatItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    receiveFormatValue, //widget.debugSettings[3],//receiveFormatValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    receiveFormatValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 16,
                        color: Color(0xFFECECEC),
                        thickness: 1,
                      ),
                      Row(
                        children: [
                          Text(S.of(context).delete_CRC /*"去CRC"*/,
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return receiveCRCItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: receiveCRCItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item != receiveCRCItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    receiveCRCValue, //widget.debugSettings[4],//receiveCRCValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    receiveCRCValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 16,
                        color: Color(0xFFECECEC),
                        thickness: 1,
                      ),
                      Row(
                        children: [
                          Text(S.of(context).delete_enter /*"去回车符"*/,
                              style: SSLiTextStyles.pingFangMedium(
                                  fontSize: 14,
                                  color: const Color(
                                      0xFF666666))), //SSLi.textStyleHeadLittle),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: MediaQuery.of(context).size.width * 0.352,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0x1A999999)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFBBBBBB),
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (_) {
                                  // 避免被选中的item有下划线
                                  return receiveEnterItems
                                      .map((String item) =>
                                          DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style:
                                                  SSLiTextStyles.pingFangBold(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF333333)),
                                            ),
                                          ))
                                      .toList();
                                },
                                items: receiveEnterItems
                                    .map((String item) =>
                                        DropdownMenuItem<String>(
                                          value: item,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item,
                                                    style: SSLiTextStyles
                                                        .pingFangBold(
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF333333)),
                                                  ),
                                                ),
                                              ),
                                              if (item !=
                                                  receiveEnterItems.last)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFBBBBBB),
                                                ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                dropdownElevation: 1,
                                dropdownPadding: EdgeInsets.zero,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                value:
                                    receiveEnterValue, //widget.debugSettings[5],//receiveEnterValue,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() {
                                    receiveEnterValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
*/
