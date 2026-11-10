import 'package:bms_app/model/paramitem.dart';

class Batpackinfo {
  String devname = "";
  //连接状态
  bool isConnected = false;
  //运行状态
  String workstate = "";
  //累加电压
  double voltage = 0;
  //采集电压
  double collectvol = 0;
  //负载电压
  double loadvol = 0;
  //电流
  double current = 0;
  //电流
  double power = 0;
  //soc
  double soc = 0;
  //soh
  double soh = 0;
  //总容量
  double totalcapaciry = 0;
  //剩余容量
  double remaincap = 0;
  //电池类型
  String bat_type = "";
  //电池串数
  int cells = 0;
  //电池温度
  int temps = 0;
  //循环次数
  int cycle = 0;
  //电芯最高电压
  double max_voltage = 0;
  //电芯最低电压
  double min_voltage = 0;
  //电芯最高温度
  double max_temperature = 0;
  //电芯最低温度
  double min_temperature = 0;
  //电芯最高电压序号
  int max_volindex = 0;
  //电芯最低电压序号
  int min_volindex = 0;
  //电芯最高温度序号
  int max_tempindex = 0;
  //电芯最低温度序号
  int min_tempeindex = 0;
  //电芯数量
  int cellnum = 0;
  //电芯温度数量
  int celltempnum = 0;
  //剩余放电时间
  int dchg_timeuse = 0;
  //剩余充电时间
  int chg_timeuse = 0;
  //保护信息
  int bms_protect = 0;
  //保护信息L
  int bms_protectL = 0;
  //保护信息H
  int bms_protectH = 0;
  //告警信息
  int bms_alarm = 0;
  //告警信息L
  int bms_alarmL = 0;
  //告警信息H
  int bms_alarmH = 0;
  //告警信息
  int bms_abnormal = 0;
  //bms状态
  int bms_state = 0;
  //电芯电压
  List<Batinfo> cellvols = [];
  //电芯温度
  List<Batinfo> celltemps = [];
  //软件版本
  String softversion = "";
  //硬件版本
  String hardversion = "";
  //基础信息
  List<ParamItem> basicParams = [];
  //状态信息
  List<ParamItem> bmsstateParams = [];
  //充电mos
  bool chargeMOS = false;
  //放电mos
  bool dischargeMOS = false;
  //均衡状态1
  int bms_balance1 = 0;
}

class Batinfo {
  int index = 0;
  String label = "";
  dynamic value;
  bool max = false;
  bool min = false;

  Batinfo(this.label, this.value);
}

class BatPackbmsinfo {
  final double value;
  final String unit;
  final String valueDisplay;
  final String nameDispaly;
  final bool max;
  final bool min;

  BatPackbmsinfo({
    this.value = 0,
    this.unit = '',
    this.valueDisplay = '',
    required this.nameDispaly,
    this.max = false,
    this.min = false,
  });

  factory BatPackbmsinfo.fromJson(Map<String, dynamic> json) {
    var valuetemp = json['value'];
    final double value = valuetemp is num
        ? valuetemp.toDouble()
        : (valuetemp is String ? int.tryParse(valuetemp)?.toDouble() : null) ??
            0.0;

    return BatPackbmsinfo(
        value: value,
        unit: json['unit'] as String,
        valueDisplay: json['valueDisplay'] as String,
        nameDispaly: json['nameDisplay'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'valueDisplay': valueDisplay,
      'nameDispaly': nameDispaly,
    };
  }
}
