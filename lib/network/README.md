# 网络请求模块使用指南

本模块基于 `dio` 和 `riverpod` 封装，提供统一的 HTTP 请求管理。

## 📁 文件结构

```
lib/network/
├── api_exception.dart    # API 异常定义
├── dio_client.dart       # Dio 客户端封装
├── dio_provider.dart     # Riverpod Provider 定义
├── api_service.dart      # API 服务示例
└── README.md            # 使用文档
```

## 🚀 快速开始

### 1. 配置 Base URL

修改 `lib/network/dio_provider.dart` 中的 `baseUrl`：

```dart
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: 'https://your-api.example.com', // 替换为实际 API 地址
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );
});
```

### 2. 基本使用

#### 方式 1：直接使用 DioClient（推荐）

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bms_app/network/dio_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dioClient = ref.watch(dioClientProvider);

    return ElevatedButton(
      onPressed: () async {
        try {
          final response = await dioClient.get('/api/users');
          print(response.data);
        } catch (e) {
          print('Error: $e');
        }
      },
      child: Text('获取用户列表'),
    );
  }
}
```

#### 方式 2：使用 ApiService

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bms_app/network/dio_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiService = ref.watch(apiServiceProvider);

    return ElevatedButton(
      onPressed: () async {
        try {
          final userInfo = await apiService.getUserInfo('123');
          print(userInfo);
        } catch (e) {
          print('Error: $e');
        }
      },
      child: Text('获取用户信息'),
    );
  }
}
```

## 📖 API 示例

### GET 请求

```dart
final dioClient = ref.watch(dioClientProvider);

// 简单 GET
final response = await dioClient.get('/api/users');

// 带查询参数
final response = await dioClient.get(
  '/api/users',
  queryParameters: {
    'page': 1,
    'limit': 10,
  },
);
```

### POST 请求

```dart
final response = await dioClient.post(
  '/api/user',
  data: {
    'name': 'John',
    'email': 'john@example.com',
  },
);
```

### PUT 请求

```dart
final response = await dioClient.put(
  '/api/user/123',
  data: {
    'name': 'Jane',
  },
);
```

### DELETE 请求

```dart
final response = await dioClient.delete('/api/user/123');
```

### 文件上传（带进度）

```dart
final response = await dioClient.upload(
  '/api/upload',
  filePath: '/path/to/file.jpg',
  fileKey: 'file',
  data: {
    'description': 'My file',
  },
  onSendProgress: (sent, total) {
    print('上传进度: ${(sent / total * 100).toStringAsFixed(0)}%');
  },
);
```

### 文件下载（带进度）

```dart
await dioClient.download(
  '/api/download/file.pdf',
  '/path/to/save/file.pdf',
  onReceiveProgress: (received, total) {
    print('下载进度: ${(received / total * 100).toStringAsFixed(0)}%');
  },
);
```

### 取消请求

```dart
final cancelToken = CancelToken();

// 发起请求
dioClient.get('/api/users', cancelToken: cancelToken);

// 取消请求
cancelToken.cancel('用户取消');
```

## 🔐 Token 管理

### 设置 Token

```dart
final dioClient = ref.watch(dioClientProvider);
dioClient.setAuthToken('your-jwt-token');
```

### 清除 Token

```dart
dioClient.clearAuthToken();
```

### 自定义请求头

```dart
dioClient.setHeaders({
  'Custom-Header': 'value',
  'Another-Header': 'value2',
});
```

## 🔧 创建自己的 Service

### 1. 创建 Service 类

```dart
// lib/network/device_service.dart
import 'package:bms_app/network/dio_client.dart';

class DeviceService {
  final DioClient _dioClient;

  DeviceService(this._dioClient);

  /// 获取设备状态
  Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async {
    try {
      final response = await _dioClient.get('/api/device/$deviceId/status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 上传设备数据
  Future<bool> uploadDeviceData(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dioClient.post('/api/device/$deviceId/data', data: data);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
```

### 2. 创建 Provider

```dart
// lib/network/dio_provider.dart 中添加
import 'package:bms_app/network/device_service.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DeviceService(dioClient);
});
```

### 3. 在页面中使用

```dart
class DevicePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceService = ref.watch(deviceServiceProvider);

    return FutureBuilder(
      future: deviceService.getDeviceStatus('device-123'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('设备状态: ${snapshot.data}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## 🛠️ 错误处理

所有请求都会自动转换为 `ApiException`：

```dart
import 'package:bms_app/network/api_exception.dart';

try {
  final response = await dioClient.get('/api/users');
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // 未授权，跳转登录
    print('请重新登录');
  } else if (e.statusCode == 404) {
    // 资源未找到
    print('资源未找到');
  } else {
    // 其他错误
    print('错误: ${e.message}');
  }
}
```

### 错误类型

- `ApiException.networkError()` - 网络连接失败
- `ApiException.timeout()` - 请求超时
- `ApiException.cancelled()` - 请求取消
- `ApiException.unauthorized()` - 401 未授权
- `ApiException.notFound()` - 404 未找到
- `ApiException.serverError()` - 服务器错误

## 📝 日志

所有请求和响应都会自动打印日志：

```
🚀 REQUEST[GET] => PATH: https://api.example.com/users
🚀 Headers: {Authorization: Bearer xxx}
✅ RESPONSE[200] => PATH: https://api.example.com/users
✅ Data: {...}
```

在生产环境中，可以在 `dio_client.dart` 中移除 `_LogInterceptor` 以关闭日志。

## 🎯 最佳实践

1. **使用 Provider 管理实例** - 通过 Riverpod Provider 获取 DioClient 和 Service
2. **创建独立的 Service** - 为不同模块创建独立的 Service 类
3. **统一错误处理** - 使用 ApiException 捕获和处理错误
4. **使用 CancelToken** - 在页面销毁时取消未完成的请求
5. **设置合理的超时** - 根据网络环境调整超时时间

## 🔗 相关链接

- [dio 官方文档](https://pub.dev/packages/dio)
- [flutter_riverpod 官方文档](https://pub.dev/packages/flutter_riverpod)
