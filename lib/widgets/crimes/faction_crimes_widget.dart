// Flutter imports:
import 'package:flutter/material.dart';

class FactionCrimesWidget extends StatefulWidget {
  final String source;

  FactionCrimesWidget({
    Key? key,
    required this.source,
  }) : super(key: key);

  @override
  _FactionCrimesWidgetState createState() => _FactionCrimesWidgetState();
}

class _FactionCrimesWidgetState extends State<FactionCrimesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.source == 'YATA' ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
            height: 18,
          ),
          SizedBox(width: 8),
          Text(
            "Member's NNB source: ${widget.source}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
