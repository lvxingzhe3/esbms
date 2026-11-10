import 'package:equatable/equatable.dart';

  //系数
double bmsHalfway = 1;
class BluetoothModel extends Equatable {
  BluetoothModel(this.items);

  final List<DataItem> items;
  @override
  List<Object?> get props => [items];

  factory BluetoothModel.fromJson(List<dynamic> json) {
    List<DataItem> list = json.map((element) {
      String name = element['name'].toLowerCase();
      num value = element['value'];
      num multiple = element['multiple'];
      String unit = element['unit'];

      return DataItem(name: name, value: value, multiple: multiple, unit: unit);
    }).toList();

    return BluetoothModel(list);
  }

  List<dynamic> toJson() {
    return items.map((item) {
      return item.toJson();
    }).toList();
  }

  DataItem get bat {
    return items.firstWhere(
      (item) => item.name == 'bat',
      orElse: () => DataItem(name: 'bat'),
    );
  }

  DataItem get current {
    return items.firstWhere(
      (item) => item.name == 'current',
      orElse: () => DataItem(name: 'current'),
    );
  }

  DataItem get power {
    return items.firstWhere(
      (item) => item.name == 'pow',
      orElse: () => DataItem(name: 'pow'),
    );
  }

  DataItem get bms_halfway {
    return items.firstWhere(
      (item) => item.name == 'bms_halfway',
      orElse: () => DataItem(name: 'bms_halfway'),
    );
  }

  DataItem get fcc {
    return items.firstWhere(
      (item) => item.name == 'fcc',
      orElse: () => DataItem(name: 'fcc'),
    );
  }

  DataItem get cap {
    return items.firstWhere(
      (item) => item.name == 'remain_cap',
      orElse: () => DataItem(name: 'remain_cap'),
    );
  }

  DataItem get soc {
    return items.firstWhere(
      (item) => item.name == 'soc',
      orElse: () => DataItem(name: 'soc'),
    );
  }

  DataItem get cycle {
    return items.firstWhere(
      (item) => item.name == 'cycle',
      orElse: () => DataItem(name: 'cycle'),
    );
  }

  DataItem get max_temperature {
    return items.firstWhere(
      (item) => item.name == 'max_temperature',
      orElse: () => DataItem(name: 'max_temperature'),
    );
  }

  DataItem get min_temperature {
    return items.firstWhere(
      (item) => item.name == 'min_temperature',
      orElse: () => DataItem(name: 'min_temperature'),
    );
  }

  DataItem get max_voltage {
    return items.firstWhere(
      (item) => item.name == 'max_voltage',
      orElse: () => DataItem(name: 'max_voltage'),
    );
  }

  DataItem get min_voltage {
    return items.firstWhere(
      (item) => item.name == 'min_voltage',
      orElse: () => DataItem(name: 'min_voltage'),
    );
  }

  DataItem get dchg_timeuse {
    return items.firstWhere(
      (item) => item.name == 'dchg_timeuse',
      orElse: () => DataItem(name: 'dchg_timeuse'),
    );
  }

  DataItem get bms_protect {
    return items.firstWhere(
      (item) => item.name == 'bms_protect',
      orElse: () => DataItem(name: 'bms_protect'),
    );
  }

  DataItem get alarm {
    return items.firstWhere(
      (item) => item.name == 'alarm',
      orElse: () => DataItem(name: 'alarm'),
    );
  }

  DataItem get bms_version {
    return items.firstWhere(
      (item) => item.name == 'bmsapp_versions',
      orElse: () => DataItem(name: 'bmsapp_versions'),
    );
  }

  List<DataItem> get cells_voltage {
    return items.where((item) => item.name.startsWith('cell_')).toList();
  }

  List<DataItem> get temperatures {
    return items.where((item) {
      RegExp regex = RegExp(r'\d$');
      return regex.hasMatch(item.name) && item.name.startsWith('temperature_');
    }).toList();
  }

  DataItem get main_state {
    return items.firstWhere(
      (item) => item.name == 'main_state',
      orElse: () => DataItem(name: 'main_state'),
    );
  }

    DataItem get bat_type {
    return items.firstWhere(
      (item) => item.name == 'bat_type',
      orElse: () => DataItem(name: 'bat_type'),
    );
  }
}

class DataItem {
  DataItem({
    required this.name,
    this.multiple = 1,
    this.value,
    this.unit,
    this.valueText = '',
  });

  String name;
  num multiple;
  num? value;
  String? unit;
  String valueText;

  factory DataItem.fromJson(Map<dynamic, dynamic> json) => DataItem(
        name: json["name"],
        value: json["value"],
        multiple: json["multiple"],
        unit: json["unit"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "value": value,
        "multiple": multiple,
        "unit": unit,
      };

  num get finalValue {
    return value != null ? value! * multiple : 0;
  }

  String get finalDisplayValue {
    Map<String, String> labelMap = {'number':  '°C'};
    String unitText = labelMap[unit] ?? unit ?? '';
    String valueText = value != null ? '${value! * multiple}' : '--';

    // 电流计算方法：电流采用补码方式，小于32768代表充电电流，大于等于32768代表放电电流。
    // eg: 当前传值为 65425，倍数为 10
    // 放电电流计算公式I= —（65535-value）* 10
    // 例如：电流= -（65535-65425）* 10 = -1100mA
    if (name == 'current' && value != null) {
      String valueSymbol = value! >= 32768 ? '-' : '';
      num valueFmt =
          (valueSymbol == '-' ? (65535 - value!) : value!) * multiple;
      valueText = '$valueSymbol$valueFmt';
    }

    if (name == 'bms_halfway' && value != null) {
      bmsHalfway= double.tryParse(value.toString()) ?? 1;
    }

   if (name == 'pow' && value != null) {
      //num valueFmt =value!/bmsHalfway* multiple;
      num valueFmt =value!* multiple;
      valueText = '$valueFmt';
    }


    // 温度计算公式：温度（℃）=（Value-2730）/10；
    // 例如：最大温度=（2986-2730）/10=25.6℃；
    // 温度最小值=（2606-2730）/10=-12.4
    if (name.contains('temperature') && value != null) {
      if(value==0)
      {
        valueText = '';
      }
      else
      {
        num valueFmt = ((value! - 2730) / 10) * multiple;
        valueText = '$valueFmt';
      }
 
    }

    return '${valueText}${unitText}';
  }
}
