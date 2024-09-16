// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class EventIcons extends StatelessWidget {
  const EventIcons({
    super.key,
    required this.message,
    required this.themeProvider,
  });

  final String message;
  final ThemeProvider? themeProvider;

  @override
  Widget build(BuildContext context) {
    Widget insideIcon;
    if (message.contains('revive')) {
      insideIcon = const Icon(
        Icons.local_hospital,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('the director of') ||
        message.contains('You have been fired from') ||
        message.contains('You application to join the company')) {
      insideIcon = Icon(
        Icons.work,
        color: Colors.brown[300],
        size: 20,
      );
    } else if (message.contains('After becoming very ill, you decide to head')) {
      insideIcon = Icon(
        MdiIcons.radioactive,
        color: Colors.amber[800],
        size: 20,
      );
    } else if (message.contains('The territorial was between') ||
        message.contains('has initiated an assault on') ||
        message.contains('successfully assaulted')) {
      insideIcon = Icon(
        MdiIcons.fencing,
        color: themeProvider!.mainText,
        size: 20,
      );
    } else if (message.contains('You are now known in the city as')) {
      insideIcon = Icon(
        MdiIcons.thoughtBubble,
        color: themeProvider!.mainText,
        size: 20,
      );
    } else if (message.contains('jail') || message.contains('arrested you')) {
      insideIcon = Center(
        child: Image.asset(
          'images/icons/jail.png',
          color: themeProvider!.currentTheme == AppTheme.light ? Colors.grey[800] : Colors.grey[400],
          width: 20,
          height: 20,
        ),
      );
    } else if (message.contains('trade')) {
      insideIcon = const Icon(
        Icons.monetization_on,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('A stock dividend from')) {
      insideIcon = Icon(
        MdiIcons.bankTransfer,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('has given you') ||
        message.contains('You were sent') ||
        message.contains('You have been credited with') ||
        message.contains('on your doorstep')) {
      insideIcon = const Icon(
        Icons.card_giftcard,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('Get out of my education') || message.contains('You must have overdosed')) {
      insideIcon = const Icon(
        Icons.warning,
        color: Colors.red,
        size: 20,
      );
    } else if (message.contains('purchased membership')) {
      insideIcon = Icon(
        Icons.fitness_center,
        color: themeProvider!.mainText,
        size: 20,
      );
    } else if (message.contains('You upgraded your level')) {
      insideIcon = const Icon(
        Icons.file_upload,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('The education course you were taking has')) {
      insideIcon = const Icon(
        Icons.book,
        color: Colors.brown,
        size: 20,
      );
    } else if (message.contains('your proposal, you are now engaged')) {
      insideIcon = Icon(
        MdiIcons.ring,
        color: Colors.amber[800],
        size: 20,
      );
    } else if (message.contains('You divorced')) {
      insideIcon = Icon(
        MdiIcons.heartBroken,
        color: Colors.red[800],
        size: 20,
      );
    } else if (message.contains('won') ||
        message.contains('lottery') ||
        message.contains('check has been credited to your') ||
        message.contains('withdraw your check from the bank') ||
        message.contains('Your bank investment has ended') ||
        message.contains('You were given \$')) {
      insideIcon = Icon(
        MdiIcons.cash100,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('attacked you') ||
        message.contains('mugged you and stole') ||
        message.contains('attacked and hospitalized')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/ic_target_account_black_48dp.png',
            width: 20,
            height: 20,
            color: Colors.red,
          ),
        ),
      );
    } else if (message.contains('You and your team') ||
        message.contains('You have been selected') ||
        message.contains('canceled the')) {
      insideIcon = Container(
        child: Center(
          child: Icon(
            MdiIcons.fingerprint,
            color: themeProvider!.currentTheme == AppTheme.light ? Colors.grey[800] : Colors.grey[400],
          ),
        ),
      );
    } else if (message.contains('You left your faction') ||
        message.contains('Your application to join the faction') ||
        message.contains('has applied to join your faction')) {
      insideIcon = Container(
        child: Center(
          child: Image.asset(
            'images/icons/faction.png',
            width: 15,
            height: 15,
            color: themeProvider!.mainText,
          ),
        ),
      );
    } else if (message.contains('You came') ||
        message.contains('race.') ||
        message.contains('race and have received') ||
        message.contains('Your best lap was')) {
      insideIcon = Icon(
        MdiIcons.gauge,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('Your bug report')) {
      insideIcon = Icon(
        MdiIcons.bug,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('You can begin programming a new virus')) {
      insideIcon = Icon(
        MdiIcons.virusOutline,
        color: Colors.red[500],
        size: 20,
      );
    } else if (message.contains('from your bazaar for')) {
      insideIcon = Icon(
        MdiIcons.store,
        color: Colors.green,
        size: 20,
      );
    } else if (message.contains('Your period of renting the') ||
        message.contains('has sent an offer for you to rent') ||
        message.contains('day extension on the rental of') ||
        message.contains('Your rental agreement with')) {
      insideIcon = Icon(
        Icons.house_outlined,
        color: Colors.orange[900],
        size: 20,
      );
    } else {
      insideIcon = Container(
        child: const Center(
          child: Text(
            'T',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    return insideIcon;
  }
}
