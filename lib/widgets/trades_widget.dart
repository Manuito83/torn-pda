import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';

class TradesWidget extends StatefulWidget {
  final int leftMoney;

  TradesWidget({
    @required this.leftMoney,
  });

  @override
  _TradesWidgetState createState() => _TradesWidgetState();
}

class _TradesWidgetState extends State<TradesWidget> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(widget.leftMoney.toString()),
    );
  }
}
