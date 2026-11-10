part of 'theme.dart';

class TextStyles {
  TextStyles._();

  static TextStyle get onPrimaryTitleText {
    return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
  }

  static TextStyle get onPrimarySubTitleText {
    return const TextStyle(
      color: Colors.white,
    );
  }

  static TextStyle get titleStyle {
    return const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle get subtitleStyle {
    return const TextStyle(
        color: AppColor.white, fontSize: 14, fontWeight: FontWeight.w300);
  }

  static TextStyle get userNameStyle {
    return const TextStyle(
        color: AppColor.white, fontSize: 14, fontWeight: FontWeight.w300);
  }

  static TextStyle get textStyle14 {
    return const TextStyle(
        color: AppColor.white, fontSize: 14, fontWeight: FontWeight.w400);
  }

  static TextStyle get textStyleVlue {
    return const TextStyle(
        color: AppColor.primary, fontSize: 14, fontWeight: FontWeight.w300);
  }

  static TextStyle get textStyle16 {
    return const TextStyle(
        color: AppColor.white, fontSize: 16, fontWeight: FontWeight.w500);
  }

  static TextStyle get textStyleTitle {
    return const TextStyle(
        color: AppColor.white, fontSize: 28, fontWeight: FontWeight.w600);
  }

  static TextStyle get textStyleLight14 {
    return const TextStyle(
        color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w300);
  }

  static TextStyle get textStyleLight {
    return const TextStyle(
        color: AppColor.lightGrey, fontSize: 10, fontWeight: FontWeight.w500);
  }
}
