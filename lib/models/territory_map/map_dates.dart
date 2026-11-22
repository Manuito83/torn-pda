import 'package:intl/intl.dart';
import 'package:torn_pda/providers/settings_provider.dart';

// Torn time is UTC
String mapDate(DateTime at, TimeZoneSetting zone, {String pattern = 'd MMM y'}) =>
    DateFormat(pattern).format(zone == TimeZoneSetting.tornTime ? at.toUtc() : at.toLocal());
