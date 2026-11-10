import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/model/device.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bms_app/global.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FirmwarePage extends ConsumerStatefulWidget  {
  //const FirmwarePage({Key? key}) : super(key: key);

  @override
    _FirmwarePageState createState() => _FirmwarePageState();
}

class _FirmwarePageState extends ConsumerState<FirmwarePage> {
  List<DeviceInfoModel> deviceInfoList = [
    {"id": 0, "label": S.current.runtime, "value": "2025.12.12 00:00:00"},
    {"id": 1, "label": S.current.appVersion, "value": "1.0.0"},
    {"id": 2, "label": S.current.sofewareVersion, "value": "1.0.0"},
    {"id": 3, "label": S.current.hardwareVersion, "value": "1.0.0"},
  ].map((data) => DeviceInfoModel.fromJson(data)).toList();

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateVersion(); // 每次依赖变化时更新
  }
  //获取应用版本号
  Future<String> getAppVersion() async {
  // 获取包信息，包括版本号
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version; // 返回版本号，如 "1.0.0"
  }
  
  Future<void> _updateVersion() async {
    final batpackinfo = ref.watch(bleStateProvider.select((s) => s.batpackinfo));
   
    deviceInfoList[1].value=await  getAppVersion();
    setState(() {
      deviceInfoList[2].value = batpackinfo.softversion;
      deviceInfoList[3].value =batpackinfo.hardversion;
    });

  }

  @override
  Widget build(BuildContext context) {
    deviceInfoList[0].value = GlobalData.LoadtIime;
    return Scaffold(
        appBar: CustomAppBar(
          isBackButton: true,
          title: customTitleText(S.of(context).sofewareInfo,
              color: AppColor.primary),
        ),
        body: ListView(
          padding: EdgeInsets.only(bottom: 16),
          children: <Widget>[
            GFCard(
              color: AppColor.backgroud,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: deviceInfoList.map((model) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: <Widget>[
                        customText('${model.label}：',
                            style: TextStyles.textStyle14,
                            textAlign: TextAlign.left),
                        customText('${model.value}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ));
  }
}
