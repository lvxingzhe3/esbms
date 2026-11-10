import 'dart:async';

import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/ui/page/bluetooth/utils/extra.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './utils/snackbar.dart';
import './widgets/scan_result_tile.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  SharedPreferenceHelper prefs = SharedPreferenceHelper();
  //0000FEE700001000800000805F9B34FB
  //Guid targetScanService = Guid("0000fee7-0000-1000-8000-00805f9b34fb");
  Guid targetScanService = Guid("fee7");
  final String targetServiceUUID = 'fee7';
  final String targetReadUUID = 'fed6';
  final String targetCharacteristicUUID = 'fed5';
  final String targetDevicPrefix = "SSL";
  bool bmDevConnected = false;
  BluetoothDevice? connectedDevice; // 已连接过的设备
  List<ScanResult> scannedResult = []; // 已扫描结果

  List<BluetoothDevice> get scannedDevices {
    try {
      List<BluetoothDevice> devices = scannedResult
          .where((r) => r.advertisementData.connectable)
          .map((r) => r.device)
          .toList();
      if (connectedDevice != null &&
          !devices.any((d) => d.remoteId == connectedDevice!.remoteId)) {
        devices.insert(0, connectedDevice!);
      }
/*
      //目标蓝牙
      final targetList = devices.where((dev) {
        String n = dev.platformName;
        return n.startsWith(targetDevicPrefix);
      }).toList();

      // 其他设备
      final otherList = devices.where((dev) {
        String n = dev.platformName;
        return !(n.startsWith(targetDevicPrefix));
      }).toList();

      // 合并：目标在前
      List<BluetoothDevice> sortedList = [...targetList, ...otherList];
        if (connectedDevice != null &&
        !sortedList.any((d) => d.remoteId == connectedDevice!.remoteId)) {
      sortedList.insert(0, connectedDevice!);
      
    }
    */
      return devices;
    } catch (e) {
      print("scannedDevices->$e");
      return [];
    }
  } // 已扫描设备

  @override
  void initState() {
    super.initState();

    _loadLastConnectedDevice();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static String? lastDeviceId = "";
  // 从 SharedPreferences 中加载上次连接的设备
  Future<void> _loadLastConnectedDevice() async {
    lastDeviceId = await prefs.getLastDeviceId();

    try {
      // 获取上次已连接的设备
      BluetoothDevice device = await FlutterBluePlus.connectedDevices
          .firstWhere((d) => d.remoteId.toString() == lastDeviceId);

      setState(() {
        connectedDevice = device;
      });
      print('已获取上次已连接设备');
    } catch (e) {
      print('无法获取上次已连接设备: $e');
    }

    _startScan();
  }

  // 扫描附近的蓝牙设备
  Future<void> _startScan() async {
    FlutterBluePlus.startScan(
        //withServices: [Guid("1801"), targetScanService],
        timeout: Duration(seconds: 5),
        androidUsesFineLocation: true);
    FlutterBluePlus.scanResults.listen((results) {
      scannedResult.clear();
      for (var r in results) {
        if (r.device.advName.startsWith(targetDevicPrefix)) {
          scannedResult.add(r);
        }
      }
      //scannedResult = results;
      if (mounted) {
        setState(() {});
      }
    });

    return Future.delayed(Duration(milliseconds: 500));
  }

  // 保存已连接的设备信息到 SharedPreferences
  Future<void> _saveConnectedDevice(BluetoothDevice device) async {
    await prefs.saveLastDeviceId(device.remoteId.toString());
    lastDeviceId = device.remoteId.toString();
  }

  // 清除已连接的设备信息
  Future<void> _clearConnectedDevice() async {
    lastDeviceId = '';
    connectedDevice = null;
    await prefs.saveLastDeviceId('');
  }

  // 连接设备
  void _connectToDevice(BluetoothDevice device) async {
    await device.connectAndUpdateStream();
    setState(() {
      connectedDevice = device;
    });
    // 连接服务
    await discoverServices(device);
    // 保存bms设备信息
    if (bmDevConnected) {
      print('连接到BMS设备: ${device.advName} (${device.remoteId})');
    }
    await _saveConnectedDevice(device);
  }

  // 断开设备
  void _disconnectToDevice(BluetoothDevice device) async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      ref.read(bleStateProvider.notifier).setCharacteristic(null, null);
      _clearConnectedDevice();
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  // 文件读写
  Future writeAndRead(List<int> data) async {
    final c = ref.read(bleStateProvider).characteristic;
    try {
      await c!.write(data);
    } catch (e) {
      print(e);
    }
  }

  // 识别 targetUUID
  Future discoverServices(BluetoothDevice device) async {
    try {
      bmDevConnected = false;
      List<BluetoothService> _services = await device.discoverServices();
      BluetoothCharacteristic? foundWriteChar;
      BluetoothCharacteristic? foundNotifyChar;
      for (BluetoothService service in _services) {
        // 查找指定服务特征
        if (service.uuid.toString() == targetServiceUUID) {
          List<BluetoothCharacteristic> characteristics =
              service.characteristics;
          for (BluetoothCharacteristic characteristic in characteristics) {
            if (characteristic.uuid.toString() == targetReadUUID) {
              foundNotifyChar = characteristic;
              // 订阅通知
              //await characteristic.setNotifyValue(true);
            }
            // 查找指定读写特征
            if (characteristic.uuid.toString() == targetCharacteristicUUID) {
              foundWriteChar = characteristic;
              bmDevConnected = true;
              break;
            }
          }
          break;
        }
      }
      ;
      // 初始化 characteristic 为连接设备
      if (mounted) {
        ref
            .read(bleStateProvider.notifier)
            .setCharacteristic(foundWriteChar, foundNotifyChar, device);
      }
    } catch (e) {
      Snackbar.show(
        ABC.c,
        prettyException("Discover Services Error:", e),
        success: false,
      );
    }
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return scannedDevices
        .map(
          (d) => ScanResultTile(
            key: Key(d.remoteId.toString()),
            device: d,
            //modify:() => _modifyBluetoothDevice(d),
            onTap: () => _connectToDevice(d),
            onStop: () => _disconnectToDevice(d),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // 缓存 context
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: CustomAppBar(
          isBackButton: true,
          title: customTitleText(
            S.current.deviceList,
            color: AppColor.primary,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _startScan,
          child: ListView(
            children: <Widget>[..._buildScanResultTiles(context)],
          ),
        ),
      ),
    );
  }
}
