import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  SharedPreferenceHelper._internal();
  static final SharedPreferenceHelper _singleton =
      SharedPreferenceHelper._internal();

  factory SharedPreferenceHelper() {
    return _singleton;
  }

  Future clearPreferenceValues() async {
    (await SharedPreferences.getInstance()).clear();
  }

  Future<bool> getHasAgreePrivacy() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.Privacy.toString()) ??
        false;
  }

  Future<bool> saveHasAgreePrivacy(bool isAgree) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.Privacy.toString(), isAgree);
  }

  Future<String?> getLastDeviceId() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.LastDeviceId.toString());
  }

  Future<bool> saveLastDeviceId(String id) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.LastDeviceId.toString(), id);
  }

  Future<String?> getLang() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Lang.toString());
  }

  Future<bool> saveLang(String lang) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.Lang.toString(), lang);
  }
}

enum UserPreferenceKey { UserProfile, UserName, Privacy, LastDeviceId, Lang }
