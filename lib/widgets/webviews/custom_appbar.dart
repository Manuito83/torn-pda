import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function onHorizontalDragEnd;
  final Function onTap;
  final AppBar genericAppBar;

  const CustomAppBar({
    Key key,
    this.onHorizontalDragEnd,
    this.onTap,
    this.genericAppBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: onHorizontalDragEnd,
      onTap: onTap,
      child: genericAppBar,
    );
  }

  // implement preferredSize
  @override
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);
}
