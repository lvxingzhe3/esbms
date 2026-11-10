import 'package:bms_app/state/location_state.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:bms_app/generated/l10n.dart';
import 'package:coordtransform/coordtransform.dart';

/// 地图页面 - 使用 OpenStreetMap (WGS84 坐标系)
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();

  /// 移动到指定位置
  void _moveToLocation(LatLng point) {
    _mapController.move(point, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    // 监听位置数据
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      appBar: CustomAppBar(
        isBackButton: true,
        title:
            customTitleText(S.of(context).deviceMap, color: AppColor.primary),
        //title:customText(S.of(context).deviceMap,style: TextStyles.textStyle14),
        //title: customTitleText('设备地图', color: AppColor.primary),
      ),
      body: locationAsync.when(
        // 加载中
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Search divece location...'),
            ],
          ),
        ),
        // 加载失败
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading fail',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // 重新加载
                  ref.invalidate(locationProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        // 加载成功，显示地图
        data: (center) {
          // 调用转换函数，得到 GCJ-02 坐标
          //final gcj02LatLng = wgs84ToGcj02(center.latitude, center.longitude);
          // WGS-84 转 GCJ-02
          final gcj02 = CoordTransform.transformBD09toGCJ02(
              center.longitude, center.latitude);
          LatLng displayCenter =
              LatLng(gcj02.lat, gcj02.lon); // [经度, 纬度] → [纬度, 经度]
          return Column(
            children: [
              // 🆕 新增：顶部经纬度信息卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColor.primary
                    .withValues(alpha: 0.1), // 使用你 AppColor 中的主色
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          customText(S.of(context).deviceLocation,
                              style: TextStyles.textStyleLight),
                          const SizedBox(height: 4),
                          Text(
                            '${S.of(context).latitude}: ${center.latitude.toStringAsFixed(8)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${S.of(context).longitude}: ${center.longitude.toStringAsFixed(8)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 复制按钮（可选）
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        // 复制经纬度到剪贴板
                        final data = '${center.latitude}, ${center.longitude}';
                        // 使用 Flutter 的 Clipboard 类
                        Clipboard.setData(ClipboardData(text: data));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copied'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 原有的地图部分
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: displayCenter,
                    initialZoom: 13.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      //  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      urlTemplate:
                          "https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}",
                      subdomains: ['1', '2', '3', '4'],
                      userAgentPackageName: 'Sinota esBMS',
                      tileProvider: NetworkTileProvider(),
                      maxZoom: 19,
                      errorImage:
                          const AssetImage('assets/images/launch_logo.png'),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: displayCenter,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // 浮动操作按钮 - 缩放和刷新控制
      floatingActionButton: locationAsync.when(
        data: (center) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 刷新位置
            FloatingActionButton(
              heroTag: 'refresh',
              mini: true,
              onPressed: () {
                ref.invalidate(locationProvider);
              },
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 8),
            // 放大
            FloatingActionButton(
              heroTag: 'zoom_in',
              mini: true,
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom + 1,
                );
              },
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            // 缩小
            FloatingActionButton(
              heroTag: 'zoom_out',
              mini: true,
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom - 1,
                );
              },
              child: const Icon(Icons.remove),
            ),
            const SizedBox(height: 8),
            // 回到设备位置
            FloatingActionButton(
              heroTag: 'center',
              mini: true,
              onPressed: () {
                _moveToLocation(center);
              },
              child: const Icon(Icons.my_location),
            ),
          ],
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

// WGS-84 转 GCJ-02 核心算法
  LatLng wgs84ToGcj02(double lat, double lng) {
    const double a = 6378245.0;
    const double ee = 0.00669342162296594323;

    double transformLat(double x, double y) {
      double ret = -100.0 +
          2.0 * x +
          3.0 * y +
          0.2 * y * y +
          0.1 * x * y +
          0.2 * sqrt(x.abs());
      ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
      ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
      ret +=
          (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
      return ret;
    }

    double transformLon(double x, double y) {
      double ret =
          300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
      ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
      ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
      ret +=
          (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
      return ret;
    }

    double dLat = transformLat(lng - 105.0, lat - 35.0);
    double dLon = transformLon(lng - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    double mgLat = lat + dLat;
    double mgLon = lng + dLon;
    return LatLng(mgLat, mgLon);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
