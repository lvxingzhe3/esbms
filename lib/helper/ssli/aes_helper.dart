import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class AesHelper{
  static List<int> _inputPad(String str){
    List<int> bytes= List.from(utf8.encode(str));
    int secNum= (bytes.length/16).toInt();
    int padNum= 16-(bytes.length-secNum*16);
    for (int i=0; i<padNum; i++){
      bytes.add(0);
    }
    return bytes;
  }

  // return MD5 data
  static String? doEncrypt128CBC(String plainTxt, {required List<int> keyByts}){
    try{
      final key = Key(Uint8List.fromList(keyByts));
      final iv = IV(Uint8List.fromList(keyByts));
      final encrypter = Encrypter(AES(key, mode:AESMode.cbc, padding: null));
      List<int> bytes= _inputPad(plainTxt);
      // print("bytes len="+bytes.length.toString());
      final encrypted = encrypter.encryptBytes(bytes, iv: iv);
      return encrypted.base64;
    }on Exception catch (e){
      print("wifiConfigSoftap error:"+e.toString());
    }
    return null;
  }

  static List<int> _outputUnpad(List<int> bytes){
    // List<int> bytes= List.from(str.codeUnits);
    List<int> tmp= bytes;
    int padStart= tmp.length-1;
    while (tmp[padStart]==0){
      padStart--;
    }
    if (padStart<tmp.length-1){
      tmp.removeRange(padStart+1, tmp.length);
    }
    return tmp;
  }

  // crypted is MD5 data
  // return should by String
  static String? doDecrypt128CBC(String crypted, {required List<int> keyBytes}){
    try{
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(keyBytes));
      final encrypter = Encrypter(AES(key, mode:AESMode.cbc, padding: null));
      List<int> bytes= encrypter.decryptBytes(Encrypted.fromBase64(crypted), iv: iv);
      List<int> unpad= _outputUnpad(bytes);
      String plainTxt = "";
      if(unpad[7] == 51 && unpad[8] == 48 && unpad[9] == 48 && unpad[10] == 48 && unpad[11] == 52){
        print("CID30004 decode");
        List<int> pre = [];
        for(int i = 1; i <= unpad.length; i++){
          String temp;
          try{
            temp = utf8.decode([...pre, unpad[i-1]]);
            pre.clear();
          }catch(error){
            print(error);
            if(error.toString().contains("Unfinished")){
              temp = "";
              pre.add(unpad[i-1]);
            }else{
              temp = "?";
              pre.clear();
            }
          }
          //print("pre:${pre}");
          plainTxt = plainTxt + temp;
        }
      }else{
        plainTxt = utf8.decode(unpad);
      }
      // String plainTxt = encrypter.decrypt(Encrypted.fromBase64(crypted), iv: iv);
      return plainTxt;
    }on Exception catch (e){
      print("wifiConfigSoftap error:"+e.toString());
    }
    return null;
  }
}