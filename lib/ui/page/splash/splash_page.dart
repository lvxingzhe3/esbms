import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/helper/shared_prefrence_helper.dart';
import 'package:bms_app/ui/page/user/user_load.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/shape/gf_button_shape.dart';
import 'package:go_router/go_router.dart';
import 'package:bms_app/ui/theme/theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  SharedPreferenceHelper prefs = SharedPreferenceHelper();
  bool hasAgree = false;
  bool visible = false;

  @override
  void initState() {
    super.initState();
    getHasAgree();
  }

  void getHasAgree() async {
    bool _hasAgree = await prefs.getHasAgreePrivacy();
    setState(() {
      hasAgree = _hasAgree;
      visible = !_hasAgree;
    });
  }

  Widget _body({required BuildContext c}) {
    return Container(
      color: AppColor.backgroud,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      /*
      decoration: BoxDecoration(
        
          image: DecorationImage(
              image: AssetImage('assets/images/launch_logo.png'),
              fit: BoxFit.fitWidth)),
              */
      child: Visibility(
        visible: visible,
        child: AlertDialog(
          backgroundColor: AppColor.backgroud,
          title: Center(child: Text(S.of(c).agreementTips)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: S.of(c).agreementTipsTitle),
                    WidgetSpan(
                      child: GestureDetector(
                        child: customText(S.of(c).agreementCaption,
                            style: TextStyle(
                              color: AppColor.primary,
                            )),
                        onTap: () {
                          context.pushNamed('privacy');
                        },
                      ),
                    ),
                    TextSpan(text: S.of(c).agreementText),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: customText(S.of(c).agreementText1),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            GFButton(
                color: AppColor.extraLightGrey,
                textColor: AppColor.darkGrey,
                shape: GFButtonShape.pills,
                onPressed: () {
                  setState(() {
                    visible = false;
                  });
                },
                text: S.of(c).disagree),
            GFButton(
                color: AppColor.primary,
                shape: GFButtonShape.pills,
                onPressed: () {
                  prefs.saveHasAgreePrivacy(true);
                  setState(() {
                    hasAgree = true;
                  });
                },
                text: S.of(c).agree),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwitterColor.white,
      body: !hasAgree ? _body(c: context) : LoginPage(),
    );
  }
}
