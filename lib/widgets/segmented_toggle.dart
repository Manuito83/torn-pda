import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class SegmentedToggle extends StatefulWidget {
  const SegmentedToggle({
    super.key,
    required this.selectedIndex,
    required this.onToggle,
    this.itemWidth = 72,
    this.labels,
    this.icons,
    this.customIcons,
    this.allowDeselect = false,
    this.activeColor,
  });

  final int? selectedIndex;
  final void Function(int? index) onToggle;
  final double itemWidth;
  final List<String>? labels;
  final List<IconData>? icons;

  /// Icons with their own size and color
  final List<Icon>? customIcons;
  final bool allowDeselect;
  final Color? activeColor;

  @override
  State<SegmentedToggle> createState() => _SegmentedToggleState();
}

class _SegmentedToggleState extends State<SegmentedToggle> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(SegmentedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final light = theme == AppTheme.light;

    final borderColor = light ? Colors.blueGrey : Colors.grey[900]!;
    final inactiveBg = light
        ? Colors.white
        : theme == AppTheme.dark
        ? Colors.grey[800]!
        : Colors.black;
    final activeBg = widget.activeColor ?? (theme == AppTheme.extraDark ? Colors.blueGrey[900]! : Colors.blueGrey);
    final fg = light ? Colors.black : Colors.white;

    final count = max(widget.labels?.length ?? 0, max(widget.icons?.length ?? 0, widget.customIcons?.length ?? 0));

    final children = <Widget>[];
    for (var i = 0; i < count; i++) {
      final active = i == _selected;

      Widget? icon;
      if (widget.customIcons != null) {
        icon = widget.customIcons![i];
      } else if (widget.icons != null) {
        icon = Icon(widget.icons![i], color: fg, size: min(15.0, widget.itemWidth / 3));
      }

      BorderRadius? corners;
      if (i == 0) corners = const BorderRadius.horizontal(left: Radius.circular(4));
      if (i == count - 1) corners = const BorderRadius.horizontal(right: Radius.circular(4));

      children.add(
        Flexible(
          child: GestureDetector(
            onTap: () => _onTap(i),
            child: AnimatedContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              constraints: BoxConstraints(maxWidth: widget.itemWidth),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: active ? activeBg : Colors.transparent, borderRadius: corners),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) icon,
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: icon == null ? 0 : 5),
                      child: Text(
                        widget.labels?[i] ?? '',
                        style: TextStyle(color: fg, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (i < count - 1) {
        final hidden = i == _selected || i + 1 == _selected;
        children.add(
          Container(
            width: 1,
            height: double.infinity,
            color: hidden ? Colors.transparent : Colors.white30,
            margin: EdgeInsets.symmetric(vertical: hidden ? 0 : 8),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: inactiveBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  void _onTap(int index) {
    final newIndex = widget.allowDeselect && _selected == index ? null : index;
    setState(() => _selected = newIndex);
    widget.onToggle(newIndex);
  }
}
