// Flutter imports:
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:expandable/expandable.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';

class JailWidget extends StatefulWidget {
  JailWidget({
    Key key,
  }) : super(key: key);

  @override
  _JailWidgetState createState() => _JailWidgetState();
}

class _JailWidgetState extends State<JailWidget> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          hasIcon: false,
          iconColor: Colors.grey,
          tapBodyToExpand: false,
          tapHeaderToExpand: false,
          tapBodyToCollapse: false,
        ),
        header: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              'VAULT SHARE',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        collapsed: Padding(
          padding: const EdgeInsets.all(10),
          child: _vaultMain(),
        ),
        expanded: null,
      ),
    );
  }

  Widget _vaultMain() {
    return SizedBox.shrink(); // TODO!
  }

    
}
