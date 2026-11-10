// 计算 crc16
import 'dart:convert';
import 'dart:typed_data';

List<int> calculateCRC16(List<int> data) {
  int crc = 0xFFFF;
  for (int i = 0; i < data.length; i++) {
    crc ^= data[i] & 0xFF;
    for (int j = 0; j < 8; j++) {
      if ((crc & 0x0001) == 1) {
        crc = (crc >> 1) ^ 0xA001;
      } else {
        crc = crc >> 1;
      }
    }
  }
  int crcInt8High = crc & 0xFF;
  int crcInt8Low = crc >> 8;

  return [crcInt8High, crcInt8Low];
}

// 从蓝牙数据中查找特征头并提取数据包
List<int>? extractPacket(List<int> data, List<int> header,
    {int packetSize = 19}) {
  // 查找特征头
  int? headerIndex = findHeader(data, header);
  if (headerIndex == null) return null;

  // 计算数据包的起始和结束位置
  int dataStart = headerIndex + header.length;
  int dataEnd = dataStart + packetSize;

  // 确保不越界
  if (dataEnd > data.length) {
    dataEnd = data.length;
  }

  // 提取数据
  return data.sublist(dataStart, dataEnd);
}

//查找数组是否包含另一个数组
int? findHeader(List<int> data, List<int> header) {
  for (int i = 0; i <= data.length - header.length; i++) {
    bool match = true;
    for (int j = 0; j < header.length; j++) {
      if (data[i + j] != header[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return null;
}

Uint8List intToTwoBytes(int value) {
  // 创建 2 字节的 ByteData
  final byteData = ByteData(2);

  // 以 16 位无符号整数写入（大端序/网络字节序）
  byteData.setUint16(0, value, Endian.big);

  // 返回字节数组
  return byteData.buffer.asUint8List();
}

/// 2 字节 → int（大端序）
int twoBytesToIntBigEndian(List<int> bytes) {
  return (bytes[0] << 8) | bytes[1];
}

/// 2 字节 → int（小端序）
int twoBytesToIntLittleEndian(List<int> bytes) {
  return bytes[0] | (bytes[1] << 8);
}

int fourBytesToInt(List<int> bytes, {Endian endian = Endian.big}) {
  final bd = ByteData.sublistView(Uint8List.fromList(bytes));
  return bd.getInt32(0, endian);
}

//8位int按位取值 低位到高位
List<int> intTo8BitListLSB(int value) {
  value = value & 0xFF;

  List<int> bits = [];
  for (int i = 0; i < 8; i++) {
    bits.add((value >> i) & 1);
  }
  return bits;
}

/// int转2字节 大端模式(高字节在前)
List<int> intTo2BytesBigEndian(int value) {
  int v = value & 0xFFFF; //限制16位，防止超出
  int high = (v >> 8) & 0xFF;
  int low = v & 0xFF;
  return [high, low];
}

//16位int按位取值 低位到高位
List<int> intTo16BitListLSB(int value) {
  value = value & 0xFFFF;

  List<int> bits = [];
  for (int i = 0; i < 16; i++) {
    bits.add((value >> i) & 1);
  }
  return bits;
}

// ascii 转 字符串
String asciiToString(List<int> asciiValues) {
  final asciiDecoder = AsciiDecoder();
  return asciiDecoder.convert(asciiValues);
}

/// int 转4字节List<int> 大端模式(高位在前)
List<int> intTo4BytesBigEndian(int value) {
  final byteData = ByteData(4);
  byteData.setUint32(0, value, Endian.big);
  return byteData.buffer.asUint8List().toList();
}

//hex字符串转List<int>
List<int> hexToList(String hexStr) {
  List<int> res = [];
  for (int i = 0; i < hexStr.length; i += 2) {
    var sub = hexStr.substring(i, i + 2);
    res.add(int.parse(sub, radix: 16));
  }
  return res;
}

/// 将 DateTime 转为 ISO 8601 格式字符串，并附加时区偏移
String formatToIsoWithOffset(DateTime dateTime) {
  // 转为本地时间（若是 UTC 则转换）
  final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;

  // 计算时区偏移（分钟）
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absMinutes = offset.inMinutes.abs();
  final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absMinutes % 60).toString().padLeft(2, '0');

  // 拼接：yyyy-MM-ddTHH:mm:ss+08:00
  final y = local.year.toString().padLeft(4, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');

  return '$y-$mo-${d}T$h:$mi:$s$sign$hours:$minutes';
}
