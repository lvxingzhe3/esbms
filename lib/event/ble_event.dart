class BleDataEvent {
  final List<int> data;        // 原始数据
  final String deviceId;    // 设备 ID
  final DateTime timestamp; // 时间戳
  final Map<String, dynamic>? parsedData; // 解析后的数据（可选）

  BleDataEvent({
    required this.data,
    required this.deviceId,
    this.parsedData,
  }) : timestamp = DateTime.now();
}