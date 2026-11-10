import 'package:flutter/material.dart';

class FronusPanelListCheck extends StatelessWidget {
  double _height;
  Color _color;
  String _label;
  bool _checked;
  Widget? _sufixIcon;
  Function(bool checked) _onTap;
  FronusPanelListCheck(
      {double height = 48,
      Color color = Colors.transparent,
      required String label,
      required bool checked,
      sufixIcon,
      required onTap})
      : this._height = height,
        this._color = color,
        this._label = label,
        this._checked = checked,
        this._sufixIcon = sufixIcon,
        this._onTap = onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 8),
      height: _height,
      width: double.infinity,
      color: _color,
      child: Row(children: [
        _sufixIcon == null ? SizedBox.shrink() : _sufixIcon!,
        _sufixIcon == null
            ? SizedBox.shrink()
            : SizedBox(
                width: 10,
              ),
        Text(_label),
        // Expanded(child: Container(alignment: Alignment.centerRight, child: Text(showValue(), style: SSLi.textStyleLittleWithColor("whitec0"),))),
        // _showArrow?Icon(Icons.keyboard_arrow_right, size: 24, color: SSLi.themeOtherItemColor("light"),):SizedBox.shrink(),
        Spacer(),
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.white30,
          ),
          child: Checkbox(
              activeColor: Colors.white30,
              checkColor: Colors.green,
              value: _checked,
              onChanged: (checked) {
                if (checked != null) _onTap(checked);
              }),
        ),
        SizedBox(
          width: 5,
        ),
      ]),
    );
  }
}
