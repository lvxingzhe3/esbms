import 'dart:async';

import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/page/wifi/my_scaffold.dart';
import 'package:bms_app/ui/page/wifi/panel_list_text.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:bms_app/helper/ssli/wifi_config.dart';
import 'package:bms_app/helper/ssli/wifi_config_softap.dart';

class PageSsidSelect extends StatefulWidget {
  String _dtuId;
  bool _wifiConnected;
  List<Completer> doGetSSIDList;
  PageSsidSelect(
      {super.key,
      required String dtuId,
      wifiConnected = false,
      required this.doGetSSIDList})
      : this._dtuId = dtuId,
        this._wifiConnected = wifiConnected;

  @override
  State<PageSsidSelect> createState() => _PageSsidSelectState();
}

class _PageSsidSelectState extends State<PageSsidSelect> {
  List<_SSID> _ssidList = [];
  ScrollController _scrollController = ScrollController();
  int _selectIndex = -1;

  Future<void> doUpdateList() async {
    if (widget.doGetSSIDList[0].isCompleted) {
      widget.doGetSSIDList[0] = Completer();
    } else {
      await widget.doGetSSIDList[0].future;
      if (!mounted) {
        return;
      }
      widget.doGetSSIDList[0] = Completer();
      await Future.delayed(const Duration(milliseconds: 1500), () {});
    }
    await WiFiConfig.instance.doGetSSIDList().then((List<ModelSSID>? models) {
      if (widget.doGetSSIDList[0].isCompleted) {
        print("widget.doGetSSIDList has already completed");
      } else {
        widget.doGetSSIDList[0].complete();
        print("widget.doGetSSIDList complete");
      }
      if (!mounted) return;
      if (models != null && models.length > 0) {
        _ssidList.clear();
        for (int i = 0; i < models.length; i++) {
          ModelSSID tmp = models[i];
          print("ssid:" + tmp.ssid + ",secu:" + tmp.secu.toString());
          _ssidList.add(_SSID(tmp.ssid, tmp.secu));
        }
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    doUpdateList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await doUpdateList();
  }

  Widget showMainList() {
    if (_ssidList.length == 0) {
      return Center(
          child: CircularProgressIndicator(
        color: Colors.white30,
        backgroundColor: Colors.black,
      ));
    } else {
      return RefreshIndicator(
        backgroundColor: Colors.black,
        onRefresh: _onRefresh,
        child: ListView.separated(
            physics: AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            separatorBuilder: (BuildContext context, int index) {
              return Divider(
                height: 1,
                color: Colors.white30,
              );
            },
            controller: _scrollController,
            itemCount: _ssidList.length,
            itemBuilder: (BuildContext context, int index) {
              if (index >= _ssidList.length) return SizedBox.shrink();
              _SSID ssid = _ssidList[index];

              return FronusPanelListText(
                showArrow: false,
                sufixIcon: index == _selectIndex
                    ? Icon(
                        Icons.radio_button_checked,
                        size: 26,
                        color: Colors.blue,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        size: 26,
                        color: Colors.grey,
                      ),
                label: ssid.ssid,
                islock: ssid.hasKey,
                value: ssid.hasKey ? "已加密" : "未加密",
                flex: [7, 3],
                onTap: (str) {
                  setState(() {
                    _selectIndex = index;
                  });
                },
              );
            }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(
        title: customTitleText(S.of(context).selectwifi),
        centerTitle: true,
        backgroundColor: Colors.transparent, // AppBar 透明
        elevation: 0, // 移除底部阴影，否则会有灰色分层
        actions: [
          TextButton(
              onPressed: () {
                if (_selectIndex < 0 || _selectIndex >= _ssidList.length) {
                  return;
                }
                String flag;
                if (_ssidList[_selectIndex].hasKey == true)
                  flag = 't';
                else
                  flag = 'f';
                Navigator.of(context)
                    .pop("$flag${_ssidList[_selectIndex].ssid}");
              },
              child: Text(S.of(context).confirm)),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 8, right: 8),
        child: showMainList(),
      ),
    );
  }
}

class _SSID {
  String ssid;
  bool hasKey;

  _SSID(this.ssid, this.hasKey);
}
