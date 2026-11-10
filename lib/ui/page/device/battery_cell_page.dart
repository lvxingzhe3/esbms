import 'package:bms_app/model/batpackinfo.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/components/card/gf_card.dart';

class BatteryCellPage extends ConsumerWidget {
  final int balance;
  final List<Batinfo> cellvols;
  final List<Batinfo> celltemps;
  const BatteryCellPage(
      {super.key,
      required this.cellvols,
      required this.celltemps,
      required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Visibility(
      visible: cellvols.isNotEmpty || celltemps.isNotEmpty,
      child: Column(children: [
        GFCard(
          color: AppColor.backgroud,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
          // 改用 shrinkWrap ListView，避免Column溢出
          content: cellvols.isNotEmpty
              ? Wrap(
                  runSpacing: 6,
                  children: cellvols
                      .map((model) => FractionallySizedBox(
                          widthFactor: 1 / 4,
                          child: int.tryParse(model.label) == balance
                              ? CellVolBalcanceItem(model: model)
                              : CellVolItem(model: model)))
                      .toList(),
                )
              : SizedBox.shrink(),
        ),
        GFCard(
          color: AppColor.backgroud,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
          // 改用 shrinkWrap ListView，避免Column溢出
          content: celltemps.isNotEmpty
              ? Wrap(
                  runSpacing: 6,
                  children: celltemps
                      .map((model) => FractionallySizedBox(
                            widthFactor: 1 / 4,
                            child: CellTempItem(model: model),
                          ))
                      .toList(),
                )
              : SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class CellVolItem extends StatelessWidget {
  final dynamic model;
  const CellVolItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 几何中心对齐
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  IconFont.batcell,
                  color: AppColor.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 1),
              customText('${model.label}',
                  style: TextStyle(color: AppColor.green, fontSize: 14)),
            ],
          ),
          SizedBox(width: 4),
          if (model.max)
            customText('${model.value}V',
                style: TextStyle(color: Colors.red, fontSize: 14))
          else if (model.min)
            customText('${model.value}V',
                style: TextStyle(color: Colors.blue, fontSize: 14))
          else
            customText('${model.value}V',
                style: TextStyles.textStyle14, textAlign: TextAlign.left),
        ],
      ),
    );
  }
}

class CellVolBalcanceItem extends StatelessWidget {
  final dynamic model;
  const CellVolBalcanceItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 几何中心对齐
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  IconFont.batcell,
                  color: AppColor.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 1),
              customText('${model.label}',
                  style: TextStyle(color: AppColor.green, fontSize: 14)),
              Icon(
                IconFont.balance,
                color: Colors.amber,
                size: 12,
              ),
            ],
          ),
          SizedBox(width: 4),
          if (model.max)
            customText('${model.value}V',
                style: TextStyle(color: Colors.red, fontSize: 14))
          else if (model.min)
            customText('${model.value}V',
                style: TextStyle(color: Colors.blue, fontSize: 14))
          else
            customText('${model.value}V',
                style: TextStyles.textStyle14, textAlign: TextAlign.left),
        ],
      ),
    );
  }
}

class CellTempItem extends StatelessWidget {
  final dynamic model;
  const CellTempItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 几何中心对齐
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Icon(
                  IconFont.battemp,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 1),
              customText('${model.label}',
                  style: TextStyle(color: Colors.orange, fontSize: 14)),
            ],
          ),
          SizedBox(height: 4),
          if (model.value == "4093")
            customText('NC')
          else if (model.value == "4092")
            customText('SC')
          else if (model.max)
            customText('${model.value}°C',
                style: const TextStyle(color: Colors.red, fontSize: 14))
          else if (model.min)
            customText('${model.value}°C',
                style: const TextStyle(color: Colors.blue, fontSize: 14))
          else
            customText('${model.value}°C',
                style: TextStyles.textStyle14, textAlign: TextAlign.left),
        ],
      ),
    );
  }
}
