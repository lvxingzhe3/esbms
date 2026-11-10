import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DeviceInfoModel extends Equatable {
  DeviceInfoModel({
    this.id,
    this.label,
    this.value,
    this.icon,
  });

  final int? id;
  final String? label;
  dynamic value;
  final DeviceIcon? icon;

  @override
  List<Object?> get props => [id, label, value, icon];

  factory DeviceInfoModel.fromJson(Map<dynamic, dynamic> json) =>
      DeviceInfoModel(
          id: json["id"],
          label: json["label"],
          value: json["value"],
          icon:
              json["icon"] != null ? DeviceIcon.fromJson(json["icon"]) : null);

  Map<String, dynamic> toJson() => {
        "id": id,
        "label": label,
        "value": value,
        "icon": icon,
      };
}

class DeviceIcon {
  DeviceIcon({
    this.type,
    this.color,
  });

  dynamic type;
  Color? color;

  factory DeviceIcon.fromJson(Map<dynamic, dynamic> json) => DeviceIcon(
        type: json["type"],
        color: json["color"],
      );
}

// 设备实体
class DeviceItem {
  final String id;
  final String dtuId;
  final String dtuDtuid;
  final String name;
  final bool isOnline; // 是否在线

  DeviceItem({
    required this.id,
    required this.dtuId,
    this.dtuDtuid='',
    required this.name,
    required this.isOnline,
  });

  factory DeviceItem.fromJson(Map<String,dynamic> json){
    return DeviceItem(id: json['id'] as String, dtuId: json['dtuId'] as String,  dtuDtuid: json['dtuDtuid'] as String,name: json['name'] as String, isOnline:  json['isOnline'] as bool);
  }

  Map<String,dynamic> toJson(){
    return{
      'id':id,
      'dtuId':dtuId,
      'dtuDtuid':dtuDtuid,
      'name':name,
      'isOnline':isOnline,
    };
  }
}
