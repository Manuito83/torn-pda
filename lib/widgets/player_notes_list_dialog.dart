// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';

enum NoteSortType { name, date, color }

enum SortDirection { ascending, descending }

class PlayerNotesListDialog extends StatefulWidget {
  const PlayerNotesListDialog({super.key});

  @override
  PlayerNotesListDialogState createState() => PlayerNotesListDialogState();
}

class PlayerNotesListDialogState extends State<PlayerNotesListDialog> {
  late PlayerNotesController _playerNotesController;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final TextEditingController _searchController = TextEditingController();
  NoteSortType _currentSort = NoteSortType.name;
  bool _isAscending = true;
  String _searchQuery = '';
  List<PlayerNote> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _playerNotesController = Get.find<PlayerNotesController>();
    _loadSortPreference();
    _updateFilteredNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _updateFilteredNotes();
    });
  }

  void _updateFilteredNotes() {
    _filteredNotes = _playerNotesController.notes.values.where((note) {
      if (_searchQuery.isEmpty) return true;

      final nameMatch = note.playerName?.toLowerCase().contains(_searchQuery) ?? false;
      final idMatch = note.playerId.toLowerCase().contains(_searchQuery);

      return nameMatch || idMatch;
    }).toList();

    _sortNotes();
  }

  void _sortNotes() {
    switch (_currentSort) {
      case NoteSortType.name:
        _filteredNotes.sort((a, b) {
          final nameA = a.playerName?.toLowerCase() ?? a.playerId;
          final nameB = b.playerName?.toLowerCase() ?? b.playerId;
          final result = nameA.compareTo(nameB);
          return _isAscending ? result : -result;
        });
        break;
      case NoteSortType.date:
        _filteredNotes.sort((a, b) {
          final dateA = a.updatedAt ?? a.createdAt ?? DateTime(1970);
          final dateB = b.updatedAt ?? b.createdAt ?? DateTime(1970);
          final result = dateA.compareTo(dateB);
          return _isAscending ? result : -result;
        });
        break;
      case NoteSortType.color:
        // Custom order: red > orange > green > none (none last) when ascending
        int rank(String? code) {
          if (PlayerNoteColor.isNone(code)) return 4; // last
          switch (code) {
            case PlayerNoteColor.red:
              return 1;
            case PlayerNoteColor.orange:
              return 2;
            case PlayerNoteColor.green:
              return 3;
            default:
              return 5;
          }
        }
        _filteredNotes.sort((a, b) {
          final rA = rank(a.color);
          final rB = rank(b.color);
          final cmp = rA.compareTo(rB);
          return _isAscending ? cmp : -cmp;
        });
        break;
    }
  }

  Future<void> _loadSortPreference() async {
    final sortIndex = await Prefs().getPlayerNotesSort();
    final isAscending = await Prefs().getPlayerNotesSortAscending();
    setState(() {
      _currentSort = NoteSortType.values[sortIndex];
      _isAscending = isAscending;
    });
  }

  Future<void> _saveSortPreference() async {
    await Prefs().setPlayerNotesSort(_currentSort.index);
    await Prefs().setPlayerNotesSortAscending(_isAscending);
  }

  Future<void> _changeSortType(NoteSortType newSort) async {
    setState(() {
      if (_currentSort == newSort) {
        _isAscending = !_isAscending;
      } else {
        _currentSort = newSort;
        _isAscending = true;
      }
      _sortNotes();
    });
    await _saveSortPreference();
  }

  Future<void> _openBrowser(String playerId) async {
    final browserType = _settingsProvider.currentBrowser;
    final String url = 'https://www.torn.com/profiles.php?XID=$playerId';

    switch (browserType) {
      case BrowserSetting.app:
        await _webViewProvider.openBrowserPreference(
          context: context,
          browserTapType: BrowserTapType.short,
          url: url,
        );
      case BrowserSetting.external:
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Color _getColorByCode(String? colorCode) {
    switch (colorCode) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange[600]!;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width - 40) > 600 ? 600.0 : (screenSize.width - 40);
    final dialogHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: _themeProvider.secondBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Text(
                'Player Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _themeProvider.mainText,
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                style: TextStyle(color: _themeProvider.mainText),
                decoration: InputDecoration(
                  hintText: 'Search by name or ID...',
                  hintStyle: TextStyle(color: _themeProvider.mainText.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search, color: _themeProvider.mainText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _themeProvider.mainText.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _themeProvider.mainText.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _themeProvider.mainText, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Sort options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSortButton('Name', NoteSortType.name, Icons.person),
                  _buildSortButton('Date', NoteSortType.date, Icons.access_time),
                  _buildSortButton('Color', NoteSortType.color, Icons.palette),
                ],
              ),
              const SizedBox(height: 12),

              // Notes list
              Expanded(
                child: _filteredNotes.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No notes available' : 'No notes found',
                          style: TextStyle(
                            color: _themeProvider.mainText,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return _buildNoteCard(note);
                        },
                      ),
              ),

              // Close button
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(color: _themeProvider.mainText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, NoteSortType sortType, IconData icon) {
    final isSelected = _currentSort == sortType;
    return GestureDetector(
      onTap: () => _changeSortType(sortType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _themeProvider.navSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _themeProvider.navSelected : _themeProvider.mainText.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: _themeProvider.mainText,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: _themeProvider.mainText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: _themeProvider.mainText,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(PlayerNote note) {
    return Slidable(
      key: ValueKey('note-${note.playerId}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _deleteNote(note),
            icon: Icons.delete,
            label: 'Delete',
            backgroundColor: Colors.red[700]!,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: _themeProvider.cardColor,
        elevation: 2,
        shape: _themeProvider.currentTheme == AppTheme.extraDark
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: _themeProvider.mainText.withValues(alpha: 0.2),
                  width: 1,
                ),
              )
            : null,
        child: InkWell(
          onTap: () => _editNote(note),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            // Right red indicator
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.red[700]!, width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Small color dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorByCode(note.color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _themeProvider.mainText.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Player info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    note.displayNameFallback,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.mainText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '[${note.playerId}]',
                                  style: TextStyle(
                                    color: _themeProvider.mainText.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                if (note.updatedAt != null || note.createdAt != null)
                                  Text(
                                    _formatDate(note.updatedAt ?? note.createdAt),
                                    style: TextStyle(
                                      color: _themeProvider.mainText.withValues(alpha: 0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (note.note.isEmpty && !PlayerNoteColor.isNone(note.color)) ? 'blank' : note.note,
                          style: TextStyle(
                            fontStyle: note.note.isEmpty && !PlayerNoteColor.isNone(note.color)
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: _themeProvider.mainText,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_browser,
                          color: _themeProvider.mainText,
                          size: 20,
                        ),
                        onPressed: () => _openBrowser(note.playerId),
                        tooltip: 'Open profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(PlayerNote note) async {
    await _playerNotesController.removePlayerNote(note.playerId);
    if (mounted) {
      setState(() {
        _updateFilteredNotes();
      });
    }
  }

  void _editNote(PlayerNote note) {
    showPlayerNotesDialog(
      context: context,
      barrierDismissible: false,
      playerId: note.playerId,
      playerName: note.playerName,
    ).then((_) {
      setState(() {
        _updateFilteredNotes();
      });
    });
  }
}
