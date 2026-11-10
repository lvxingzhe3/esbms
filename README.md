# 昔诺达 BMS 电池管理系统

基于 Flutter 开发的电池管理系统（BMS）监控应用，通过蓝牙Wifi连接 BMS 设备实时显示电池数据。

## 项目信息

- **应用名称**：昔诺达储能BMS电池管理系统
- **包名**：com.snt.esbms
- **版本**：1.0.0+1
- **Flutter 版本**：3.32.4
- **Dart 版本**：3.8.1

## 技术栈

- **框架**：Flutter 3.32.4
- **状态管理**：Riverpod 2.6.1
- **路由管理**：go_router 16.2.0
- **蓝牙通信**：flutter_blue_plus 2.0.0
- **MQTT**：mqtt5_client 4.14.0
- **身份认证**：AWS Amplify (Cognito)
- **国际化**：flutter_intl (主要语言：中文，支持英文)

## 主要功能

- 📱 蓝牙扫描与设备连接
- 🔋 实时显示电池数据（电压、电流、温度、SOC 等）
- 📊 电芯电压监控
- 🌡️ 温度监测
- 🔄 固件升级（OTA）
- ⚙️ 设备设置管理
- 🌍 多语言支持（中文/英文）

## 开发环境设置

### 前置要求

- Flutter SDK 3.32.4 或更高版本
- Dart 3.8.1 或更高版本
- Android Studio / Xcode (用于移动端开发)
- Android SDK (minSdk 24, targetSdk 根据 Flutter 版本)

### 安装依赖

```bash
# 获取 Flutter 依赖
flutter pub get

# 生成应用图标
flutter pub run flutter_launcher_icons

# 生成国际化文件（如修改了 .arb 文件）
flutter pub run intl_utils:generate
```

## 常用命令

### 运行与调试

```bash
# 运行应用（连接设备或模拟器）
flutter run

# 运行在指定设备
flutter run -d <device_id>

# 热重载模式运行
flutter run --hot

# 查看可用设备
flutter devices
```

### 代码质量

```bash
# 运行静态代码分析
flutter analyze

# 运行测试
flutter test

# 运行指定测试文件
flutter test test/widget_test.dart

# 格式化代码
dart format lib/
```

### 构建应用

#### Android

```bash
# 清理构建缓存（推荐在构建前执行）
flutter clean

# 构建 APK（用于应用商店上架）
flutter build apk --release

# 构建 App Bundle（Google Play 推荐格式）
flutter build appbundle --release

# 构建 Debug APK（用于开发测试）
flutter build apk --debug

# 输出位置：
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
# 构建 iOS 应用
flutter build ios --release

# 构建 IPA 文件
flutter build ipa --release
```

#### macOS

```bash
# 构建 macOS 应用
flutter build macos --release
```

### 清理与维护

```bash
# 清理所有构建产物
flutter clean

# 更新 Flutter SDK
flutter upgrade

# 检查 Flutter 环境
flutter doctor

# 查看过时的依赖
flutter pub outdated

# 升级依赖到最新兼容版本
flutter pub upgrade
```

## Android 签名配置

项目已配置 release 签名，签名文件信息：

- **签名文件**：`android/app/upload-keystore.jks`
- **配置文件**：`android/key.properties`
- **密钥别名**：upload
- **签名算法**：SHA384withRSA (2048 位)
- **证书有效期**：2025 年 9 月 30 日 - 2053 年 2 月 15 日

构建 release 版本时会自动使用此签名，无需额外操作。

**⚠️ 安全提示：**

- `key.properties` 文件包含敏感信息，已加入 `.gitignore`
- `upload-keystore.jks` 应妥善保管，丢失将无法更新应用
- 建议定期备份签名文件到安全位置

## 应用商店上架流程

### 腾讯应用宝上架

#### 1. 构建 APK

```bash
# 清理并构建 release APK
flutter clean
flutter build apk --release
```

生成的 APK 位置：`build/app/outputs/flutter-apk/app-release.apk`

#### 2. 准备上架材料

**必需材料：**

- ✅ 签名的 APK 文件（已完成）
- 📱 应用图标：512x512 像素 PNG 格式，背景不透明
- 📸 应用截图：至少 3 张，建议 5-8 张（竖屏 1080x1920 或横屏 1920x1080）
- 📝 应用详细描述：
  - 应用简介（200 字以内）
  - 功能介绍（500-1000 字）
  - 更新说明
- 📄 隐私政策链接（必需，应用使用了蓝牙和位置权限）
- 🏢 软件著作权或相关资质证明（行业应用推荐）

**应用信息：**

| 项目     | 内容                                   |
| -------- | -------------------------------------- |
| 应用名称 | 昔诺达 BMS 电池管理系统                |
| 应用分类 | 工具 > 系统工具 或 商务办公 > 行业工具 |
| 包名     | com.snt.esbms                            |
| 版本号   | 1.0.0                                  |
| APK 大小 | 约 76 MB                               |

#### 3. 权限说明

应用使用了以下敏感权限，需要在上架时说明用途：

| 权限                 | 用途说明                                                 |
| -------------------- | -------------------------------------------------------- |
| BLUETOOTH_SCAN       | 扫描附近的 BMS 蓝牙设备                                  |
| BLUETOOTH_CONNECT    | 连接并通信 BMS 设备，获取电池数据                        |
| ACCESS_FINE_LOCATION | Android 系统要求：蓝牙扫描需要位置权限（不实际使用位置） |

#### 4. 上架步骤

1. 访问 [腾讯开放平台](https://open.tencent.com/)
2. 注册/登录开发者账号
3. 进入应用宝发布后台
4. 创建新应用
5. 填写应用信息
6. 上传 APK 文件
7. 上传应用图标和截图
8. 填写应用描述和权限说明
9. 提交审核
10. 等待审核结果（通常 3-7 个工作日）

#### 5. 审核注意事项

- ✅ 确保应用功能正常，无崩溃问题
- ✅ 隐私政策必须完整且可访问
- ✅ 敏感权限必须有合理说明
- ✅ 不得包含违规内容
- ✅ 应用截图需真实反映应用功能

### Google Play Store 上架

```bash
# 构建 App Bundle（Google Play 推荐格式）
flutter clean
flutter build appbundle --release
```

生成的 AAB 位置：`build/app/outputs/bundle/release/app-release.aab`

### Apple App Store 上架

```bash
# 构建 iOS 应用
flutter build ipa --release
```

使用 Xcode 或 Transporter 上传到 App Store Connect。

## 项目结构

```
lib/
├── generated/          # 自动生成的文件（国际化等）
├── helper/             # 工具类
│   ├── constant.dart   # 常量定义
│   ├── enum.dart       # 枚举类型
│   ├── routes.dart     # 路由配置
│   └── shared_prefrence_helper.dart  # 本地存储
├── l10n/               # 国际化资源文件 (.arb)
├── model/              # 数据模型
│   ├── bluetooth.dart  # 蓝牙数据模型
│   └── device.dart     # 设备信息模型
├── state/              # Riverpod 状态管理
│   ├── app_state.dart   # 应用全局状态
│   └── bluetooth_state.dart  # 蓝牙状态管理
├── ui/
│   ├── page/           # 页面
│   │   ├── splash/     # 启动页
│   │   ├── home/       # 主页（底部导航容器）
│   │   ├── profile/    # 设备数据显示页
│   │   ├── settings/   # 设置页
│   │   ├── user/       # 用户页
│   │   ├── device/     # 设备相关页面（蓝牙、固件、电芯）
│   │   └── bluetooth/  # 蓝牙扫描连接
│   └── theme/          # 主题配置
└── widgets/            # 可复用组件
```

## 核心功能说明

### 蓝牙数据协议

BMS 设备通过蓝牙发送数据，协议格式：

```
{key: data, value: [{name: xxx, value: 1, multiple: 10, unit: mV}]}
```

**特殊计算：**

1. **电流计算**（两补码）：

   - value < 32768：充电电流（正值）
   - value >= 32768：放电电流 = -(65535 - value) × multiple

2. **温度计算**：
   - 温度(℃) = (value - 2730) / 10 × multiple

实现位置：`lib/state/bluetooth_state.dart`

### 状态管理

项目使用 Riverpod 进行状态管理：

- **app_stateProvider**: 管理底部导航栏索引
- **bleStateProvider**: 管理蓝牙连接状态和实时数据

```dart
// 读取状态
final bleState = ref.watch(bleStateProvider);
final batteryVoltage = bleState.bleModel.bat.finalDisplayValue;

// 更新状态
ref.read(bleStateProvider.notifier).setCharacteristic(characteristic, device);
```

## 常见问题

### 构建失败

**问题：构建时提示签名错误**

```bash
# 确认签名文件存在
ls -l android/app/upload-keystore.jks
cat android/key.properties

# 如果签名文件路径错误，修改 key.properties
```

**问题：依赖冲突**

```bash
# 清理后重新获取依赖
flutter clean
flutter pub get
```

### 蓝牙连接问题

**问题：无法扫描到蓝牙设备**

1. 确认设备蓝牙已开启
2. 检查定位权限是否已授予（Android 必需）
3. 确认 BMS 设备处于可连接状态

**问题：数据解析错误**

检查 `lib/state/bluetooth_state.dart` 中的 `decodeJson` 方法，确认协议格式匹配。

### 权限问题

**问题：运行时提示缺少权限**

在 `android/app/src/main/AndroidManifest.xml` 中已配置所需权限，确保运行时授予权限。

## 版本更新

更新版本号时，修改 `pubspec.yaml`：

```yaml
version: 1.0.1+2 # 格式：版本号+构建号
```

- 版本号：用户可见（如 1.0.1）
- 构建号：内部使用（如 2），每次发布必须递增

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feat/new-feature`)
3. 提交更改 (`git commit -m 'Add: new feature'`)
4. 推送到分支 (`git push origin feat/new-feature`)
5. 创建 Pull Request

## 许可证

[待添加]

## 联系方式

- 组织：Sinota
- 开发者：hang
- 邮箱：[待添加]
