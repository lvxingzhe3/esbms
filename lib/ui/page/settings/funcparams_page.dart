import 'dart:async';
import 'dart:typed_data';

import 'package:bms_app/event/ble_event.dart';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/model/paramitem.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FuncParamsPage extends ConsumerStatefulWidget {
  const FuncParamsPage({super.key});

  @override
  _FuncParamsPageState createState() => _FuncParamsPageState();
}

// 主页面
class _FuncParamsPageState extends ConsumerState<FuncParamsPage> {
  // 刷新控制器
  RefreshController? _refreshController;
  late PageController _pageController;
  int currentPage = 1;
  static const int pageSize = 10;
  int totalPage = 0;
  bool hasMore = true;
  // 所有参数数据
  late List<ParamItem> allParams = [];
  late List<ParamItem> params = [];
  StreamSubscription? _subscription;
  // 存储每个输入框的控制器
  Map<int, TextEditingController> _controllers = {};
  //加载
  bool _isLoading = false;
  //正在翻页
  bool _loadingPage = false;
  int roleNumm = 0;
  @override
  void initState() {
    super.initState();
    // 初始化创建
    _refreshController = RefreshController(initialRefresh: false);
    _pageController = PageController(initialPage: currentPage - 1);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await initPage();
    readParams();
  }

  @override
  void dispose() {
    // 释放控制器
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _subscription?.cancel();
    _refreshController?.dispose();
    super.dispose();
  }

  /// 初始化页面
  Future<void> initPage() async {
    try {
      final userState = ref.watch(userStateProvider);
      roleNumm = userState.role;
    } catch (e) {
      print("initPage->$e");
    }
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
      params[index].value = newValue;
    });
    _editController.text = newValue;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: Text('${params[index].name}'),
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
    try {
      setState(() {
        _isLoading = true;
        allParams = [];
        _controllers = {};
      });
      final apiService = ref.read(apiServiceProvider);

      var paramgrouprec =
          await apiService.getparamlistgroup(GlobalData.currentDeviceId!);
      var apiparamgroupRes = ApiResponse.fromJson(paramgrouprec);
      List<dynamic> groups = apiparamgroupRes.data["attributesGroups"] ?? [];
      final targetgroup = groups.firstWhere(
          (group) => group['key'] == 'coil_module_set',
          orElse: () => null);
      final attributes = targetgroup["attributes"] ?? [];
      final List<Map<String, String>> groupparams =
          attributes.map<Map<String, String>>((attr) {
        return {
          'key': attr['key']?.toString() ?? '',
          'name': attr['name']?.toString() ?? '',
        };
      }).toList();

      paramgrouprec =
          await apiService.getparamlistgroup(GlobalData.currentDeviceId!);
      apiparamgroupRes = ApiResponse.fromJson(paramgrouprec);
      groups = apiparamgroupRes.data["attributesGroups"] ?? [];
      final targetgroup2 = groups.firstWhere(
          (group) => group['key'] == 'coil_protection_set',
          orElse: () => null);
      final attributes2 = targetgroup2["attributes"] ?? [];
      final List<Map<String, String>> groupparams2 =
          attributes2.map<Map<String, String>>((attr) {
        return {
          'key': attr['key']?.toString() ?? '',
          'name': attr['name']?.toString() ?? '',
        };
      }).toList();

      List<Map<String, String>> groupparamsRes = [
        ...groupparams,
        ...groupparams2
      ];

      final paramrec =
          await apiService.getparamlist(GlobalData.currentDeviceId!);
      final apiparamRes = ApiResponse.fromJson(paramrec);
      if (apiparamRes.code == 0) {
        final devparamjson = apiparamRes.data as Map<String, dynamic>;

        devparamjson.forEach((key, value) {
          final Map<String, dynamic> param = value as Map<String, dynamic>;
          if (groupparamsRes.any((item) => item['key'] == param['key'])) {
            allParams.add(ParamItem(
              key: param['key'].toString(),
              name: param['name'].toString(),
              value: param['value'].toString(),
              unit: param['unit'].toString(),
            ));
          }
        });

        setState(() {
          totalPage = (allParams.length / pageSize).ceil();
          _loadPageData();
        });
      }
    } catch (e) {
      print("readParams->$e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //修改参数
  Future<void> sendParamCmd(int index, String value) async {
    try {
      String key = params[index].key;
      final apiService = ref.read(apiServiceProvider);
      final paramrec =
          await apiService.setparam(GlobalData.currentDeviceId!, key, value);
      final apiparamRes = ApiResponse.fromJson(paramrec);
      if (apiparamRes.code == 0) {
        params[index].value = value;
        setState(() {
          _controllers[index]?.text = params[index].value;
        });
      }
    } catch (e) {}
  }

// 开关点击事件
  Future<void> _onSwitchChanged(int index, String newValue) async {
    try {
      String key = params[index].key;
      final apiService = ref.read(apiServiceProvider);
      final paramrec =
          await apiService.setparam(GlobalData.currentDeviceId!, key, newValue);
      final apiparamRes = ApiResponse.fromJson(paramrec);
      if (apiparamRes.code == 0) {
        params[index].value = newValue;
        setState(() {
          _controllers[index]?.text = params[index].value;
        });
      }
    } catch (e) {}
  }

  /// 截取分页数据，更新 params 和 textfield controller
  Future<void> _loadPageData() async {
    int start = (currentPage - 1) * pageSize;
    int end = start + pageSize;
    if (start >= totalPage * pageSize) {
      hasMore = false;
      return;
    }
    if (end > allParams.length) {
      end = allParams.length;
    }
    final List<ParamItem> newPageData = allParams.sublist(start, end);
    params = newPageData;
    /*
    if (currentPage == 1) {
      // 第一页：清空旧数据
      params = newPageData;
    } else {
      // 上拉加载：追加数据
      params.addAll(newPageData);
    }
    */
    // 初始化控制器
    _controllers = {};
    setState(() {
      for (int i = 0; i < params.length; i++) {
        _controllers[i] = TextEditingController(text: params[i].value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isBackButton: true,
        title:
            customTitleText(S.of(context).funcparam, color: AppColor.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ========== 顶部标题行 ==========
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color.fromARGB(255, 19, 89, 175),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          S.of(context).paramname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          S.of(context).operation,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== PageView.builder 原生左右滑动（有动画） ==========
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalPage, //总页数
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    onPageChanged: (int index) async {
                      if (_loadingPage) return;
                      _loadingPage = true;
                      try {
                        setState(() {
                          currentPage = index + 1;
                        });
                        _loadPageData();
                      } finally {
                        _loadingPage = false;
                      }
                    },
                    itemBuilder: (context, index) {
                      // 这里重点：每个页面内部新建独立RefreshController，不再共用！
                      return _buildParamListPage();
                    },
                  ),
                ),

                // ========== 底部分页按钮，联动PageView ==========
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: currentPage <= 1
                            ? null
                            : () async {
                                currentPage--;
                                await _loadPageData();
                              },
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text("上一页"),
                      ),
                      Text("第 $currentPage 页 / 共 $totalPage 页"),
                      TextButton.icon(
                        onPressed: currentPage >= totalPage
                            ? null
                            : () async {
                                currentPage++;
                                await _loadPageData();
                              },
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        label: const Text("下一页"),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  /// 构建参数列表页面，使用独立的RefreshController
  Widget _buildParamListPage() {
    // ✅ 局部变量：每次构建页面都会生成独立RefreshController，不会共用，消除断言报错
    final RefreshController refreshController =
        RefreshController(initialRefresh: false);
    return SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const ClassicHeader(
        refreshingText: "refreshing...",
      ),
      onRefresh: () async {
        // 下拉刷新逻辑：回到第1页，重新读取参数
        currentPage = 1;
        await readParams();
        // 【必须】通知控件刷新结束，收起loading
        refreshController.refreshCompleted();
      },
      child: ListView.builder(
        itemCount: params.length,
        itemBuilder: (context, index) {
          final param = params[index];
          // 1=打开 true；0=关闭 false
          bool switchValue = param.value == "1";

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      param.name ?? "",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  // ===== 替换为Switch开关 =====
                  SizedBox(
                    width: 60,
                    child: Switch(
                      value: switchValue,
                      onChanged: roleNumm == 0
                          ? (v) {}
                          : (bool val) async {
                              // 点击开关：更新内存数据，调用保存接口
                              String newVal = val ? "1" : "0";
                              param.value = newVal;
                              setState(() {});
                              await _onSwitchChanged(index, newVal);
                            },
                      inactiveThumbColor: null,
                      inactiveTrackColor: null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
