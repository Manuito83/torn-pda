import 'dart:math';

import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';

class ShortcutPagedGrid extends StatefulWidget {
  final List<Shortcut> shortcuts;
  final bool showEditIcon;
  final String shortcutTile;
  final Widget Function(Shortcut) shortcutTileBuilder;
  final Widget Function({required double width, required double height}) editTileBuilder;

  const ShortcutPagedGrid({
    super.key,
    required this.shortcuts,
    required this.showEditIcon,
    required this.shortcutTile,
    required this.shortcutTileBuilder,
    required this.editTileBuilder,
  });

  @override
  State<ShortcutPagedGrid> createState() => _ShortcutPagedGridState();
}

class _ShortcutPagedGridState extends State<ShortcutPagedGrid> {
  static const int _columns = 5;
  static const int _maxRows = 2;
  static const int _itemsPerPage = _columns * _maxRows;

  late final PageController _pageController;
  int _currentPage = 0;
  late List<List<_PageItem>> _pages;

  double get _itemHeight {
    switch (widget.shortcutTile) {
      case 'icon':
        return 40;
      case 'text':
        return 40;
      default:
        return 60;
    }
  }

  double get _itemWidth {
    switch (widget.shortcutTile) {
      case 'icon':
        return 40;
      default:
        return 70;
    }
  }

  @override
  void initState() {
    super.initState();
    _rebuildPages();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(ShortcutPagedGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcuts != widget.shortcuts ||
        oldWidget.showEditIcon != widget.showEditIcon ||
        oldWidget.shortcutTile != widget.shortcutTile) {
      _rebuildPages();
      _currentPage = _currentPage.clamp(0, _pages.length - 1);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  void _rebuildPages() {
    final allItems = <_PageItem>[
      for (final s in widget.shortcuts) _PageItem.shortcut(s),
      if (widget.showEditIcon) _PageItem.edit(),
    ];

    _pages = [];
    for (int i = 0; i < allItems.length; i += _itemsPerPage) {
      _pages.add(allItems.sublist(i, min(i + _itemsPerPage, allItems.length)));
    }
    if (_pages.isEmpty) _pages.add([]);
  }

  int _rowsForPage(int pageIndex) {
    if (pageIndex >= _pages.length) return 1;
    final count = _pages[pageIndex].length;
    if (count == 0) return 1;
    return count <= _columns ? 1 : _maxRows;
  }

  @override
  Widget build(BuildContext context) {
    final safePageIndex = _currentPage.clamp(0, _pages.length - 1);
    final rows = _rowsForPage(safePageIndex);
    final double pageHeight = _itemHeight * rows;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: pageHeight,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, pageIndex) {
              return _buildPage(pageIndex);
            },
          ),
        ),
        if (_pages.length > 1) ...[
          const SizedBox(height: 6),
          _buildDotIndicators(context),
        ],
      ],
    );
  }

  Widget _buildPage(int pageIndex) {
    final items = _pages[pageIndex];
    final colCount = min(items.length, _columns);

    // Always lay out for _maxRows; UnconstrainedBox allows the content to exceed
    // the PageView's tight height constraint during the AnimatedContainer transition
    // without triggering overflow errors, while clipBehavior clips the excess.
    return UnconstrainedBox(
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.topCenter,
      constrainedAxis: Axis.horizontal,
      child: SizedBox(
        height: _itemHeight * _maxRows,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(colCount, (col) {
            final bottomIndex = _columns + col;
            return SizedBox(
              width: _itemWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildItem(items[col]),
                  if (bottomIndex < items.length) _buildItem(items[bottomIndex]),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItem(_PageItem item) {
    if (item.isEdit) {
      return widget.editTileBuilder(width: _itemWidth, height: _itemHeight);
    }
    return SizedBox(
      width: _itemWidth,
      height: _itemHeight,
      child: Semantics(
        label: "Shortcut to ${item.shortcut!.name}",
        child: ExcludeSemantics(
          child: widget.shortcutTileBuilder(item.shortcut!),
        ),
      ),
    );
  }

  Widget _buildDotIndicators(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}

class _PageItem {
  final Shortcut? shortcut;
  final bool isEdit;

  _PageItem.shortcut(this.shortcut) : isEdit = false;
  _PageItem.edit()
      : shortcut = null,
        isEdit = true;
}
