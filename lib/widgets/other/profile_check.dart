import 'package:flutter/material.dart';


class ProfileAttackCheckWidget extends StatefulWidget {
  final int profileId;

  ProfileAttackCheckWidget({
    @required this.profileId,
  });

  @override
  _ProfileAttackCheckWidgetState createState() => _ProfileAttackCheckWidgetState();
}

class _ProfileAttackCheckWidgetState extends State<ProfileAttackCheckWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Align(
        alignment: Alignment.center,
        child: Text("lala"),
      ),
    );
  }


}
