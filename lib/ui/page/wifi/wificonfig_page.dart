import 'dart:io';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({super.key});

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  final TextEditingController _wifiNameCtrl = TextEditingController();
  final TextEditingController _wifiPwdCtrl = TextEditingController();
  bool _pwdVisible = false;
  bool _isScanning = false;

  Future<void> _onSearchWifiTap() async {
    if (Platform.isAndroid) {
      // ==========安卓：扫描附近全部WiFi列表==========
      final status = await Permission.nearbyWifiDevices.request();
      if (!status.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("需要附近设备权限才能扫描WiFi")));
        return;
      }
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("无法扫描WiFi：$canScan")));
        return;
      }
      setState(() => _isScanning = true);
      await WiFiScan.instance.startScan();
      final canGetResult = await WiFiScan.instance.canGetScannedResults();
      List<WiFiAccessPoint> apList = [];
      if (canGetResult == CanGetScannedResults.yes) {
        apList = await WiFiScan.instance.getScannedResults();
      }
      setState(() => _isScanning = false);
      if (!mounted) return;
      // 过滤空SSID、去重，并且只保留2.4G（2400~2500MHz）
      final unique24GWifi = apList
          .where((ap) => ap.ssid.isNotEmpty && ap.frequency >= 2400 && ap.frequency <= 2500)
          .map((ap) => ap.ssid)
          .toSet()
          .toList();

      final selectedSsid = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: const Text("选择Wi-Fi（仅2.4G）",style:TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600,color: AppColor.primary)),
          content: SizedBox(
            width: double.maxFinite,
            child: _isScanning
                ? const Center(child: CircularProgressIndicator())
                : unique24GWifi.isEmpty
                    ? const Text("未扫描到2.4G WiFi，请检查WiFi开关和权限",style:TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600,color: AppColor.primary))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: unique24GWifi.length,
                        itemBuilder: (context, index) {
                          final ssid = unique24GWifi[index];
                          return ListTile(title: Text(ssid),textColor: AppColor.white, onTap: () => Navigator.pop(ctx, ssid));
                        },
                      ),
          ),
        ),
      );
      if (selectedSsid != null) {
        setState(() => _wifiNameCtrl.text = selectedSsid);
      }
    } else if (Platform.isIOS) {
      // ==========iOS：只能读取当前已连接WiFi，无法扫描周边WiFi==========
      final locPerm = await Permission.locationWhenInUse.request();
      if (!locPerm.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("定位权限用于读取当前WiFi名称")));
        return;
      }
      final info = NetworkInfo();
      String? currentSsid = await info.getWifiName();
      if (!mounted) return;
      if (currentSsid == null || currentSsid.isEmpty) {
        await showDialog(
          context: context,
          builder: (ctx) => const AlertDialog(
            title: Text("提示"),
            content: Text("iOS系统限制，无法扫描周围WiFi，当前未获取到已连接WiFi，请手动输入2.4G WiFi名称"),
          ),
        );
        return;
      }
      // 弹出确认框，回填当前WiFi
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("当前WiFi"),
          content: Text("检测到当前连接WiFi：$currentSsid\n\n⚠️请确认是2.4GHz WiFi，5G无法配网"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("使用此WiFi")),
          ],
        ),
      );
      if (confirm == true) {
        setState(() {
          _wifiNameCtrl.text = currentSsid;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customText("Wi-Fi配置", style: TextStyles.textStyle16), 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customText("ID", style: TextStyles.textStyle16), 
            const SizedBox(height: 32),
            TextField(
              controller: _wifiNameCtrl,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: "Wi-Fi名称:",
                labelStyle: const TextStyle(fontSize: 16, color: Colors.white54),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _wifiNameCtrl.clear(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                    IconButton(
                      onPressed: _onSearchWifiTap,
                      icon: const Icon(Icons.search, color: Colors.white54),
                    ),
                  ],
                ),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _wifiPwdCtrl,
              obscureText: !_pwdVisible,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: "Wi-Fi密码:",
                labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _pwdVisible = !_pwdVisible),
                  icon: Icon(_pwdVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                ),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                ),
                onPressed: () {
                  // 提交配网， _wifiNameCtrl.text 、 _wifiPwdCtrl.text
                },
                child: const Text("设置", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "1. 请确保您的Wi-Fi路由器是打开的，若连接失败，可检查路由器是否对联网设备数量有限制",
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xfffff8dc), borderRadius: BorderRadius.circular(12)),
              child: const Text(
                "此设备只支持连接2.4GHz Wi-Fi, 选择5GHz Wi-Fi会导致设置设备失败!",
                style: TextStyle(fontSize: 15, color: Color(0xffbc8c00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
