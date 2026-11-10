import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/topsnackbar.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/ui/page/device/scanqrpage.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class AddDevicePage extends ConsumerStatefulWidget {
  const AddDevicePage({super.key});

  @override
  ConsumerState<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends ConsumerState<AddDevicePage> {
  // 表单控制器
  final TextEditingController _dtuIdController =
      TextEditingController(text: "");
  final TextEditingController _deviceNameController = TextEditingController();
  late TextEditingController _companyInputCtrl;
  //加载
  bool _isLoading = false;
  bool _isSubmitting = false;
  // 下拉公司列表
  List<ResDateItem> _companyTypeList = [];
  String? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _companyInputCtrl = TextEditingController();
    _readCompanies();
  }

  @override
  void dispose() {
    _dtuIdController.dispose();
    _deviceNameController.dispose();
    _companyInputCtrl.dispose();
    super.dispose();
  }

// 返回：纬度、经度、国家名称
  Future<Map<String, dynamic>> getLocationInfo() async {
    try {
      // 权限检查
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {"latitue": null, "longitude": null, "country": null};
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return {"latitue": null, "longitude": null, "country": null};
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ✅ 改这个
        timeLimit: const Duration(seconds: 5), // ✅ 增加超时，防止卡死
      );
      final lat = pos.latitude;
      final lng = pos.longitude;

      List<Placemark> placeList = await placemarkFromCoordinates(lat, lng);
      Placemark? place;
      if (placeList.isNotEmpty) {
        place = placeList.first;
      }
      final country = place?.country; // 国家名称（中文：中国）

      return {
        "latitue": lat,
        "longitude": lng,
        "country": country,
      };
    } catch (e) {
      print("获取位置失败：$e");
      return {"latitue": null, "longitude": null, "country": null};
    }
  }

  //读取公司列表
  Future<void> _readCompanies() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final apiService = ref.read(apiServiceProvider);
      final paramrec = await apiService.getstationlist();
      final apiparamRes = ApiResponse.fromJson(paramrec);
      if (apiparamRes.code == 0) {
        final data = apiparamRes.data["list"];
        final reclist = data
            .map<ResDateItem>(
                (e) => ResDateItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _companyTypeList = reclist;
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 扫描DTU ID
  Future<void> _scanDtuId() async {
    final String? qrResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrPage()),
    );
    if (qrResult != null && qrResult.isNotEmpty) {
      setState(() {
        _dtuIdController.text = qrResult;
      });
    }
  }

  // 提交保存
  Future<void> _submitForm() async {
    if (_isSubmitting) return; // ✅ 防重复点击
    setState(() {
      _isSubmitting = true;
    });
    try {
      // 简单校验
      if (_dtuIdController.text.trim().isEmpty ||
          _deviceNameController.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Fill in all")));
        }
        return;
      }
      String devname = _deviceNameController.text;
      String dutId = _dtuIdController.text.trim();

      if (_companyTypeList.isNotEmpty) {
        if (_selectedCompanyId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Select company")));
          }
          return;
        }
        final apiService = ref.read(apiServiceProvider);
        final paramrec =
            await apiService.adddevice(devname, dutId, _selectedCompanyId!);
        final apiparamRes = ApiResponse.fromJson(paramrec);
        if (apiparamRes.code == 0) {
          if (context.mounted) {
            TopSnackBar.show(
              context,
              S.of(context).adddevicesuccess,
              backgroundColor: AppColor.info,
              icon: Icons.check_circle,
              duration: const Duration(seconds: 2),
            );
          }
          // ✅ 延时等弹窗展示完再关闭页面
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.pop(true);
          }
        } else {
          if (context.mounted) {
            TopSnackBar.show(
              context,
              apiparamRes.localMessage!,
              backgroundColor: AppColor.warn,
              icon: Icons.error,
              duration: const Duration(seconds: 2),
            );
          }
        }
      } else {
        String staionname = _companyInputCtrl.text.trim();
        if (staionname.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill in company name")));
          }
          return;
        }

        final latitue = "30.368683161885968";
        final longitude = "121.68808487801188";
        final country = "中国";
        final apiService = ref.read(apiServiceProvider);
        final paramrec = await apiService.adddeviceandstation(
            devname, dutId, staionname, country, latitue, longitude);
        final apiparamRes = ApiResponse.fromJson(paramrec);
        if (apiparamRes.code == 0) {
          if (context.mounted) {
            TopSnackBar.show(
              context,
              S.of(context).adddevicesuccess,
              backgroundColor: AppColor.info,
              icon: Icons.check_circle,
              duration: const Duration(seconds: 1),
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          if (context.mounted) {
            context.pop(true);
          }
        } else {
          if (context.mounted) {
            TopSnackBar.show(
              context,
              apiparamRes.localMessage!,
              backgroundColor: AppColor.warn,
              icon: Icons.error, // ✅ 修改错误图标
              duration: const Duration(seconds: 1),
            );
          }
        }
      }
    } catch (e) {
      print(e);
      if (context.mounted) {
        TopSnackBar.show(
          context,
          e.toString(),
          backgroundColor: AppColor.warn,
          icon: Icons.error,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
          title: customTitleText(S.of(context).adddevice,
              color: AppColor.primary)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColor.backgroud,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).deviceinfo,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),

                      // 1.设备类型下拉
                      _buildFormItem(
                        label: S.of(context).company,
                        child: _companyTypeList.isNotEmpty
                            ? DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCompanyId,
                                  isExpanded: true,
                                  items: _companyTypeList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item.id,
                                      child: Text(item.name),
                                    );
                                  }).toList(),
                                  onChanged: (newId) {
                                    if (newId == null) return;
                                    setState(() {
                                      _selectedCompanyId = newId;
                                    });
                                    final selectedItem = _companyTypeList
                                        .firstWhere((e) => e.id == newId);
                                    debugPrint(
                                        "选中：${selectedItem.name} , id:${selectedItem.id}");
                                  },
                                ),
                              )
                            : TextField(
                                controller: _companyInputCtrl,
                                decoration: InputDecoration(
                                  labelStyle:
                                      const TextStyle(color: Colors.white38),
                                  hintStyle:
                                      const TextStyle(color: Colors.white38),
                                  hintText: S.of(context).company,
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              ),
                      ),

                      const Divider(height: 1, color: Colors.grey),

                      //2. DTU ID 带复制图标
                      _buildFormItem(
                        label: "DTU ID",
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dtuIdController,
                                decoration: const InputDecoration(
                                  labelStyle:
                                      const TextStyle(color: Colors.white38),
                                  hintStyle:
                                      const TextStyle(color: Colors.white38),
                                  border: InputBorder.none,
                                  hintText: "DTU ID",
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _scanDtuId,
                              icon: const Icon(Icons.qr_code_scanner,
                                  color: Colors.blue),
                            )
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Colors.grey),

                      //3.设备名称
                      _buildFormItem(
                        label: S.of(context).deviceName,
                        child: TextField(
                          controller: _deviceNameController,
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.white38),
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            hintText: S.of(context).deviceName,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: Text(S.of(context).adddevice),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 封装表单行组件，左边label，右边输入控件，底部分割线
  Widget _buildFormItem({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 5,
            child: child,
          ),
        ],
      ),
    );
  }
}

class ResDateItem {
  final String id;
  final String name;

  ResDateItem({
    required this.id,
    required this.name,
  });

  factory ResDateItem.fromJson(Map<String, dynamic> json) {
    return ResDateItem(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
