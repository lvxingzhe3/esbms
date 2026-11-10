// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `昔诺达 BMS`
  String get title {
    return Intl.message('昔诺达 esBMS', name: 'title', desc: '', args: []);
  }

  /// `电池监控`
  String get batminitor {
    return Intl.message('电池监控', name: 'batminitor', desc: '', args: []);
  }

  /// `设置`
  String get settings {
    return Intl.message('设置', name: 'settings', desc: '', args: []);
  }

  /// `帮助中心`
  String get userPage {
    return Intl.message('帮助中心', name: 'userPage', desc: '', args: []);
  }

  /// `隐私协议`
  String get agreement {
    return Intl.message('隐私协议', name: 'agreement', desc: '', args: []);
  }

  /// `用户登陆`
  String get userload {
    return Intl.message('用户登陆', name: 'userload', desc: '', args: []);
  }

  /// `用户注册`
  String get userregister {
    return Intl.message('用户注册', name: 'userregister', desc: '', args: []);
  }

  /// `离线登陆`
  String get offlineload {
    return Intl.message('离线登陆', name: 'offlineload', desc: '', args: []);
  }

  /// `用户协议`
  String get useragreement {
    return Intl.message('用户协议', name: 'useragreement', desc: '', args: []);
  }

  String get loginUseragreementTip {
    return Intl.message('已阅读并同意',
        name: 'loginUseragreementTip', desc: '', args: []);
  }

  String get selectagreementTip {
    return Intl.message('请勾选同意用户协议及隐私协议',
        name: 'selectagreementTip', desc: '', args: []);
  }

  /// `温馨提示`
  String get agreementTips {
    return Intl.message('温馨提示', name: 'agreementTips', desc: '', args: []);
  }

  /// `欢迎使用“昔诺达BMS电池管理系统”，我们非常重视您的个人信息和隐私保护，在您使用本应用之前，请仔细阅读`
  String get agreementTipsTitle {
    return Intl.message(
      '欢迎使用“昔诺达esBMS电池管理系统”，我们非常重视您的个人信息和隐私保护，在您使用本应用之前，请仔细阅读',
      name: 'agreementTipsTitle',
      desc: '',
      args: [],
    );
  }

  /// `《昔诺达BMS隐私政策》`
  String get agreementCaption {
    return Intl.message(
      '《昔诺达esBMS隐私政策》',
      name: 'agreementCaption',
      desc: '',
      args: [],
    );
  }

  /// `我们将按照您同意的条款使用您的个人信息，以便为您提供服务。`
  String get agreementText {
    return Intl.message(
      '我们将按照您同意的条款使用您的个人信息，设备信息，位置信息，蓝牙信息，以便为您提供服务。',
      name: 'agreementText',
      desc: '',
      args: [],
    );
  }

  /// `如您同意此政策，请点击“同意”并开始我们的产品和服务，我们尽全力保护您的个人信息安全。`
  String get agreementText1 {
    return Intl.message(
      '如您同意此政策，请点击“同意”并开始我们的产品和服务，我们尽全力保护您的个人信息安全。',
      name: 'agreementText1',
      desc: '',
      args: [],
    );
  }

  /// `同意`
  String get agree {
    return Intl.message('同意', name: 'agree', desc: '', args: []);
  }

  /// `不同意`
  String get disagree {
    return Intl.message('不同意', name: 'disagree', desc: '', args: []);
  }

  /// `正常`
  String get normal {
    return Intl.message('正常', name: 'normal', desc: '', args: []);
  }

  /// `异常`
  String get abnormal {
    return Intl.message('异常', name: 'abnormal', desc: '', args: []);
  }

  /// `语言切换`
  String get langSwitch {
    return Intl.message('语言切换', name: 'langSwitch', desc: '', args: []);
  }

  /// `中文`
  String get chinese {
    return Intl.message('中文', name: 'chinese', desc: '', args: []);
  }

  /// `英文`
  String get english {
    return Intl.message('英文', name: 'english', desc: '', args: []);
  }

  /// `确认`
  String get confirm {
    return Intl.message('确认', name: 'confirm', desc: '', args: []);
  }

  /// `取消`
  String get cancel {
    return Intl.message('取消', name: 'cancel', desc: '', args: []);
  }

  String get back {
    return Intl.message('返回', name: 'back', desc: '', args: []);
  }

  /// `暂无异常`
  String get noerror {
    return Intl.message('暂无异常', name: 'noerror', desc: '', args: []);
  }

  /// `容量信息`
  String get capacityinfo {
    return Intl.message('容量信息', name: 'capacityinfo', desc: '', args: []);
  }

  /// `电池组信息`
  String get batpackinfo {
    return Intl.message('电池组信息', name: 'batpackinfo', desc: '', args: []);
  }

  /// `电池信息`
  String get batinfo {
    return Intl.message('电池信息', name: 'batinfo', desc: '', args: []);
  }

  /// `BMS状态信息`
  String get bmsstateinfo {
    return Intl.message('BMS状态', name: 'bmsstateinfo', desc: '', args: []);
  }

  /// `总电压`
  String get totalVol {
    return Intl.message('总电压', name: 'totalVol', desc: '', args: []);
  }

  /// `采集电压`
  String get collectvol {
    return Intl.message('采集电压', name: 'collectvol', desc: '', args: []);
  }

  /// `负载电压`
  String get loadvol {
    return Intl.message('负载电压', name: 'loadvol', desc: '', args: []);
  }

  /// `电流`
  String get cur {
    return Intl.message('电流', name: 'cur', desc: '', args: []);
  }

  /// `功率`
  String get power {
    return Intl.message('功率', name: 'power', desc: '', args: []);
  }

  /// `循环次数`
  String get cycleCount {
    return Intl.message('循环次数', name: 'cycleCount', desc: '', args: []);
  }

  /// `电芯最大值`
  String get cellMaxVal {
    return Intl.message('最大电压', name: 'cellMaxVal', desc: '', args: []);
  }

  /// `电芯最小值`
  String get cellMinVal {
    return Intl.message('最小电压', name: 'cellMinVal', desc: '', args: []);
  }

  /// `压差`
  String get cellVoltdiff {
    return Intl.message('压差', name: 'cellVoltdiff', desc: '', args: []);
  }

  /// `温度最大值`
  String get maxTemp {
    return Intl.message('温度最大值', name: 'maxTemp', desc: '', args: []);
  }

  /// `温度最小值`
  String get minTemp {
    return Intl.message('温度最小值', name: 'minTemp', desc: '', args: []);
  }

  /// `温差`
  String get cellTempdiff {
    return Intl.message('温差', name: 'cellTempdiff', desc: '', args: []);
  }

  /// `充电MOS`
  String get chargeMOS {
    return Intl.message('充电MOS', name: 'chargeMOS', desc: '', args: []);
  }

  /// `放电MOS`
  String get dischargeMOS {
    return Intl.message('放电MOS', name: 'dischargeMOS', desc: '', args: []);
  }

  /// `放电剩余时间`
  String get remainDischargeTime {
    return Intl.message(
      '放电剩余',
      name: 'remainDischargeTime',
      desc: '',
      args: [],
    );
  }

  /// `充电剩余时间`
  String get remainchargeTime {
    return Intl.message(
      '充电剩余',
      name: 'remainchargeTime',
      desc: '',
      args: [],
    );
  }

  /// `电池总容量`
  String get totalBattery {
    return Intl.message('总容量', name: 'totalBattery', desc: '', args: []);
  }

  /// `电池剩余容量`
  String get remainBattery {
    return Intl.message('剩余容量', name: 'remainBattery', desc: '', args: []);
  }

  /// `电池类型`
  String get batteryType {
    return Intl.message('电池类型', name: 'batteryType', desc: '', args: []);
  }

  /// `保护信息`
  String get protectionInfo {
    return Intl.message('保护信息', name: 'protectionInfo', desc: '', args: []);
  }

  /// `告警信息`
  String get alarmInfo {
    return Intl.message('告警信息', name: 'alarmInfo', desc: '', args: []);
  }

  /// `告警状态`
  String get alarmState {
    return Intl.message('告警状态', name: 'alarmState', desc: '', args: []);
  }

  String get noalarm {
    return Intl.message('暂无告警', name: 'noalarm', desc: '', args: []);
  }

  /// `当前ota版本已是最新，无需升级`
  String get otaNoUpdateNeeded {
    return Intl.message(
      '当前ota版本已是最新，无需升级',
      name: 'otaNoUpdateNeeded',
      desc: '',
      args: [],
    );
  }

  /// `升级过程中请勿离开此页面或者关闭App`
  String get otaUpdateTips {
    return Intl.message(
      '升级过程中请勿离开此页面或者关闭App',
      name: 'otaUpdateTips',
      desc: '',
      args: [],
    );
  }

  /// `当前进度`
  String get progress {
    return Intl.message('当前进度', name: 'progress', desc: '', args: []);
  }

  /// `OTA升级`
  String get otaUpgrade {
    return Intl.message('OTA升级', name: 'otaUpgrade', desc: '', args: []);
  }

  /// `OTA升级完成`
  String get otaDone {
    return Intl.message('OTA升级完成', name: 'otaDone', desc: '', args: []);
  }

  /// `升级成功`
  String get otaDoneTips {
    return Intl.message('升级成功', name: 'otaDoneTips', desc: '', args: []);
  }

  /// `OTA升级中`
  String get otaUpgrading {
    return Intl.message('OTA升级中', name: 'otaUpgrading', desc: '', args: []);
  }

  /// `升级中，请稍后`
  String get otaUpgradingTips {
    return Intl.message(
      '升级中，请稍后',
      name: 'otaUpgradingTips',
      desc: '',
      args: [],
    );
  }

  /// `设置`
  String get settingPage {
    return Intl.message('设置', name: 'settingPage', desc: '', args: []);
  }

  /// `软件信息`
  String get sofewareInfo {
    return Intl.message('软件信息', name: 'sofewareInfo', desc: '', args: []);
  }

  /// `App版本`
  String get appVersion {
    return Intl.message('App版本', name: 'appVersion', desc: '', args: []);
  }

  /// `软件版本`
  String get sofewareVersion {
    return Intl.message('软件版本', name: 'sofewareVersion', desc: '', args: []);
  }

  /// `硬件版本`
  String get hardwareVersion {
    return Intl.message('硬件版本', name: 'hardwareVersion', desc: '', args: []);
  }

  /// `设备列表`
  String get deviceList {
    return Intl.message('设备列表', name: 'deviceList', desc: '', args: []);
  }

  /// `添加设备`
  String get adddevice {
    return Intl.message('添加设备', name: 'adddevice', desc: '', args: []);
  }

  String get adddevicesuccess {
    return Intl.message('添加设备成功', name: 'adddevicesuccess', desc: '', args: []);
  }

  /// `设备信息`
  String get deviceinfo {
    return Intl.message('设备信息', name: 'deviceinfo', desc: '', args: []);
  }

  String get deviceinittip {
    return Intl.message('初次连接，请等待一分钟设备完成初始化',
        name: 'deviceinittip', desc: '', args: []);
  }

  String get deviceoffline {
    return Intl.message('设备离线', name: 'deviceoffline', desc: '', args: []);
  }

  /// `公司`
  String get company {
    return Intl.message('公司', name: 'company', desc: '', args: []);
  }

  String get scanqrcode {
    return Intl.message('扫描二维码', name: 'scanqrcode', desc: '', args: []);
  }

  /// `修改蓝牙名称`
  String get editbloothname {
    return Intl.message('修改蓝牙名称', name: 'editbloothname', desc: '', args: []);
  }

  /// `新名称`
  String get newname {
    return Intl.message('新名称', name: 'newname', desc: '', args: []);
  }

  /// `设备位置`
  String get deviceLocation {
    return Intl.message('设备位置', name: 'deviceLocation', desc: '', args: []);
  }

  /// `设备地图`
  String get deviceMap {
    return Intl.message('设备地图', name: 'deviceMap', desc: '', args: []);
  }

  /// `当前位置`
  String get currentLocation {
    return Intl.message('当前位置', name: 'currentLocation', desc: '', args: []);
  }

  /// `经度`
  String get longitude {
    return Intl.message('经度', name: 'longitude', desc: '', args: []);
  }

  /// `纬度`
  String get latitude {
    return Intl.message('纬度', name: 'latitude', desc: '', args: []);
  }

  /// `设备名称`
  String get deviceName {
    return Intl.message('设备名称', name: 'deviceName', desc: '', args: []);
  }

  /// `请先连接设备`
  String get deviceTips {
    return Intl.message('请先连接设备', name: 'deviceTips', desc: '', args: []);
  }

  /// `升级`
  String get upgrade {
    return Intl.message('升级', name: 'upgrade', desc: '', args: []);
  }

  /// `未连接`
  String get noConnected {
    return Intl.message('未连接', name: 'noConnected', desc: '', args: []);
  }

  /// `导入OTA文件`
  String get importOtaFile {
    return Intl.message('导入OTA文件', name: 'importOtaFile', desc: '', args: []);
  }

  /// `选择`
  String get select {
    return Intl.message('选择', name: 'select', desc: '', args: []);
  }

  /// `OTA手动升级`
  String get otaManulUpgrade {
    return Intl.message('OTA手动升级', name: 'otaManulUpgrade', desc: '', args: []);
  }

  /// `文件名`
  String get fileName {
    return Intl.message('文件名', name: 'fileName', desc: '', args: []);
  }

  /// `电芯信息`
  String get batteryCellInfo {
    return Intl.message('电芯信息', name: 'batteryCellInfo', desc: '', args: []);
  }

  /// `连接`
  String get connect {
    return Intl.message('连接', name: 'connect', desc: '', args: []);
  }

  /// `断开`
  String get disconnect {
    return Intl.message('断开', name: 'disconnect', desc: '', args: []);
  }

  /// `次`
  String get times {
    return Intl.message('次', name: 'times', desc: '', args: []);
  }

  /// `运行时间`
  String get runtime {
    return Intl.message('运行时间', name: 'runtime', desc: '', args: []);
  }

  ///GPS登陆
  String get gpslogin {
    return Intl.message('GPS登陆', name: 'gpslogin', desc: '', args: []);
  }

  ///登陆
  String get login {
    return Intl.message('登陆', name: 'login', desc: '', args: []);
  }

  ///登出
  String get logout {
    return Intl.message('登出', name: 'logout', desc: '', args: []);
  }

  ///账号
  String get account {
    return Intl.message('账号', name: 'account', desc: '', args: []);
  }

  ///手机号
  String get phonenum {
    return Intl.message('手机号', name: 'phonenum', desc: '', args: []);
  }

  ///密码
  String get password {
    return Intl.message('密码', name: 'password', desc: '', args: []);
  }

  ///确认密码
  String get confirmpassword {
    return Intl.message('确认密码', name: 'confirmpassword', desc: '', args: []);
  }

  String get passworddif {
    return Intl.message('两次输入的密码不一致', name: 'passworddif', desc: '', args: []);
  }

  ///验证码
  String get vercode {
    return Intl.message('验证码', name: 'vercode', desc: '', args: []);
  }

  ///获取验证码
  String get getvercode {
    return Intl.message('获取验证码', name: 'getvercode', desc: '', args: []);
  }

  String get sentvercode {
    return Intl.message('验证码发送成功，请注意查收',
        name: 'sentvercode', desc: '', args: []);
  }

  ///请输入账号
  String get inputaccount {
    return Intl.message('请输入账号', name: 'inputaccount', desc: '', args: []);
  }

  ///请输入密码
  String get inputpassword {
    return Intl.message('请输入密码', name: 'inputpassword', desc: '', args: []);
  }

  String get inputphonecode {
    return Intl.message('请输入手机号和验证码',
        name: 'inputphonecode', desc: '', args: []);
  }

  String get phonenumwrong {
    return Intl.message('请输入正确的手机号', name: 'phonenumwrong', desc: '', args: []);
  }

  String get registersuccess {
    return Intl.message('注册成功，请登录',
        name: 'registersuccess', desc: '', args: []);
  }

  String get registerfail {
    return Intl.message('注册失败', name: 'registerfail', desc: '', args: []);
  }

  ///登陆提示
  String get logintip {
    return Intl.message('已有账号？去登陆', name: 'logintip', desc: '', args: []);
  }

  ///注册提示
  String get registertip {
    return Intl.message('没有账号？去注册', name: 'registertip', desc: '', args: []);
  }

  ///当前用户
  String get currentuser {
    return Intl.message('当前用户', name: 'currentuser', desc: '', args: []);
  }

  ///账号或密码错误
  String get userinfowrong {
    return Intl.message('账号或密码错误', name: 'userinfowrong', desc: '', args: []);
  }

  String get accounttip {
    return Intl.message('账号长度必须在6-30个字符之间',
        name: 'accounttip', desc: '', args: []);
  }

  String get passwordtip {
    return Intl.message('密码长度必须在6-20个字符之间',
        name: 'passwordtip', desc: '', args: []);
  }

  String get accountsecurity {
    return Intl.message('账号安全', name: 'accountsecurity', desc: '', args: []);
  }

  ///已登陆
  String get loggedIn {
    return Intl.message('登陆成功', name: 'loggedIn', desc: '', args: []);
  }

  static String get loginfail {
    return Intl.message('登陆失败', name: 'loginfail', desc: '', args: []);
  }

  ///已登出
  String get loggedOut {
    return Intl.message('已登出', name: 'loggedOut', desc: '', args: []);
  }

  ///注销账号
  String get deleteAccount {
    return Intl.message('注销账号', name: 'deleteAccount', desc: '', args: []);
  }

  String get deleteuserTip {
    return Intl.message('该用户下的绑定设备将解除绑定，资料将无法找回，请谨慎操作',
        name: 'deleteuserTip', desc: '', args: []);
  }

  ///常见问题
  String get question {
    return Intl.message('常见问题', name: 'question', desc: '', args: []);
  }

  ///蓝牙名称
  String get bloothname {
    return Intl.message('蓝牙名称', name: 'bloothname', desc: '', args: []);
  }

  String get bloothconntedfail {
    return Intl.message('蓝牙连接失败',
        name: 'bloothconntedfail', desc: '', args: []);
  }

  String get read {
    return Intl.message('读取', name: 'read', desc: '', args: []);
  }

  String get write {
    return Intl.message('写入', name: 'write', desc: '', args: []);
  }

  String get modify {
    return Intl.message('修改', name: 'modify', desc: '', args: []);
  }

  String get set {
    return Intl.message('设置', name: 'set', desc: '', args: []);
  }

  String get moreset {
    return Intl.message('更多设置', name: 'moreset', desc: '', args: []);
  }

  /// 保险丝
  String get fuse {
    return Intl.message('三端保险丝', name: 'fuse', desc: '', args: []);
  }

  /// 参数设置
  String get paramsettings {
    return Intl.message('参数设置', name: 'paramsettings', desc: '', args: []);
  }

  /// 保护参数
  String get protectparam {
    return Intl.message('保护参数', name: 'protectparam', desc: '', args: []);
  }

  /// 警告保护参数
  String get warnparam {
    return Intl.message('警告保护参数', name: 'warnparam', desc: '', args: []);
  }

  /// 功能参数
  String get funcparam {
    return Intl.message('功能参数', name: 'funcparam', desc: '', args: []);
  }

  /// 系统参数
  String get systemparam {
    return Intl.message('系统参数', name: 'systemparam', desc: '', args: []);
  }

  /// 基础参数
  String get basicsettings {
    return Intl.message('基础设置', name: 'basicsettings', desc: '', args: []);
  }

  /// SOC参数
  String get socparam {
    return Intl.message('SOC参数', name: 'socparam', desc: '', args: []);
  }

  /// 参数名
  String get paramname {
    return Intl.message('参数名', name: 'paramname', desc: '', args: []);
  }

  /// 参数值
  String get paramvalue {
    return Intl.message('参数值', name: 'paramvalue', desc: '', args: []);
  }

  /// 单位
  String get unit {
    return Intl.message('单位', name: 'unit', desc: '', args: []);
  }

  /// 操作
  String get operation {
    return Intl.message('操作', name: 'operation', desc: '', args: []);
  }

  /// `运行状态`
  String get runstate {
    return Intl.message('运行状态', name: 'runstate', desc: '', args: []);
  }

  /// `蓝牙配网`
  String get bluewifi {
    return Intl.message('蓝牙配网', name: 'bluewifi', desc: '', args: []);
  }

  /// `选择wifi名称`
  String get selectwifi {
    return Intl.message('选择wifi名称', name: 'selectwifi', desc: '', args: []);
  }

  String get wificonfigdhcptip {
    return Intl.message('"如果确定路由器已关闭DHCP功能，请手动设置IP地址等网络参数，否则保持DHCP使能不变。',
        name: 'wificonfigdhcptip', desc: '', args: []);
  }

  String get wificonfigtip1 {
    return Intl.message('1. 请确保你的Wi-Fi路由器是打开的，若连接失败，可检查路由器是否对联网设备数量有限制',
        name: 'wificonfigtip1', desc: '', args: []);
  }

  String get wificonfigtip2 {
    return Intl.message('2. DTU仅适用2.4G频段的Wi-Fi"',
        name: 'wificonfigtip2', desc: '', args: []);
  }

  String get wificonfigprocessing {
    return Intl.message('正在Wifi配网，请稍等...',
        name: 'wificonfigprocessing', desc: '', args: []);
  }

  String get wificonfigscucess {
    return Intl.message('配网成功', name: 'wificonfigscucess', desc: '', args: []);
  }

  String get wificonfigfail {
    return Intl.message('配网失败', name: 'wificonfigfail', desc: '', args: []);
  }

  String get wificonfigcancel {
    return Intl.message('配网取消', name: 'wificonfigcancel', desc: '', args: []);
  }

  /// 单体过充
  String get overcharge {
    return Intl.message('单体过充', name: 'overcharge', desc: '', args: []);
  }

  /// 单体过充延时
  String get overchargedelay {
    return Intl.message('单体过充延时', name: 'overchargedelay', desc: '', args: []);
  }

  /// 单体过充解除
  String get overchargelift {
    return Intl.message('单体过充解除', name: 'overchargelift', desc: '', args: []);
  }

  /// 单体过充解除延时
  String get overchargeliftdelay {
    return Intl.message('单体过充解除延时',
        name: 'overchargeliftdelay', desc: '', args: []);
  }

  /// 单体过放
  String get overdischarge {
    return Intl.message('单体过放', name: 'overdischarge', desc: '', args: []);
  }

  /// 单体过放延时
  String get overdischargedelay {
    return Intl.message('单体过放延时',
        name: 'overdischargedelay', desc: '', args: []);
  }

  /// 单体过放解除
  String get overdischargelift {
    return Intl.message('单体过放解除',
        name: 'overdischargelift', desc: '', args: []);
  }

  /// 单体过放解除延时
  String get overdischargeliftdelay {
    return Intl.message('单体过放解除延时',
        name: 'overdischargeliftdelay', desc: '', args: []);
  }

  /// 总体过充
  String get allovercharge {
    return Intl.message('总体过充', name: 'allovercharge', desc: '', args: []);
  }

  /// 总体过充延时
  String get alloverchargedelay {
    return Intl.message('总体过充延时',
        name: 'alloverchargedelay', desc: '', args: []);
  }

  /// 总体过充解除
  String get alloverchargelift {
    return Intl.message('总体过充解除',
        name: 'alloverchargelift', desc: '', args: []);
  }

  /// 总体过充解除延时
  String get alloverchargeliftdelay {
    return Intl.message('总体过充解除延时',
        name: 'alloverchargeliftdelay', desc: '', args: []);
  }

  /// 总体过放
  String get alloverdischarge {
    return Intl.message('总体过放', name: 'alloverdischarge', desc: '', args: []);
  }

  /// 总体过放延时
  String get alloverdischargedelay {
    return Intl.message('总体过放延时',
        name: 'alloverdischargedelay', desc: '', args: []);
  }

  /// 总体过放解除
  String get alloverdischargelift {
    return Intl.message('总体过放解除',
        name: 'alloverdischargelift', desc: '', args: []);
  }

  /// 总体过放解除延时
  String get alloverdischargeliftdelay {
    return Intl.message('总体过放解除延时',
        name: 'alloverdischargeliftdelay', desc: '', args: []);
  }

  /// 充电过流
  String get overchargecur {
    return Intl.message('充电过流', name: 'overchargecur', desc: '', args: []);
  }

  /// 充电过流延时
  String get overchargecurdelay {
    return Intl.message('充电过流延时',
        name: 'overchargecurdelay', desc: '', args: []);
  }

  /// 充电过流解除
  String get overchargecurlift {
    return Intl.message('充电过流解除',
        name: 'overchargecurlift', desc: '', args: []);
  }

  /// 充电过流解除延时
  String get overchargecurliftdelay {
    return Intl.message('充电过流解除延时',
        name: 'overchargecurliftdelay', desc: '', args: []);
  }

  /// 二级充电过流
  String get overchargecur2 {
    return Intl.message('二级充电过流', name: 'overchargecur2', desc: '', args: []);
  }

  /// 二级充电过流延时
  String get overchargecur2delay {
    return Intl.message('二级充电过流延时',
        name: 'overchargecur2delay', desc: '', args: []);
  }

  /// 放电过流
  String get overdischargecur {
    return Intl.message('放电过流', name: 'overdischargecur', desc: '', args: []);
  }

  /// 放电过流延时
  String get overdischargecurdelay {
    return Intl.message('放电过流延时',
        name: 'overdischargecurdelay', desc: '', args: []);
  }

  /// 放电过流解除
  String get overdischargecurlift {
    return Intl.message('放电过流解除',
        name: 'overdischargecurlift', desc: '', args: []);
  }

  /// 放电过流解除延时
  String get overdischargecurliftdelay {
    return Intl.message('放电过流解除延时',
        name: 'overdischargecurliftdelay', desc: '', args: []);
  }

  /// 二级放电过流
  String get overdischargecur2 {
    return Intl.message('二级放电过流',
        name: 'overdischargecur2', desc: '', args: []);
  }

  /// 二级放电过流延时
  String get overdischargecur2delay {
    return Intl.message('二级放电过流延时',
        name: 'overdischargecur2delay', desc: '', args: []);
  }

  /// 放电高温
  String get dischargehightemp {
    return Intl.message('放电高温', name: 'dischargehightemp', desc: '', args: []);
  }

  /// 放电高温延时
  String get dischargehightempdelay {
    return Intl.message('放电高温延时',
        name: 'dischargehightempdelay', desc: '', args: []);
  }

  /// 放电高温解除
  String get dischargehightemplift {
    return Intl.message('放电高温解除',
        name: 'dischargehightemplift', desc: '', args: []);
  }

  /// 放电高温解除延时
  String get dischargehightempliftdelay {
    return Intl.message('放电高温解除延时',
        name: 'dischargehightempliftdelay', desc: '', args: []);
  }

  /// 放电低温
  String get dischargelowtemp {
    return Intl.message('放电低温', name: 'dischargelowtemp', desc: '', args: []);
  }

  /// 放电低温解除
  String get dischargelowtemplift {
    return Intl.message('放电低温解除',
        name: 'dischargelowtemplift', desc: '', args: []);
  }

  /// 放电低温延时
  String get dischargelowtempdelay {
    return Intl.message('放电低温延时',
        name: 'dischargelowtempdelay', desc: '', args: []);
  }

  /// 放电低温解除延时
  String get dischargelowtempliftdelay {
    return Intl.message('放电低温解除延时',
        name: 'dischargelowtempliftdelay', desc: '', args: []);
  }

  /// 充电高温
  String get chargehightemp {
    return Intl.message('充电高温', name: 'chargehightemp', desc: '', args: []);
  }

  /// 充电高温解除
  String get chargehightemplift {
    return Intl.message('充电高温解除',
        name: 'chargehightemplift', desc: '', args: []);
  }

  /// 充电高温延时
  String get chargehightempdelay {
    return Intl.message('充电高温延时',
        name: 'chargehightempdelay', desc: '', args: []);
  }

  /// 充电高温解除延时
  String get chargehightempliftdelay {
    return Intl.message('充电高温解除延时',
        name: 'chargehightempliftdelay', desc: '', args: []);
  }

  /// 充电低温
  String get chargelowtemp {
    return Intl.message('充电低温', name: 'chargelowtemp', desc: '', args: []);
  }

  /// 充电低温解除
  String get chargelowtemplift {
    return Intl.message('充电低温解除',
        name: 'chargelowtemplift', desc: '', args: []);
  }

  /// 充电低温延时
  String get chargelowtempdelay {
    return Intl.message('充电低温延时',
        name: 'chargelowtempdelay', desc: '', args: []);
  }

  /// 充电低温解除延时
  String get chargelowtempliftdelay {
    return Intl.message('充电低温解除延时',
        name: 'chargelowtempliftdelay', desc: '', args: []);
  }

  /// MOS高温
  String get moshightemp {
    return Intl.message('MOS高温', name: 'moshightemp', desc: '', args: []);
  }

  /// MOS高温延时
  String get moshightempdelay {
    return Intl.message('MOS高温延时',
        name: 'moshightempdelay', desc: '', args: []);
  }

  /// MOS高温解除
  String get moshightemplift {
    return Intl.message('MOS高温解除', name: 'moshightemplift', desc: '', args: []);
  }

  /// MOS高温解除延时
  String get moshightempliftdelay {
    return Intl.message('MOS高温解除延时',
        name: 'moshightempliftdelay', desc: '', args: []);
  }

  /// 环境高温
  String get evnhightemp {
    return Intl.message('环境高温', name: 'evnhightemp', desc: '', args: []);
  }

  /// 环境高温延时
  String get evnhightempdelay {
    return Intl.message('环境高温延时', name: 'evnhightempdelay', desc: '', args: []);
  }

  /// 环境高温解除
  String get evnhightemplift {
    return Intl.message('环境高温解除', name: 'evnhightemplift', desc: '', args: []);
  }

  /// 环境高温解除延时
  String get evnhightempliftdelay {
    return Intl.message('环境高温解除延时',
        name: 'evnhightempliftdelay', desc: '', args: []);
  }

  /// 环境低温
  String get evnlowtemp {
    return Intl.message('环境低温', name: 'evnlowtemp', desc: '', args: []);
  }

  /// soc低
  String get soclow {
    return Intl.message('soc低', name: 'soclow', desc: '', args: []);
  }

  /// soc低延时
  String get soclowdelay {
    return Intl.message('soc低延时', name: 'soclowdelay', desc: '', args: []);
  }

  /// soc低解除
  String get soclowlift {
    return Intl.message('soc低解除', name: 'soclowlift', desc: '', args: []);
  }

  /// soc低解除延时
  String get soclowliftdelay {
    return Intl.message('soc低解除延时',
        name: 'soclowliftdelay', desc: '', args: []);
  }

  /// soc高
  String get sochigh {
    return Intl.message('soc高', name: 'sochigh', desc: '', args: []);
  }

  /// soc高延时
  String get sochighdelay {
    return Intl.message('soc高延时', name: 'sochighdelay', desc: '', args: []);
  }

  /// soc高解除
  String get sochighlift {
    return Intl.message('soc高解除', name: 'sochighlift', desc: '', args: []);
  }

  /// soc高解除延时
  String get sochighliftdelay {
    return Intl.message('soc高解除延时',
        name: 'sochighliftdelay', desc: '', args: []);
  }

  /// soh低
  String get sohlow {
    return Intl.message('soh低', name: 'sohlow', desc: '', args: []);
  }

  /// soh低延时
  String get sohlowdelay {
    return Intl.message('soh低延时', name: 'sohlowdelay', desc: '', args: []);
  }

  /// soh低解除
  String get sohlowlift {
    return Intl.message('soh低解除', name: 'sohlowlift', desc: '', args: []);
  }

  /// soh低解除延时
  String get sohlowliftdelay {
    return Intl.message('soh低解除延时',
        name: 'sohlowliftdelay', desc: '', args: []);
  }

  /// soh高
  String get sohhigh {
    return Intl.message('soh高', name: 'sohhigh', desc: '', args: []);
  }

  /// soh高延时
  String get sohhighdelay {
    return Intl.message('soh高延时', name: 'sohhighdelay', desc: '', args: []);
  }

  /// soh高解除
  String get sohhighlift {
    return Intl.message('soh高解除', name: 'sohhighlift', desc: '', args: []);
  }

  /// soh高解除延时
  String get sohhighliftdelay {
    return Intl.message('soh高解除延时',
        name: 'sohhighliftdelay', desc: '', args: []);
  }

  /// 充电压差
  String get chargevoldif {
    return Intl.message('充电压差', name: 'chargevoldif', desc: '', args: []);
  }

  /// 充电压差延时
  String get chargevoldifdelay {
    return Intl.message('充电压差延时',
        name: 'chargevoldifdelay', desc: '', args: []);
  }

  /// 充电压差解除
  String get chargevoldiflift {
    return Intl.message('充电压差解除', name: 'chargevoldiflift', desc: '', args: []);
  }

  /// 充电压差解除延时
  String get chargevoldifliftdelay {
    return Intl.message('充电压差解除延时',
        name: 'chargevoldifliftdelay', desc: '', args: []);
  }

  /// 放电压差
  String get dischargevoldif {
    return Intl.message('放电压差', name: 'dischargevoldif', desc: '', args: []);
  }

  /// 放电压差延时
  String get dischargevoldifdelay {
    return Intl.message('放电压差延时',
        name: 'dischargevoldifdelay', desc: '', args: []);
  }

  /// 放电压差解除
  String get dischargevoldiflift {
    return Intl.message('放电压差解除',
        name: 'dischargevoldiflift', desc: '', args: []);
  }

  /// 放电压差解除延时
  String get dischargevoldifliftdelay {
    return Intl.message('放电压差解除延时',
        name: 'dischargevoldifliftdelay', desc: '', args: []);
  }

  /// 充电温差
  String get chargetempdif {
    return Intl.message('充电温差', name: 'chargetempdif', desc: '', args: []);
  }

  /// 充电温差延时
  String get chargetempdifdelay {
    return Intl.message('充电温差延时',
        name: 'chargetempdifdelay', desc: '', args: []);
  }

  /// 充电温差解除
  String get chargetempdiflift {
    return Intl.message('充电温差解除',
        name: 'chargetempdiflift', desc: '', args: []);
  }

  /// 充电温差解除延时
  String get chargetempdifliftdelay {
    return Intl.message('充电温差解除延时',
        name: 'chargetempdifliftdelay', desc: '', args: []);
  }

  /// 放电温差
  String get dischargetempdif {
    return Intl.message('放电温差', name: 'dischargetempdif', desc: '', args: []);
  }

  /// 放电温差延时
  String get dischargetempdifdelay {
    return Intl.message('放电温差延时',
        name: 'dischargetempdifdelay', desc: '', args: []);
  }

  /// 放电温差解除
  String get dischargetempdiflift {
    return Intl.message('放电温差解除',
        name: 'dischargetempdiflift', desc: '', args: []);
  }

  /// 放电温差解除延时
  String get dischargetempdifliftdelay {
    return Intl.message('放电温差解除延时',
        name: 'dischargetempdifliftdelay', desc: '', args: []);
  }

  /// 温升
  String get temprise {
    return Intl.message('温升', name: 'temprise', desc: '', args: []);
  }

  /// 休眠电压
  String get sleepvoltage {
    return Intl.message('休眠电压', name: 'sleepvoltage', desc: '', args: []);
  }

  /// 进入休眠电压时间
  String get sleepvoltagedelay {
    return Intl.message('进入休眠电压时间',
        name: 'sleepvoltagedelay', desc: '', args: []);
  }

  ///短路
  String get bordshort {
    return Intl.message('短路', name: 'bordshort', desc: '', args: []);
  }

  ///反接
  String get reverse {
    return Intl.message('反接', name: 'reverse', desc: '', args: []);
  }

  ///电芯异常
  String get batabnormal {
    return Intl.message('电芯异常', name: 'batabnormal', desc: '', args: []);
  }

  ///电流异常
  String get currentabnormal {
    return Intl.message('电流异常', name: 'currentabnormal', desc: '', args: []);
  }

  ///NTC异常
  String get ntcabnormal {
    return Intl.message('NTC异常', name: 'ntcabnormal', desc: '', args: []);
  }

  ///AFE通信异常
  String get afeabnormal {
    return Intl.message('AFE通信异常', name: 'afeabnormal', desc: '', args: []);
  }

  ///充电MOS异常
  String get chargemosabnormal {
    return Intl.message('充电MOS异常',
        name: 'chargemosabnormal', desc: '', args: []);
  }

  ///放电MOS异常
  String get dischargemosabnormal {
    return Intl.message('放电MOS异常',
        name: 'dischargemosabnormal', desc: '', args: []);
  }

  ///充电限流异常
  String get chargelimitcurabnormal {
    return Intl.message('充电限流异常',
        name: 'chargelimitcurabnormal', desc: '', args: []);
  }

  ///预放异常
  String get predischargeabnormal {
    return Intl.message('预放异常',
        name: 'predischargeabnormal', desc: '', args: []);
  }

  ///风扇异常
  String get fanabnormal {
    return Intl.message('风扇异常', name: 'fanabnormal', desc: '', args: []);
  }

  ///加热异常
  String get riseabnormal {
    return Intl.message('加热异常', name: 'riseabnormal', desc: '', args: []);
  }

  ///系统异常
  String get systemabnormal {
    return Intl.message('系统异常', name: 'systemabnormal', desc: '', args: []);
  }

  ///硬件异常
  String get hardwareabnormal {
    return Intl.message('硬件异常', name: 'hardwareabnormal', desc: '', args: []);
  }

  String get invertercom {
    return Intl.message('逆变器通信', name: 'invertercom', desc: '', args: []);
  }

  String get hostcom {
    return Intl.message('上位机通信', name: 'hostcom', desc: '', args: []);
  }

  String get mergecom {
    return Intl.message('并机通信', name: 'mergecom', desc: '', args: []);
  }

  String get forbidcharge {
    return Intl.message('禁充标志', name: 'forbidcharge', desc: '', args: []);
  }

  String get forbiddischarge {
    return Intl.message('禁放标志', name: 'forbiddischarge', desc: '', args: []);
  }

  String get forcechargeenable {
    return Intl.message('强充使能', name: 'forcechargeenable', desc: '', args: []);
  }

  String get fullcharge {
    return Intl.message('满充标志', name: 'fullcharge', desc: '', args: []);
  }

  String get predischarge {
    return Intl.message('预放完成', name: 'predischarge', desc: '', args: []);
  }

  String get chargeraccess {
    return Intl.message('充电器接入', name: 'chargeraccess', desc: '', args: []);
  }

  String get loadaccess {
    return Intl.message('负载接入', name: 'loadaccess', desc: '', args: []);
  }

  String get raiseflag {
    return Intl.message('加热', name: 'raiseflag', desc: '', args: []);
  }

  String get release {
    return Intl.message('脱扣器', name: 'release', desc: '', args: []);
  }

  String get uploadflag {
    return Intl.message('升级', name: 'uploadflag', desc: '', args: []);
  }

  /// `wifi connecting`
  String get wifi_connecting {
    return Intl.message(
      'wifi connecting',
      name: 'wifi_connecting',
      desc: '',
      args: [],
    );
  }

  /// `Router not exist`
  String get router_not_exist {
    return Intl.message(
      'Router not exist',
      name: 'router_not_exist',
      desc: '',
      args: [],
    );
  }

  /// `Error router key`
  String get error_router_key {
    return Intl.message(
      'Error router key',
      name: 'error_router_key',
      desc: '',
      args: [],
    );
  }

  /// `Error router connect`
  String get error_router_connect {
    return Intl.message(
      'Error router connect',
      name: 'error_router_connect',
      desc: '',
      args: [],
    );
  }

  /// `Router connecting`
  String get ongoing_router_connect {
    return Intl.message(
      'Router connecting',
      name: 'ongoing_router_connect',
      desc: '',
      args: [],
    );
  }

  /// `success`
  String get config_success {
    return Intl.message(
      'success',
      name: 'config_success',
      desc: '',
      args: [],
    );
  }

  /// `timeout`
  String get config_timeout {
    return Intl.message(
      'timeout',
      name: 'config_timeout',
      desc: '',
      args: [],
    );
  }

  /// `Error send cmd`
  String get error_send_cmd {
    return Intl.message(
      'Error send cmd',
      name: 'error_send_cmd',
      desc: '',
      args: [],
    );
  }

  /// `No Location Permission!`
  String get no_location_permission {
    return Intl.message(
      'No Location Permission!',
      name: 'no_location_permission',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get not_yet {
    return Intl.message(
      'No',
      name: 'not_yet',
      desc: '',
      args: [],
    );
  }

  /// `Go Open`
  String get go_open {
    return Intl.message(
      'Go Open',
      name: 'go_open',
      desc: '',
      args: [],
    );
  }

  /// `Need location services`
  String get need_location_services {
    return Intl.message(
      'Need location services',
      name: 'need_location_services',
      desc: '',
      args: [],
    );
  }

  /// `Find nearby devices`
  String get find_nearby_devices {
    return Intl.message(
      'Find nearby devices',
      name: 'find_nearby_devices',
      desc: '',
      args: [],
    );
  }

  String get faq_q1 {
    return Intl.message('蓝牙搜不到设备怎么办？', name: 'faq_q1', desc: '', args: []);
  }

  String get faq_a1 {
    return Intl.message('1.确认设备已上电；2.手机蓝牙、定位权限已打开；3.靠近设备重试；4.关闭APP重新进入。',
        name: 'faq_a1', desc: '', args: []);
  }

  String get faq_q2 {
    return Intl.message('设备离线不刷新数据？', name: 'faq_q2', desc: '', args: []);
  }

  String get faq_a2 {
    return Intl.message('检查WiFi网络是否正常，重启BMS设备，确认DTU联网指示灯常亮。',
        name: 'faq_a2', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
