import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FaqPage extends ConsumerStatefulWidget {
  const FaqPage({super.key});

  @override
  ConsumerState<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends ConsumerState<FaqPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = "";

  // FAQ 数据，key：问题，value：答案，支持多语言
  late final List<FaqItem> _allFaqList = [
    FaqItem(
      q: S.of(context).faq_q1,
      a: S.of(context).faq_a1,
    ),
    FaqItem(
      q: S.of(context).faq_q2,
      a: S.of(context).faq_a2,
    ),
  ];

  List<FaqItem> get _filterList {
    if (_keyword.trim().isEmpty) return _allFaqList;
    return _allFaqList
        .where((item) =>
            item.q.toLowerCase().contains(_keyword.toLowerCase()) ||
            item.a.toLowerCase().contains(_keyword.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: customTitleText(S.of(context).question),
        isBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _keyword = v),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                //hintText: S.of(context).faq_search_hint,
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: Colors.blue),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filterList.isEmpty
                  ? Center(
                      child:
                          customText("No data", style: TextStyles.textStyle14),
                    )
                  : ListView.builder(
                      itemCount: _filterList.length,
                      itemBuilder: (ctx, index) {
                        final item = _filterList[index];
                        return _FaqExpandTile(item: item);
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class _FaqExpandTile extends StatefulWidget {
  final FaqItem item;
  const _FaqExpandTile({required this.item});

  @override
  State<_FaqExpandTile> createState() => __FaqExpandTileState();
}

class __FaqExpandTileState extends State<_FaqExpandTile> {
  bool _expand = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColor.backgroud,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        initiallyExpanded: false,
        onExpansionChanged: (v) => setState(() => _expand = v),
        title: customText(widget.item.q, style: TextStyles.textStyle14),
        trailing: Icon(
          _expand ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 20,
          color: _expand ? AppColor.primary : Colors.grey,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          customText(widget.item.a, style: TextStyles.textStyleLight14),
        ],
      ),
    );
  }
}

class FaqItem {
  final String q;
  final String a;
  FaqItem({required this.q, required this.a});
}
