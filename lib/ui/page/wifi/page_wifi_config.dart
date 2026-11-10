import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/page/wifi/my_dropdown_textfield.dart';
import 'package:bms_app/ui/page/wifi/my_scaffold.dart';
import 'package:bms_app/ui/page/wifi/page_ssid_select.dart';
import 'package:bms_app/ui/page/wifi/panel_list_check.dart';
import 'package:bms_app/ui/page/wifi/panel_list_textfield.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:expansion_widget/expansion_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
//import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:bms_app/helper/ssli/udp_helper.dart';
import 'package:bms_app/helper/ssli/wifi_config.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
//import 'package:bms_app/ui/page/ble_add_dev/page_near_dtu_config.dart';
//import 'package:bms_app/ui/page/wifi_config/page_chazhuo_waiting.dart';
//import 'package:bms_app/ui/page/wifi_config/page_diagnose.dart';
//import 'package:bms_app/ui/page/wifi_config/page_ssid_select.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:bms_app/helper/ssli/eutil.dart';
import 'package:bms_app/helper/ssli/prof.dart';
import 'dart:math' as math;
import 'package:bms_app/generated/l10n.dart' as lan;
//import '../../item/my_dropdown_textfield.dart';
//import '../../item/my_scaffold.dart';
//import '../../panel/fronus/panel_list_check.dart';
//import '../../panel/fronus/panel_list_textfield.dart';
//import '../../ui_config.dart';
//import '../../widget_helper.dart';

class PageWiFiConfig extends StatefulWidget {
  final String _dtuId;
  final bool _wifiConnected; //判断当前是wifi配网还是蓝牙配网
  final String? _lastConnected;

  String type;
  var deviceInfo;
  PageWiFiConfig(
      {super.key,
      required String dtuId,
      lastConnected,
      this.deviceInfo = '',
      wifiConnected = false,
      is4G = false,
      type = 'qita'})
      : this._dtuId = dtuId,
        this._lastConnected = lastConnected,
        this._wifiConnected = wifiConnected,
        this.type = type;

  @override
  State<PageWiFiConfig> createState() => _PageWiFiConfigState();
}

class _PageWiFiConfigState extends State<PageWiFiConfig> {
  final _ctrlSsid = SingleValueDropDownController();
  final _txtKey = TextEditingController();
  String? ssidValue;
  bool _hasKey = true;
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
  StateSetter? stateSetter;
  BuildContext? mContext;
  List<Completer> doGetSSIDList = [Completer()];
  bool _passwordVerified = false;
  bool did = false;
  bool? isBleKeyEnable;

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
    print("WiFiConfig initState:");
    ssidValue = widget._lastConnected ?? "";
    doGetSSIDList[0].complete();

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
    mContext = context;
    if (!_hasLostConnected && !_deviceFault && _deviceConnected) {
      if (did == true) {
      } else {
        did = true;
        Future.delayed(Duration.zero, () async {
          if (mounted) {
          } else {
            return;
          }
          isBleKeyEnable = await WiFiConfig.instance.doCheckBleKeyEnable();
          if (isBleKeyEnable == null) {
            //存在蓝牙密码
            String? savedKey = await Prof.instance.getBleKey(widget._dtuId);
            print("savedKey:${savedKey}");
            bool quit = false;
            bool result = false;
            bool firstTime = true;
            bool didSavePwd = false;
            String key = "_";

            while (result == false) {
              Completer completer = Completer();
              if (savedKey == null) {
                if (mounted) {
                } else {
                  return;
                }
                if (quit == true) return; //跳出Future函数
              }

              if (savedKey != null) {
                if (savedKey.isEmpty ||
                    savedKey.length < 8 ||
                    savedKey.length > 16) {
                  print("密码长度");
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
            //Navigator.of(context).pop(); //关闭转圈
            if (didSavePwd == true)
              await Prof.instance.setBleKey(widget._dtuId, key);
            isBleKeyEnable = true;
            await WiFiConfig.instance.doSetBleKey(false).then((value) {
              //验证成功后取消用户的密码
              if (value == true) isBleKeyEnable = false;
            });
          }
          print("isBleKeyEnable:${isBleKeyEnable}");
          if (mounted)
            setState(() {
              _passwordVerified = true;
            });
        });
      }
    }
    return MyScaffold(
        appBar: AppBar(
          title: customTitleText(S.of(context).bluewifi),
          centerTitle: true,
          backgroundColor: Colors.transparent, // AppBar 透明
          elevation: 0, // 移除底部阴影，否则会有灰色分层
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ListView(
              children: [
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "ID:  " + widget._dtuId,
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        "Wi-Fi Name:",
                      ),
                      Expanded(
                        child: MyDropDownTextField(
                          //hintText: lan.S.of(context).info_input_ssid,
                          onChanged: (value) async {
                            // FocusScope.of(context).requestFocus(FocusNode());
                            // textFieldFocusNode.requestFocus();
                            print("1 onChanged:" + value.toString());
                            String? ssid;
                            if (value is String) {
                              // print("onChanged:"+value);
                              if (value.indexOf("~~!!@@deleted-") == 0) {
                                String idx =
                                    value.substring("~~!!@@deleted-".length);
                                if (EUtil.isNumericInt(idx) == true) {
                                  int index = int.parse(idx);
                                  doDeleteSSID(index);
                                  return;
                                }
                              }
                              ssid = value;
                            } else if (value is DropDownValueModel) {
                              ssid = value.name;
                            }
                            if (ssid != null && ssid.isNotEmpty) {
                              String? key =
                                  await Prof.instance.getKeyBySSID(ssid);
                              print("key=" + key.toString());
                              if (key != null) {
                                _txtKey.text = key;
                              } else {
                                _txtKey.text = "";
                              }
                            } else {
                              _txtKey.text = "";
                            }
                            ssidValue = ssid;
                            // setState(() {ssidValue=ssid;});
                          },
                          readOnly: false,
                          initialValue: ssidValue,
                          controller: _ctrlSsid,
                          dropdownRadius: 2,
                          dropDownIconProperty:
                              IconProperty(color: Colors.black),
                          dropDownList: showDropDown(),
                          clearOption: true,
                          clearIconProperty:
                              IconProperty(color: Colors.black, size: 14),
                          //textStyle: SSLi.textStyleLittleWithColor("whitec0"),
                          onTextChanged: (_) {
                            if (_hasKey == false) {
                              _hasKey = true;
                              if (mounted && stateSetter != null)
                                stateSetter!(() {});
                            }
                          },
                          onClear: () {
                            if (_hasKey == false) {
                              _hasKey = true;
                              if (mounted && stateSetter != null)
                                stateSetter!(() {});
                            }
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(7),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: (!_hasLostConnected &&
                                  !_deviceFault &&
                                  _deviceConnected &&
                                  _passwordVerified)
                              ? () {
                                  doUnfocus(context);
                                  Navigator.of(context)
                                      .push(
                                    PageRouteBuilder(
                                      pageBuilder: (ctx, a1, a2) =>
                                          PageSsidSelect(
                                        dtuId: widget._dtuId,
                                        wifiConnected: widget._wifiConnected,
                                        doGetSSIDList: doGetSSIDList,
                                      ),
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  )
                                      .then((value) async {
                                    if (value != null && value is String) {
                                      if (value[0] == 't') _hasKey = true;
                                      if (value[0] == 'f') _hasKey = false;
                                      value = value.substring(1);
                                      String? key = await Prof.instance
                                          .getKeyBySSID(value);
                                      if (key != null) {
                                        _txtKey.text = key;
                                      } else {
                                        _txtKey.text = "";
                                      }
                                      if (mounted)
                                        setState(() {
                                          ssidValue = value;
                                        });
                                    }
                                  });
                                }
                              : () {},
                          child: Icon(
                            Icons.search,
                            size: 24,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 2,
                  thickness: 1,
                  color: Colors.white30,
                ),
                SizedBox(
                  height: 30,
                ),
                // TextField(controller: _txtKey, style: SSLi.textStyleLittle,obscureText:true,focusNode: textFieldFocusNode,),
                StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                  stateSetter = setState;
                  return FronusPanelListTextField(
                    hideText: _hideKey,
                    isNumber: false,
                    txtCtrl: _txtKey,
                    label: "Wi-Fi password:",
                    hint: _hasKey
                        ? "Fill in Wi-Fi password"
                        : "This Wi-Fi dose not require a password",
                    actIcon: _hideKey
                        ? SvgPicture.asset(
                            "assets/fronus/guanbixianshi1.svg",
                            height: 24,
                            width: 24,
                            color: Colors.white30,
                          )
                        : SvgPicture.asset(
                            "assets/fronus/yanjing1.svg",
                            height: 24,
                            width: 24,
                            color: Colors.white30,
                          ),
                    onAction: () {
                      if (mounted)
                        setState(() {
                          _hideKey = !_hideKey;
                        });
                    },
                    editable: _hasKey,
                    //labelStyle: SSLi.textStyleLittle,
                    //textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
                  );
                }),
                SizedBox(
                  height: 30,
                ),
                ExpansionWidget(
                  initiallyExpanded: _showNetSet,
                  titleBuilder:
                      (double animationValue, _, isExpaned, toogleFunction) {
                    return InkWell(
                      onTap: (!_hasLostConnected &&
                              !_deviceFault &&
                              _deviceConnected &&
                              _passwordVerified)
                          ? () {
                              toogleFunction(animated: true);
                              if (mounted)
                                setState(() {
                                  _showNetSet = !_showNetSet;
                                });
                            }
                          : () {},
                      child: Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Row(
                          children: [
                            // Expanded(child: Divider(height: 2, thickness: 1, color: SSLi.themeOtherItemColor("whitea0"),)),
                            Text(
                              S.of(context).moreset,
                              //style: SSLi.textStyleLittleMoreLight,
                            ),
                            Transform.rotate(
                              angle: math.pi * animationValue / 2,
                              child: Icon(
                                Icons.arrow_right,
                                size: 20,
                                color: Colors.white30,
                              ),
                              alignment: Alignment.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  content: Container(
                    width: double.infinity,
                    child: Column(
                      children: showDhcp(),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: Padding(
                      padding: EdgeInsets.only(left: 40, right: 40),
                      child: ElevatedButton(
                        onPressed: (!_hasLostConnected &&
                                !_deviceFault &&
                                _deviceConnected &&
                                _passwordVerified)
                            ? () async {
                                if (_deviceFault == true) {
                                  print("设备错误，请返回后重试");
                                  return;
                                }
                                if (ssidValue == null || ssidValue!.isEmpty) {
                                  print("请输入Wi-Fi名称");

                                  return;
                                }
                                if (_txtKey.text.isNotEmpty &&
                                    (_txtKey.text.length < 8 ||
                                        _txtKey.text.length > 63)) {
                                  return;
                                }
                                if (_showNetSet == true) {
                                  print(
                                      "_showNetSet::" + _showNetSet.toString());
                                  if (_checkDhcpEn == true) {
                                    await WiFiConfig.instance
                                        .doSetModelConfig(DHCP: true);
                                  } else {
                                    String ip = _txtCtrlIp.text;
                                    String subnet = _txtCtrlSubnet.text;
                                    String gw = _txtCtrlGw.text;
                                    String dns = _txtCtrlDns.text;
                                    if (ip.isEmpty ||
                                        EUtil.isIpAddress(ip) == false) {
                                      return;
                                    }
                                    if (subnet.isEmpty ||
                                        EUtil.isIpAddress(subnet) == false) {
                                      return;
                                    }
                                    if (gw.isEmpty ||
                                        EUtil.isIpAddress(gw) == false) {
                                      return;
                                    }
                                    if (dns.isEmpty) {
                                      await WiFiConfig.instance
                                          .doSetModelConfig(
                                              DHCP: false,
                                              IP: ip,
                                              Subnet: subnet,
                                              GW: gw);
                                    } else {
                                      await WiFiConfig.instance
                                          .doSetModelConfig(
                                              DHCP: false,
                                              IP: ip,
                                              Subnet: subnet,
                                              GW: gw,
                                              DNS: dns);
                                    }
                                  }
                                }
                                print("ssid=" +
                                    ssidValue! +
                                    ",key=" +
                                    _txtKey.text);
                                Prof.instance
                                    .addSSIDandKey(ssidValue!, _txtKey.text);
                                _ssidList = await Prof.instance.getSSIDList();
                                if (widget.type == 'chazhuo') {
                                  print("chazhuo");
                                } else {
                                  _showWaiting(
                                      context, ssidValue, _txtKey.text);
                                }
                                // Navigator.of(context).push(MaterialPageRoute(builder: (context){return FronusPageDtuIdInput();}));
                              }
                            : () {},
                        child: customText(
                          S.of(context).set,
                          style: TextStyles.textStyle16,
                        ),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blue),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                        ),
                      )),
                ),
                SizedBox(
                  height: 20,
                ),
                // Spacer(),
                Text(S.of(context).wificonfigtip1),
                Text(S.of(context).wificonfigtip2),
              ],
            ),
          ),
        ));
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
        color: Colors.white30,
      ),
    );
    if (!_checkDhcpEn) {
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlIp,
          label: "ip_address",
          hint: "请输入IP地址",
          //labelStyle: SSLi.textStyleLittle,
          //textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlSubnet,
          label: "ubnet",
          hint: "请输入子网掩码",
          //labelStyle: SSLi.textStyleLittle,
          //textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlGw,
          label: "gateway",
          hint: "请输入网关地址",
          //labelStyle: SSLi.textStyleLittle,
          //textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
      list.add(
        FronusPanelListTextField(
          txtCtrl: _txtCtrlDns,
          label: "dns",
          hint: "info_input_dns" /*"请输入DNS服务器地址"*/,
          //labelStyle: SSLi.textStyleLittle,
          //textFieldStyle: SSLi.textStyleLittleWithColor("whitec0"),
        ),
      );
    }
    list.add(SizedBox(
      height: 5,
    ));
    list.add(Text(
      S.of(context).wificonfigdhcptip,
      //style: SSLi.textStyleLittleMoreLight,
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
}

class _dlgInfoConnect extends StatefulWidget {
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
          padding: EdgeInsets.only(left: 8, right: 8),
          height: 150,
          width: 280,
          color: Colors.white,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 10,
            ),
            Text(
              "Device connected,please reconnect",
              //style: SSLi.textStyleNormalWithColor("white20"),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              Prof.instance.prefixSSID + widget.dtuId,
              //style: SSLi.textStyleNormalWithColor("white20"),
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
                            "back" /*返回*/,
                            //style: SSLi.textStyleNormalWithColor("button_text"),
                          ),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(70, 40),
                              backgroundColor: Colors.blue)),
                      ElevatedButton(
                          onPressed: () {
                            AppSettings.openAppSettings(
                                type: AppSettingsType.wifi);
                          },
                          child: Text(
                            "Connect",
                            //style: SSLi.textStyleNormalWithColor("button_text"),
                          ),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(70, 40),
                              backgroundColor: Colors.blue)),
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
      backgroundColor: AppColor.backgroud,
      children: [
        Container(
          padding: EdgeInsets.only(left: 8, right: 8),
          width: 300,
          height: 260,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(height: 10,),
              // isRunning?CircularProgressIndicator(color: SSLi.themeOtherItemColor("button_normal"),):SizedBox(height: 30,),
              CircularPercentIndicator(
                progressColor: Colors.green,
                center: Text((_percent * 100).round().toString() + " %"),
                percent: _percent,
                lineWidth: 2,
                radius: 50.0,
              ),
              SizedBox(
                height: 10,
              ),
              Text(isRunning
                  ? (S.of(context).wificonfigprocessing + _timeSec.toString())
                  : isConfigOK
                      ? (S.of(context).wificonfigscucess)
                      : isCanceled
                          ? (S.of(context).wificonfigcancel)
                          : (S.of(context).wificonfigfail)),
              SizedBox(
                height: 5,
              ),
              Text(
                isConfigOK ? "" : (_word ?? ""),
                //style: SSLi.textStyleLittleMoreWithColor("white60"),
              ), //
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
                        print("是否取消配网？");
                        if (true) {
                          WiFiConfig.instance.cancelWiFiConfig();
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Text(
                      isRunning ? S.of(context).cancel : S.of(context).back,
                      style: TextStyle(color: Colors.white),
                      //style: SSLi.textStyleNormalWithColor("button_text"),
                    ),
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 46),
                        backgroundColor: Colors.blue)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
