import 'package:flutter/material.dart';

class FronusPanelListText extends StatelessWidget {
  double _height;
  Color _color;
  String _label;
  dynamic _value;
  bool _showArrow;
  bool _isRequiresPadding;
  Widget? _sufixIcon;
  TextStyle? _style;
  String? _unit;
  bool _islock;
  List<int>? _flex; //分配label和value所占空间的比例
  Function(String strValue)? _onTap;
  FronusPanelListText(
      {double height = 48,
      Color color = Colors.transparent,
      required String label,
      required value,
      showArrow = true,
      isRequiresPadding = true,
      sufixIcon,
      unit,
      style,
      islock,
      flex,
      onTap})
      : this._height = height,
        this._color = color,
        this._label = label,
        this._value = value,
        this._style = style,
        this._showArrow = showArrow,
        this._isRequiresPadding = isRequiresPadding,
        this._sufixIcon = sufixIcon,
        this._unit = unit,
        this._islock = islock,
        this._flex = flex,
        this._onTap = onTap;

  String showValue() {
    if (_value is double) {
      return _value.toStringAsFixed(2);
    } else if (_value is int) {
      return _value.toString();
    } else if (_value is String) {
      return _value;
    } else {
      return "--";
    }
  }

  @override
  Widget build(BuildContext context) {
    String showStr = showValue();
    if (showStr != "--") {
      showStr += _unit ?? "";
    }
    return GestureDetector(
      onTap: () {
        if (_onTap != null) _onTap!(showValue());
      },
      child: Container(
        padding: EdgeInsets.all(_isRequiresPadding ? 10 : 0),
        height: _height,
        width: double.infinity,
        color: _color,
        child: Row(
            children: _flex == null
                ? [
                    _sufixIcon == null ? SizedBox.shrink() : _sufixIcon!,
                    SizedBox(
                      width: 10,
                    ),
                    Text(_label),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                        child: Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                              showStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ))),
                    _showArrow
                        ? Icon(
                            Icons.keyboard_arrow_right,
                            size: 24,
                            color: Colors.white30,
                          )
                        : SizedBox.shrink(),
                    SizedBox(
                      width: 5,
                    ),
                  ]
                : [
                    _sufixIcon == null ? SizedBox.shrink() : _sufixIcon!,
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: Row(children: [
                      Expanded(
                          flex: _flex![0],
                          child: Text(
                            _label
                                .replaceAll(' ', '\u{000A0}')
                                .replaceAll('-', '\u{2011}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                      // Expanded(flex: _flex![1], child: Container(alignment: Alignment.centerRight, child: Text("  $showStr".replaceAll(' ', '\u{000A0}').replaceAll('-', '\u{2011}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: SSLi.textStyleLittle,))),
                      Expanded(
                        flex: _flex![1],
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: _islock
                              ? Icon(
                                  Icons.lock,
                                  size: 20,
                                  color: Colors.grey,
                                )
                              : Icon(
                                  Icons.lock_open,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    ])),
                    _showArrow
                        ? Icon(
                            Icons.keyboard_arrow_right,
                            size: 24,
                            color: Colors.white30,
                          )
                        : SizedBox.shrink(),
                    SizedBox(
                      width: 5,
                    ),
                  ]),
      ),
    );
  }
}
