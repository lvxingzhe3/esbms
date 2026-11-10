import 'package:bms_app/helper/ssli/eutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FronusPanelListTextField extends StatefulWidget {
  TextEditingController _txtCtrl;
  Widget? _profixIcon;
  double _height;
  String _label;
  bool _showStar;
  String? _hint;
  Widget? _actIcon;
  Function()? _onAction;
  bool _hideText;
  bool _isNumber;
  int _splitPos = -1;
  bool _editable;
  TextStyle? _textFieldStyle;
  TextStyle? _labelStyle;

  FronusPanelListTextField(
      {required TextEditingController txtCtrl,
      profixIcon,
      height = 40.0,
      required String label,
      showStart = false,
      hint,
      actIcon,
      onAction,
      isNumber = false,
      hideText = false,
      editable = true,
      textFieldStyle,
      labelStyle})
      : this._txtCtrl = txtCtrl,
        this._profixIcon = profixIcon,
        this._height = height,
        this._label = label,
        this._showStar = showStart,
        this._hint = hint,
        this._actIcon = actIcon,
        this._onAction = onAction,
        this._isNumber = isNumber,
        this._hideText = hideText,
        this._editable = editable,
        this._textFieldStyle = textFieldStyle,
        this._labelStyle = labelStyle {
    if (_txtCtrl.text != null && _txtCtrl.text.isNotEmpty) {
      if (_txtCtrl.text.indexOf("/") >= 0) {
        _splitPos = _txtCtrl.text.indexOf("/");
        print("splitPos=" + _splitPos.toString());
      }
    }
  }

  @override
  State<FronusPanelListTextField> createState() =>
      _FronusPanelListTextFieldState();
}

class _FronusPanelListTextFieldState extends State<FronusPanelListTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 8, right: 8),
          width: double.infinity,
          height: widget._height,
          child: Row(
            children: [
              Text(
                widget._label,
                style: widget._labelStyle ?? TextStyle(fontSize: 14),
              ),
              widget._showStar ? Text("*") : SizedBox.shrink(),
              widget._profixIcon == null
                  ? SizedBox.shrink()
                  : widget._profixIcon!,
              Expanded(
                  child: TextField(
                //focusNode: widget._editable?null:_AlwaysDisabledFocusNode(),
                readOnly: !widget._editable,
                // inputFormatters: [FilteringTextInputFormatter(RegExp("^[a-z0-9A-Z]+"), allow: true)],
                obscureText: widget._hideText,
                //cursorColor: SSLi.themeTextColorNormal,
                keyboardType: widget._isNumber
                    ? TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                textAlign: TextAlign.right,
                style: widget._textFieldStyle ?? TextStyle(fontSize: 14),
                controller: widget._txtCtrl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget._hint,
                  //hintStyle: SSLi.textStyleLittleLight,
                ),
                onChanged: (str) {
                  // print("onChanged str="+str);
                  if (str != null && str.isNotEmpty) {
                    print(widget._splitPos.toString() +
                        "," +
                        str.indexOf("/").toString());
                    if (widget._splitPos >= 0 && str.indexOf("/") < 0) {
                      setState(() {
                        widget._txtCtrl.text =
                            str.insert("/", widget._splitPos);
                      });
                    } else if (widget._splitPos >= 0 && str.indexOf("/") >= 0) {
                      widget._splitPos = str.indexOf("/");
                    }
                  }
                },
              )),
              widget._actIcon == null
                  ? SizedBox.shrink()
                  : Container(
                      padding: EdgeInsets.all(7),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          if (widget._onAction != null) {
                            widget._onAction!();
                          }
                        },
                        child: widget._actIcon,
                      ),
                    ),
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.white30,
        ),
      ],
    );
  }
}

class _AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
