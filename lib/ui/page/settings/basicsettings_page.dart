import 'dart:convert';
import 'dart:typed_data';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:bms_app/state/bluetooth_state.dart';

class BasicSettingsPage extends ConsumerStatefulWidget {
  const BasicSettingsPage({Key? key}) : super(key: key);

  @override
  _BasicSettingsPageState createState() => _BasicSettingsPageState();
}

// 主页面
class _BasicSettingsPageState extends ConsumerState<BasicSettingsPage> {
  @override
  void initState() {
    super.initState();
    RefreshData();
  }

  var bluetoothName = '';
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(S.of(context).basicsettings,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              content: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(children: [
                        const Icon(
                            Icons.bluetooth,
                            color: Color(0xFF2196F3),
                            size: 26,
                          ),
                        const SizedBox(width: 4),
                        Text(S.of(context).bloothname,style: TextStyles.textStyleLight14),
                    ],),
                   
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              bluetoothName,
                              style: TextStyles.textStyle16,
                            ),
                        ),
                        const SizedBox(width: 12),
                        // 编辑按钮（右侧）
                        GestureDetector(
                          onTap: () async {
                            _modifyBluetoothDevice();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                 ],
              )
              )
        ],
      )
    );
  }
  //刷新数
  void RefreshData()
  {
      try
      {
        final c = ref.read(bleStateProvider).characteristic;  
        bluetoothName = c!.device.advName;
      }
      catch(e)
      {
          print(e.toString());
      }

  }

  // 蓝牙发送
  Future writeAndRead(List<int> data) async {
    final c = ref.read(bleStateProvider).characteristic;
    try {
        await c!.write(data);
    } catch (e) {
      print(e);
    }
  }

  //修改蓝牙名称
  void _modifyBluetoothDevice() async {
    try 
    {     
      if(bluetoothName.isEmpty)
      {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).deviceTips),
            duration: Duration(seconds: 1), // 持续时间，可根据需要调整
          ));
          return;
      }
       String? newName = await showEditBloothNameDialog( context: context, currentName: bluetoothName);
       if(newName!=null)
       {
          print(newName);
          String modifyname='rename:$newName';
          Int8List data = Int8List.fromList(utf8.encode(modifyname));
          // 写入
          await writeAndRead(data);
          await Future.delayed(Duration(milliseconds: 300));
          RefreshData();
       }
      // 更新状态
      setState(() {
    });
    } catch (e) {
      
    }
  }

    // 弹出修改对话框的方法
  Future<String?> showEditBloothNameDialog({
    required BuildContext context,
    required String currentName,
  }) async 
  {
    TextEditingController controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud, 
          title: customText(S.of(context).editbloothname,
                              style: TextStyles.textStyle14),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:  InputDecoration(
              hintText:  S.of(context).newname,
              hintStyle: TextStyles.textStyleLight, 
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              // 按回车键时自动确认
              Navigator.of(context).pop(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 取消，返回 null
              },
              child: customText(S.of(context).cancel,
                              style: TextStyles.textStyle14),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary, // 正常背景色
                foregroundColor: Colors.white,     // 文字/图标颜色
                elevation: 5, // 阴影高度，数值越大阴影越明显
                shadowColor: AppColor.primary.withValues(alpha: 0.4), 
                padding: EdgeInsets.symmetric(horizontal:16, vertical:8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                String newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop(newName); // 确认，返回新名称
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


}
