import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/wiki_pages.dart';
import 'package:torn_pda/widgets/webviews/webview_simple_dialog.dart';

class WikiMenu extends StatefulWidget {
  const WikiMenu({
    super.key,
    required this.themeProvider,
  });

  final ThemeProvider themeProvider;

  @override
  State<WikiMenu> createState() => _WikiMenuState();
}

class _WikiMenuState extends State<WikiMenu> {
  final _wikiExpController = ExpandableController();
  final _searchController = TextEditingController();

  List<Widget> _searchLines = <Widget>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _buildSearchLines(context, search: _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.book_outlined,
        color: widget.themeProvider.mainText,
      ),
      title: ExpandablePanel(
        theme: ExpandableThemeData(
          iconColor: widget.themeProvider.mainText,
          animationDuration: const Duration(milliseconds: 1),
        ),
        controller: _wikiExpController,
        collapsed: const Text(
          "Wiki",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        expanded: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 14, bottom: 14),
                  child: Text(
                    "Wiki",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
            TextFormField(
              controller: _searchController,
              style: TextStyle(fontSize: 12, color: widget.themeProvider.mainText),
              maxLength: 40,
              maxLines: 1,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (value) {
                if (value.isEmpty) return;
                String url = "https://wiki.torn.com/mediawiki/index.php?search=$value";
                openWebViewSimpleDialog(
                  context: context,
                  initUrl: url,
                );
              },
              decoration: const InputDecoration(
                counterText: "",
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Search',
                labelStyle: TextStyle(fontSize: 12),
              ),
              validator: (value) {
                if (value == null) return null;
                if (value.replaceAll(' ', '').isEmpty) {
                  return "Cannot be empty!";
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _searchLines,
            )
          ],
        ),
      ),
      onTap: () {
        _wikiExpController.toggle();
        _searchController.clear();
      },
    );
  }

  void _buildSearchLines(BuildContext context, {String search = ""}) {
    List<Widget> items = <Widget>[];

    wikiPages.forEach((key, value) {
      addItem() {
        items.add(
          GestureDetector(
            onTap: () {
              openWebViewSimpleDialog(
                context: context,
                initUrl: value,
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (search.isEmpty || (search.isNotEmpty && key.toLowerCase().contains(_searchController.text.toLowerCase()))) {
        addItem();
      }
    });

    setState(() {
      _searchLines = List.from(items);
    });
  }
}
