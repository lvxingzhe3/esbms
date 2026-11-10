import 'package:intl/intl.dart';
import 'package:event_bus/event_bus.dart';

// 全局单例
final eventBus = EventBus();

//全局变量
class GlobalData {
  //登陆时间
  static String LoadtIime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  static int DeviceConnectType = 0; //0:蓝牙 1:network
  static String? SN;
  static String? PACK;
  static bool FuseState = false;
  static int cmdAddress = 0x05;
  static String? language;
  static String apiAccessToken = '';
  static String apiRefreshToken = '';
  //设备ID
  static String? currentDeviceId;
  //设备dtuId
  static String? currentDtuId;
  //设备名称
  static String? currentDeviceName;
  static List<String> secretParamList = [
    "battery_calibrated_soc",
    "battery_coulomb_soc",
    "battery_requested_charge_voltage",
    "battery_requested_charge_current",
    "battery_requested_discharge_voltage",
    "battery_requested_discharge_current",
    "input_io_status_hex",
    "output_io_status_hex",
    "temporary_flags",
    "temporary_flags_hex",
    "switch_status_l_hex",
    "alarm_status_hex",
    "protection_status_hex",
    "fault_status_hex",
    "bms_status_hex",
    "cell_balance_status_1_hex",
    "cell_balance_status_2_hex",
    "cell_balance_status_3_hex",
    "cell_balance_status_4_hex",
  ];
}
