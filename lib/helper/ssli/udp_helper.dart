import 'dart:async';
import 'dart:io';
import 'package:date_format/date_format.dart';
import 'package:udp/udp.dart';

class UdpHelper{
  static UdpHelper? _instance;
  // 私有的命名构造函数
  UdpHelper._internal();
  static UdpHelper getInstance() {
    if (_instance == null) {
      _instance = UdpHelper._internal();
    }
    return _instance!;
  }

  UDP? _udp;
  Function(UdpHelperEvent event)? _callback;
  StreamSubscription? udpRecvListen;
  void doInit({Function(UdpHelperEvent event)? callback}) async {
    if (callback!=null){
      _callback= callback;
    }
    try{
      _udp= await UDP.bind(Endpoint.any(port: Port(58898)));
    }on Exception{return ;}
    // _udp= await UDP.bind(Endpoint.any(port: Port(58898)));
    udpRecvListen?.cancel();
    udpRecvListen= _udp!.asStream().listen((datagram) {
      if (datagram!=null){
        print("recv from:"+datagram!.address.address);
        String recv= String.fromCharCodes(datagram!.data);
        if (_callback!=null){
          _callback!(UdpHelperEvent(type: "recv", data: recv, ip: datagram!.address.address));
        }
      }
    });
  }
  void doStop() {
    udpRecvListen?.cancel();
    if (_udp!=null){
      _udp!.close();
      _udp= null;
    }
  }

  Future<void> doSendBytes(List<int> bytes, {required String ip}) async {
    if (_udp!=null){
      int sendlen= await _udp!.send(bytes, Endpoint.unicast(InternetAddress(ip), port: Port(58899)));
      if (sendlen<=0){
        print("sendlen="+sendlen.toString());
        _udp!.close();
        _udp= null;
        udpRecvListen?.cancel();
        await Future.delayed(Duration(seconds: 3));
        try{
          _udp= await UDP.bind(Endpoint.any(port: Port(58898)));
        }on Exception{return ;}
        udpRecvListen= _udp!.asStream().listen((datagram) {
          if (datagram!=null){
            print("recv from:"+datagram!.address.address);
            String recv= String.fromCharCodes(datagram!.data);
            if (_callback!=null){
              _callback!(UdpHelperEvent(type: "recv", data: recv, ip: datagram!.address.address));
            }
          }
        });
      }
    }
  }

  Future<void> doSend(String str, {required String ip})async{
    print(formatDate(DateTime.now(), [yyyy,"-",mm,"-",dd,"-",HH,":",nn,":",ss,z])+"udp send:"+str+",to:"+ip);
    await doSendBytes(str.codeUnits, ip: ip);
  }
}
class UdpHelperEvent{
  String type;
  var data;
  String? ip;
  UdpHelperEvent({required this.type, this.data, this.ip});
}