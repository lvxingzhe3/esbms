import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/model/bmscmd.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/colors/gf_color.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/progress_bar/gf_progress_bar.dart';
import 'package:getwidget/components/toast/gf_toast.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:getwidget/size/gf_size.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as pathmain;

class OtaUpgradPage extends ConsumerStatefulWidget {
  const OtaUpgradPage({super.key});

  @override
  ConsumerState<OtaUpgradPage> createState() => _OtaUpgradPageState();
}

class _OtaUpgradPageState extends ConsumerState<OtaUpgradPage> {
  String? otaFilePath;
  String? otaFileName;
  String otaOriginFilePath = 'assets/ota/ota_v1.0.0.bin';
  Uint8List? otaSource; // ota 包源文件
  int? otaBytes; // ota 包大小
  final ValueNotifier<double> uploadSchedule =
      ValueNotifier<double>(0); // ota 上传进度
  int otaStep = 0; // ota 升级当前步骤
  int chunkIdx = 0; // 当前上传中 ota 切片下标
  int retryCount = 0; // ota 单步重试重试次数
  Timer? otaTimer; // ota 重试超时计时器
  Timer? otaResendTimer; // ota发送接收计时器
  bool otaTimeout = false; // ota 升级是否超时
  bool canOtaStart = false; // ota 升级能否开始
  bool otaSuccess = false; // ota 升级是否完成
  StreamSubscription? otaSubscription; // ota stream subscription

 final storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState(); // 必须首先调用 super.initState()
  }

  @override
  void dispose() {
    uploadSchedule.dispose();
    otaTimer?.cancel();
    super.dispose();
  }
  
  // start ota
  void startOta(String path, [bool isManual = false]) async {
    String ext  = pathmain.extension(path);
    if (ext != '.bin') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select bin file!'),
              duration: Duration(seconds: 2), // 持续时间，可根据需要调整
            )
          );
      return;
    }


    // 升级弹窗
    showOtaDialog(context);

    // 读取 ota 文件
    if (otaSource == null) {
      await loadBinaryFile(path);
    }
    final List<int> blerecBuff=[];
    //发送指令进入接收订阅
    await stepPre();
    // 开始升级
    otaSubscription = await ref
        .read(bleStateProvider.notifier)
        .asyncValueListener((status, value) async {
      if (otaSuccess) {
        return;
      }
      //status == BleValueStatus.Ended && !canOtaStart
      if (!canOtaStart) {
        setState(() {
          canOtaStart = true;
        });
        stepA1();
      } else if (canOtaStart) {
        //接收数据关闭重发计时器
        otaResendTimer?.cancel();
        otaResendTimer=null;

        blerecBuff.addAll(value);
        final headIndex=blerecBuff.indexOf(BmsCmd.cmdAddress);
        if(headIndex>0)
        {
          blerecBuff.removeRange(0, headIndex);
        }
        if(blerecBuff.length>=6)
        {
          listenBluePlusAck(blerecBuff);
          blerecBuff.clear();
        } 
        else
        {
          print("blerecBuff->$value");
        }
    
      }
    });
  }

  // reset ota
  void resetOtaStatus() {
    setState(() {
      otaSource = null;
      otaBytes = null;
      uploadSchedule.value = 0;
      otaStep = 0;
      chunkIdx = 0;
      retryCount = 0;
      otaTimer?.cancel();
      otaTimer = null;
      otaTimeout = false;
      canOtaStart = false;
      otaSuccess = false;
    });
  }

  // 监听蓝牙 ack
  listenBluePlusAck(List<int> value) {
    List<Function> otaStepFnList = [stepA1, stepA2, stepA3, stepA4, stepA5];
    bool stepPassed = false; // ota 单步是否成功
    int retryLimit = 30; // ota 单步重试重试次数上限
    List<Uint8List> chunks = []; // ota 源文件切片数组 块大小为 chunkSize
    bool otaError = retryCount >= retryLimit || otaTimeout; // ota 升级是否失败
    var chunkindex=sixteenToEight(chunkIdx + 1);
    if (otaStep == 3) {
      chunks = getChunks();
    }
    if (otaError || otaSuccess) 
    {
      return;
    }

    switch (otaStep) {
      case 0:
        stepPassed = (value[1] == 241 && value[2] == 0 && value[3] == 0);
        break;
      case 1:
        stepPassed = (value[1] == 242 && value[2] == 0 && value[3] == 0);
        break;
      case 2:
        stepPassed = (value[1] == 243 && value[2] == 0 && value[3] == 0);
        break;
      case 3:    
        stepPassed = chunkIdx >= chunks.length-1;
        break;
      case 4:
        stepPassed = (value[1] == 245 && value[2] == 0 && value[3] == 0);
        break;
    }
    print('Ota== receive($otaStep) :: $stepPassed');
    setState(() {
      if (stepPassed) {
        otaTimer?.cancel();
        otaTimer = null;
        retryCount = 0;
        if (otaStep == 4) {
          updateUploadSchedule(1);
          otaSuccess = true;
        }
        otaStep += 1;
      } else {
        if (otaStep == 3) {
          if ((value[1] == 244) && chunkindex.length>=2&& value[2] == chunkindex[0] && value[3] == chunkindex[1]) {
            otaTimer?.cancel();
            otaTimer = null;
            retryCount = 0;
            chunkIdx += 1;
            double process=chunkIdx / chunks.length;
            updateUploadSchedule(process);
          } else {
            retryCount += 1;
          }
        } else {
          retryCount += 1;
        }
      }
    });

    Future.microtask(() {
      if (otaSuccess || otaError) {
        otaSubscription?.cancel();
        otaSubscription = null;
        return;
      }
      otaStepFnList[otaStep]();
    });
  }

  stepPre() async {
    // 下发升级指令
    List<int> cmdOfA1 = [BmsCmd.cmdAddress, 0xF1, 0x00, 0x01];
    List<int> crc = calculateCRC16(cmdOfA1);
    cmdOfA1.addAll(crc);
    // 将数据转成 Int8List 并发送到下位机
    Int8List data = Int8List.fromList(cmdOfA1);
    await Future.delayed(Duration(milliseconds: 200));
    await writecmd(data);
  }

  stepA1() async {
    // 下发升级指令
    List<int> cmdOfA1 = [BmsCmd.cmdAddress, 0xF1, 0x00, 0x01];
    List<int> crc = calculateCRC16(cmdOfA1);
    cmdOfA1.addAll(crc);
    // 将数据转成 Int8List 并发送到下位机
    Int8List data = Int8List.fromList(cmdOfA1);
    await Future.delayed(Duration(milliseconds: 200));
    writecmd(data);
    /*
    // 写入
    Timer(Duration(milliseconds: 100), () {
      writecmd(data);
    });
    */
    otaTimer = Timer(Duration(seconds: 60), () {
      setState(() {
        otaTimeout = true;
      });
    });
  }

  stepA2() async {
      // 1. 获取文件名（不含扩展名）
      String fileNameWithoutExt = otaFileName!.substring(0, otaFileName!.length - 4);
      // 2. 按 '+' 分割
      List<String> binNameStrs = fileNameWithoutExt.split('+');
      // 3. 检查分割结果
      if (binNameStrs.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('version error'),
            duration: Duration(seconds: 1), // 持续时间，可根据需要调整
          ));
        return;
      } 
      // 4. 获取硬件和软件版本字符串
      String hardwareStr = binNameStrs[0];
      String softwareStr = binNameStrs[1];
      // 5. 转换为字节数组（使用 UTF-8 编码，对应 C# 的 Encoding.Default）
      List<int> hardwareArray = utf8.encode(hardwareStr);
      List<int> softwareArray = utf8.encode(softwareStr);
      // 计算总长度：4（头部） + 硬件版本长度 + 软件版本长度+2(crc)
      int totalLength = 4 + hardwareArray.length + softwareArray.length;
      List<int> vhCheckData = List<int>.filled(totalLength, 0, growable: true);
      // 填充头部数据
      vhCheckData[0] = BmsCmd.cmdAddress;
      vhCheckData[1] = 0xF2;
      vhCheckData[2] = hardwareArray.length;
      vhCheckData[3] = softwareArray.length;
      // 填充硬件版本数据（从索引4开始）
      for (int i = 0; i < hardwareArray.length; i++) {
        vhCheckData[4 + i] = hardwareArray[i];
      }
      // 填充软件版本数据（从索引 4 + hardwareArray.length 开始）
      for (int i = 0; i < softwareArray.length; i++) {
        vhCheckData[4 + hardwareArray.length + i] = softwareArray[i];
      }
    List<int> crc = calculateCRC16(vhCheckData);
    vhCheckData.addAll(crc);
    // 将数据转成 Int8List 并发送到下位机
    Int8List data = Int8List.fromList(vhCheckData);
    await Future.delayed(Duration(milliseconds: 200));
    await writecmd(data);
    otaTimer = Timer(Duration(seconds: 60), () {
      setState(() {
        otaTimeout = true;
      });
    });
  }

  stepA3() async {
    try {

      List<int> crcOtaSource = calculateCRC16(otaSource!);
      List<int> sourcelenarr=intTo4BytesBigEndian(otaSource!.length);
      if(crcOtaSource.length<2 || sourcelenarr.length<4)
      {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('file length error'),
            duration: Duration(seconds: 1), // 持续时间，可根据需要调整
          ));
        return;
      }
      // 发起起始传输
      List<int> cmdOfA3 = [BmsCmd.cmdAddress, 0xF3, sourcelenarr[0], sourcelenarr[1], sourcelenarr[2], sourcelenarr[3], crcOtaSource[0], crcOtaSource[1]];
      List<int> crc = calculateCRC16(cmdOfA3);
      cmdOfA3.addAll(crc);
      // 将数据转成 Int8List 并发送到下位机
      Int8List data = Int8List.fromList(cmdOfA3);
      await Future.delayed(Duration(milliseconds: 200));
      await writecmd(data);
      otaTimer = Timer(Duration(seconds: 60), () {
        setState(() {
          otaTimeout = true;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('升级stepA3退出->$e'),
        duration: Duration(seconds: 2), // 持续时间，可根据需要调整
      ));
    }
  }

  stepA4() async {
    try {
      List<Uint8List> chunks = getChunks();
      Uint8List chunk = chunks[chunkIdx];
      int chunkSize = chunk.length;
      List<int> source = chunk;
      List<int> cmdOfA4 = [
        BmsCmd.cmdAddress,
        0xF4,
        ...sixteenToEight(chunkIdx + 1),
        ...sixteenToEight(chunkSize),
        ...source
      ];
      List<int> crc = calculateCRC16(cmdOfA4);
      cmdOfA4.addAll(crc);

      // 将数据转成 Int8List 并发送到下位机
      Int8List data = Int8List.fromList(cmdOfA4);
      await Future.delayed(Duration(milliseconds: 1));
      await writecmd(data);

      otaResendTimer=Timer(Duration(seconds: 1), () {
          stepA4();
      });

      if (chunkIdx == 0) {
        otaTimer = Timer(Duration(seconds: 60), () {
          setState(() {
            otaTimeout = true;
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('退出升级->$e'),
        duration: Duration(seconds: 2), // 持续时间，可根据需要调整
      ));
    }
  }

  stepA5() async {
    // 数据传输结束
    List<int> cmdOfA5 = [BmsCmd.cmdAddress, 0xF5, 0x10, 0x01];
    List<int> crc = calculateCRC16(cmdOfA5);
    cmdOfA5.addAll(crc);

    // 将数据转成 Int8List 并发送到下位机
    Int8List data = Int8List.fromList(cmdOfA5);
    await Future.delayed(Duration(milliseconds: 200));
    await writecmd(data);
    await Future.delayed(Duration(milliseconds: 200));
    /*
    Timer(Duration(milliseconds: 200), () {
        writecmd(data);
    });
    */
    otaTimer = Timer(Duration(seconds: 60), () {
      setState(() {
        otaTimeout = true;
      });
    });
  }

  // 更新上传进度
  void updateUploadSchedule(double value) {
    uploadSchedule.value = value;
  }

  // 获取数据切片，切片大小为 chunkSize 字节 发送多的又可能接收不到完整数据
  List<Uint8List> getChunks() {
    int chunkSize = 256;
    List<Uint8List> chunks = splitUint8List(otaSource!, chunkSize);
    return chunks;
  }

  // 在适当的位置调用文件选择器
  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        otaFilePath = file.path;
        otaFileName = file.name;
      });
    }
  }

  // 读取本地文件信息
  Future loadBinaryFile(String path) async {
    try
    {
       ByteData? data = await loadfile(path);
       if(data!=null)
       {
         Uint8List source = data.buffer.asUint8List();
          int bytes = data.lengthInBytes;
          setState(() {
            otaSource = source;
            otaBytes = bytes;
          });
       }
    }
    catch (e) 
    {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('捕获到异常: $e'),
          duration: Duration(seconds: 2), // 持续时间，可根据需要调整
        )
      );
    }
  }

  Future<ByteData?> loadfile(String filePath) async {
    try {
      // 1. 创建 File 对象
      File file = File(filePath);
      
      // 2. 检查文件是否存在
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return null;
      }
      
      // 3. 读取为 Uint8List
      Uint8List bytes = await file.readAsBytes();
      
      // 4. 转换为 ByteData
      ByteData byteData = ByteData.sublistView(bytes);
      
      return byteData;
    } catch (e) {
      print('读取文件失败: $e');
      return null;
    }
  }

   // 蓝牙发送
  Future writecmd(List<int> data, {bool needAck = true}) async {
    final writechar = ref.read(bleStateProvider).characteristic;
    try {
      if(writechar==null)
      {
        print("writecmd:writechar=null");
        await Future.delayed(Duration(milliseconds: 10));
      }
      //print("mtu:${writechar.device.mtu}");
      await writechar!.write(data, withoutResponse: needAck);
      
    } catch (e) {
      print(e);
    }
  }

  // 计算 crc16
  List<int> calculateCRC16(List<int> data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data[i] & 0xFF;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x0001) == 1) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
    }
    int crcInt8High = crc & 0xFF;
    int crcInt8Low = crc >> 8;

    return [crcInt8High, crcInt8Low];
  }

  // 将十进制数转换为十六进制字符串，并补齐为8位（32位二进制）
  String decimalToHex(int decimal) {
    String hexString = decimal.toRadixString(16).toUpperCase();
    return hexString.padLeft(8, '0'); // 补齐为8位
  }

// 将十六进制字符串按指定长度分割
  List<String> splitHexString(String hexString, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < hexString.length; i += chunkSize) {
      chunks.add(hexString.substring(i, i + chunkSize));
    }
    return chunks;
  }

  List<int> sixteenToEight(int num) {
    int int8High = num >> 8;
    int int8Low = num & 0xFF;

    return [int8High, int8Low];
  }

  int eightToSixteen(int num, int num1) {
    int ret = (num << 8) + num1;

    return ret;
  }

  // 分割 Uint8List 的函数
  List<Uint8List> splitUint8List(Uint8List list, int chunkSize) {
    List<Uint8List> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      int end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(Uint8List.sublistView(list, i, end));
    }
    return chunks;
  }

  // ota 升级弹窗
  void showOtaDialog(BuildContext context) {
    AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.info,
        headerAnimationLoop: false,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: AppColor.backgroud,
        dismissOnBackKeyPress: false,
        btnOkColor: AppColor.primary,
        btnOkText: S.of(context).confirm,
        body: ValueListenableBuilder<double>(
            valueListenable: uploadSchedule,
            builder: (context, value, child) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
                  child: Column(
                    children: [
                      customTitleText(
                          value >= 1
                              ? S.of(context).otaDone
                              : S.of(context).otaUpgrading,
                          color: Colors.white),
                      SizedBox(height: 10),
                      customText(S.of(context).otaUpdateTips),
                      customText(
                          "${S.of(context).progress}：${(value * 100).toInt()}%"),
                      GFProgressBar(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          lineHeight: 20,
                          percentage: value,
                          backgroundColor: Colors.black26,
                          progressBarColor: GFColors.SUCCESS),
                    ],
                  ));
            }),
        autoDismiss: false,
        onDismissCallback: (type) {},
        btnOkOnPress: () {
          if (uploadSchedule.value >= 1) {
            resetOtaStatus();
            context.pop();
            GFToast.showToast(
              S.of(context).otaDoneTips,
              context,
            );
          } else {
            GFToast.showToast(
              S.of(context).otaUpgradingTips,
              context,
            );
          }
        }).show();
  }


  @override
  Widget build(BuildContext context) {
    final isConnect = ref.watch(bleStateProvider.select((s) => s.characteristic!=null && s.characteristic!.device.isConnected));
    return Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          title: customTitleText(S.of(context).settingPage),
          centerTitle: true,
          backgroundColor: Colors.transparent, // AppBar 透明
          elevation: 0, // 移除底部阴影，否则会有灰色分层
        ),
        body: CustomBackground(child:ListView(
          padding: EdgeInsets.only(bottom: 16),
          children: [
            GFCard(
                color: AppColor.backgroud,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                              border: Border(
                              )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              customText(S.of(context).importOtaFile,
                                  style: TextStyles.textStyle14),
                              GFButton(
                                  onPressed: () async {
                                    if (!isConnect) {
                                      GFToast.showToast(
                                        S.of(context).deviceTips,
                                        context,
                                      );

                                      return;
                                    }

                                    pickFile();
                                  },
                                  color: AppColor.primary,
                                  text: isConnect
                                      ? S.of(context).select
                                      : S.of(context).noConnected,
                                  shape: GFButtonShape.pills,
                                  size: GFSize.SMALL),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            Visibility(//手动升级
              visible: otaFilePath != null,
              child: GFCard(
                color: AppColor.backgroud,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        customText(S.of(context).otaManulUpgrade,
                            style: TextStyles.textStyle14),
                        GFButton(
                            onPressed: () async {
                              startOta(otaFilePath!, true);
                            },
                            color: AppColor.primary,
                            text: S.of(context).upgrade,
                            shape: GFButtonShape.pills,
                            size: GFSize.SMALL),
                      ],
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppColor.darkGrey))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                                "${S.of(context).fileName}：${otaFileName ?? ''}",
                                maxLines: null,
                                overflow: TextOverflow.visible,
                                style: TextStyles.textStyle14),
                                
                          ),)
                          
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        )));
  }
}
