// Flutter imports:
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function? onHorizontalDragEnd;
  final Function? onPanEnd;
  final Function? onTap;
  final AppBar? genericAppBar;

  const CustomAppBar({
    super.key,
    this.onHorizontalDragEnd,
    this.onPanEnd,
    this.onTap,
    this.genericAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: onHorizontalDragEnd as void Function(DragEndDetails)?,
      onPanEnd: onPanEnd as void Function(DragEndDetails)?,
      onTap: onTap as void Function()?,
      child: genericAppBar,
    );
  }

  // implement preferredSize
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
