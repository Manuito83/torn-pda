import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function onHorizontalDragEnd;
  final AppBar genericAppBar;

  const CustomAppBar({Key key, this.onHorizontalDragEnd, this.genericAppBar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: genericAppBar,
    );
  }

  // implement preferredSize
  @override
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);
}