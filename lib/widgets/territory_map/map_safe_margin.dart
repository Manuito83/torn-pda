import 'package:flutter/widgets.dart';

const _air = 8.0;

// Clear of the system gesture bar
double mapBottomMargin(BuildContext context) => MediaQuery.paddingOf(context).bottom + _air;
