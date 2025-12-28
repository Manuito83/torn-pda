import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/pages/chaining/yata/yata_targets_distribution.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

enum TargetsSyncAction {
  importYata,
  exportYata,
  tornImported,
  tornFailed,
}

enum _TargetsSyncView {
  selection,
  tornImport,
  yataLoading,
  yataContent,
}

class TargetsSyncDialog extends StatefulWidget {
  const TargetsSyncDialog({
    super.key,
    this.tornTargetsCount,
    required this.targetsProvider,
    required this.onImportFromTorn,
    required this.onImportFromYata,
  });

  final int? tornTargetsCount;
  final TargetsProvider targetsProvider;
  final Future<TornTargetsImportResult> Function(void Function(int fetched) onProgress) onImportFromTorn;
  final Future<YataTargetsImportModel> Function() onImportFromYata;

  @override
  State<TargetsSyncDialog> createState() => _TargetsSyncDialogState();
}

class _TargetsSyncDialogState extends State<TargetsSyncDialog> {
  _TargetsSyncView _view = _TargetsSyncView.selection;
  bool _isLoading = false;
  int _fetched = 0;
  String? _error;
  TornTargetsImportResult? _result;
  bool _yataLoading = false;
  String? _yataError;
  List<TargetsOnlyYata> _onlyYata = [];
  List<TargetsOnlyLocal> _onlyLocal = [];
  List<TargetsBothSides> _bothSides = [];
  double _yataImportPercentage = 0;
  String _yataImportTarget = '';
  bool _yataImporting = false;
  bool _yataCancelRequested = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: theme.secondBackground,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sync_alt, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Sync targets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.mainText),
          ),
        ],
      ),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _dialogBody(theme),
      ),
    );
  }

  Widget _dialogBody(ThemeProvider theme) {
    switch (_view) {
      case _TargetsSyncView.selection:
        return _selectionView(theme);
      case _TargetsSyncView.tornImport:
        return _tornImportView(theme);
      case _TargetsSyncView.yataLoading:
      case _TargetsSyncView.yataContent:
        return _yataView(theme);
    }
  }

  Widget _selectionView(ThemeProvider theme) {
    final hasTornTargets = (widget.tornTargetsCount ?? 0) > 0;
    final tornCountLabel = widget.tornTargetsCount == null
        ? 'Unable to fetch the current number of targets'
        : hasTornTargets
            ? '${widget.tornTargetsCount} targets found in Torn'
            : 'No targets found in Torn';

    return Column(
      key: const ValueKey('selection'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          title: 'TORN',
          subtitle: tornCountLabel,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
            onPressed: (_isLoading || !hasTornTargets) ? null : () => startTornImport(),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(_isLoading ? 'Importing...' : 'Import from Torn'),
          ),
        ),
        const SizedBox(height: 18),
        Divider(color: theme.getTextColor(theme.mainText.withValues(alpha: 0.2))),
        const SizedBox(height: 12),
        _sectionHeader(
          theme,
          title: 'YATA',
          subtitle: 'Sync with YATA to import or export notes and colors',
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
            onPressed: _yataLoading ? null : () => _startYataFlow(),
            icon: _yataLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round),
                  )
                : const Icon(Icons.sync_alt, size: 18),
            label: Text(_yataLoading ? 'Connecting...' : 'Sync with YATA'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _tornImportView(ThemeProvider theme) {
    if (_isLoading) {
      return Column(
        key: const ValueKey('torn-loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Importing from Torn...', style: TextStyle(fontSize: 13, color: theme.mainText)),
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text('Fetched $_fetched targets', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    if (_result != null && _result!.success) {
      return Column(
        key: const ValueKey('torn-success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Import complete', style: TextStyle(fontSize: 13, color: theme.mainText)),
          const SizedBox(height: 8),
          Text('Added ${_result!.imported} targets from Torn.', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(TargetsSyncAction.tornImported),
            child: const Text('Done'),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('torn-error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Import failed', style: TextStyle(fontSize: 13, color: theme.mainText)),
        const SizedBox(height: 8),
        Text(_error ?? 'Unknown error', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(TargetsSyncAction.tornFailed),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _yataView(ThemeProvider theme) {
    if (_yataLoading) {
      return Column(
        key: const ValueKey('yata-loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Connecting to YATA...', style: TextStyle(fontSize: 13, color: theme.mainText)),
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    if (_yataError != null) {
      return Column(
        key: const ValueKey('yata-error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not contact YATA', style: TextStyle(fontSize: 13, color: theme.mainText)),
          const SizedBox(height: 8),
          Text(_yataError!, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _view = _TargetsSyncView.selection;
                    _yataError = null;
                    _yataLoading = false;
                  });
                },
                child: const Text('Back'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      );
    }

    if (_yataImporting) {
      return Column(
        key: const ValueKey('yata-importing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Importing targets from YATA', style: TextStyle(fontSize: 13, color: theme.mainText)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: _yataImportPercentage),
          const SizedBox(height: 8),
          Text(
            _yataImportTarget.isEmpty ? 'Preparing import...' : _yataImportTarget,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _cancelYataImport,
                  child: const Text('Cancel import'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _yataDistributionView(theme);
  }

  Widget _sectionHeader(
    ThemeProvider theme, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.mainText)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: theme.getTextColor(theme.mainText.withValues(alpha: 0.7))),
        ),
      ],
    );
  }

  Widget _yataDistributionView(ThemeProvider theme) {
    final importAvailable = _onlyYata.isNotEmpty || _bothSides.isNotEmpty;
    final exportAvailable = _onlyLocal.isNotEmpty || _bothSides.isNotEmpty;

    return Column(
      key: const ValueKey('yata-distribution'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                height: 28,
                width: 28,
                child: Image.asset('images/icons/yata_logo.png'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Targets distribution',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.mainText)),
                  const SizedBox(height: 4),
                  Text('Review what is in YATA vs local before syncing.',
                      style: TextStyle(fontSize: 12, color: theme.getTextColor(theme.mainText.withValues(alpha: 0.7)))),
                ],
              ),
            ),
            OpenContainer(
              transitionDuration: const Duration(milliseconds: 250),
              transitionType: ContainerTransitionType.fade,
              openBuilder: (BuildContext context, VoidCallback _) {
                return YataTargetsDistribution(
                  bothSides: _bothSides,
                  onlyYata: _onlyYata,
                  onlyLocal: _onlyLocal,
                );
              },
              closedElevation: 0,
              closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              closedColor: Colors.transparent,
              openColor: theme.canvas,
              closedBuilder: (BuildContext context, VoidCallback openContainer) {
                return IconButton(
                  onPressed: openContainer,
                  icon: const Icon(Icons.info_outline, size: 20),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_download, size: 16),
                    const SizedBox(width: 6),
                    Text('${_onlyYata.length} only in YATA', style: TextStyle(fontSize: 12, color: theme.mainText)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.link, size: 16),
                    const SizedBox(width: 6),
                    Text('${_bothSides.length} in both', style: TextStyle(fontSize: 12, color: theme.mainText)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_iphone, size: 16),
                    const SizedBox(width: 6),
                    Text('${_onlyLocal.length} only in Torn PDA',
                        style: TextStyle(fontSize: 12, color: theme.mainText)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: theme.getTextColor(theme.mainText.withValues(alpha: 0.2))),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: importAvailable ? _startYataImport : null,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Import from YATA'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: exportAvailable ? _exportToYata : null,
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: const Text('Export to YATA'),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 6,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _view = _TargetsSyncView.selection;
                  _onlyYata = [];
                  _onlyLocal = [];
                  _bothSides = [];
                }),
                child: const Text('Back'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> startTornImport() async {
    setState(() {
      _view = _TargetsSyncView.tornImport;
      _isLoading = true;
      _error = null;
      _result = null;
      _fetched = 0;
    });

    try {
      final result = await widget.onImportFromTorn((fetched) {
        if (!mounted) return;
        setState(() {
          _fetched = fetched;
        });
      });
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startYataFlow() async {
    setState(() {
      _view = _TargetsSyncView.yataLoading;
      _yataLoading = true;
      _yataError = null;
      _onlyYata = [];
      _onlyLocal = [];
      _bothSides = [];
      _yataImporting = false;
      _yataImportPercentage = 0;
      _yataImportTarget = '';
      _yataCancelRequested = false;
    });

    try {
      final yataTargets = await widget.onImportFromYata();
      if (!mounted) return;

      if (yataTargets.errorConnection || yataTargets.errorPlayer || yataTargets.targets == null) {
        String error = yataTargets.errorPlayer
            ? 'We could not find your user in YATA. Do you have an account there?'
            : 'There was a problem contacting YATA. Try again in a moment.';
        if (yataTargets.errorReason.isNotEmpty) {
          error += '\n\nError code: ${yataTargets.errorReason}';
        }
        setState(() {
          _yataError = error;
          _yataLoading = false;
          _view = _TargetsSyncView.yataContent;
        });
        return;
      }

      final onlyYata = <TargetsOnlyYata>[];
      final onlyLocal = <TargetsOnlyLocal>[];
      final bothSides = <TargetsBothSides>[];

      if (widget.targetsProvider.allTargets.isEmpty) {
        yataTargets.targets!.forEach((key, yataTarget) {
          onlyYata.add(
            TargetsOnlyYata()
              ..id = key
              ..name = yataTarget.name
              ..noteYata = yataTarget.note
              ..colorYata = yataTarget.color,
          );
        });
      } else {
        yataTargets.targets!.forEach((key, yataTarget) {
          bool foundLocally = false;
          for (final localTarget in widget.targetsProvider.allTargets) {
            if (localTarget.playerId.toString() == key) {
              final playerNotesController = Get.find<PlayerNotesController>();
              final playerNote = playerNotesController.getNoteForPlayer(localTarget.playerId.toString());
              bothSides.add(
                TargetsBothSides()
                  ..id = key
                  ..name = yataTarget.name
                  ..noteYata = yataTarget.note
                  ..noteLocal = playerNote?.note ?? ''
                  ..colorLocal = _yataColorCode(playerNote?.color)
                  ..colorYata = yataTarget.color,
              );
              foundLocally = true;
              break;
            }
          }
          if (!foundLocally) {
            onlyYata.add(
              TargetsOnlyYata()
                ..id = key
                ..name = yataTarget.name
                ..noteYata = yataTarget.note
                ..colorYata = yataTarget.color,
            );
          }
        });

        for (final localTarget in widget.targetsProvider.allTargets) {
          bool foundInYata = false;
          yataTargets.targets!.forEach((key, _) {
            if (localTarget.playerId.toString() == key) {
              foundInYata = true;
            }
          });
          if (!foundInYata) {
            final playerNotesController = Get.find<PlayerNotesController>();
            final playerNote = playerNotesController.getNoteForPlayer(localTarget.playerId.toString());
            onlyLocal.add(
              TargetsOnlyLocal()
                ..id = localTarget.playerId.toString()
                ..name = localTarget.name
                ..noteLocal = playerNote?.note ?? ''
                ..colorLocal = _yataColorCode(playerNote?.color),
            );
          }
        }
      }

      setState(() {
        _onlyYata = onlyYata;
        _onlyLocal = onlyLocal;
        _bothSides = bothSides;
        _yataLoading = false;
        _view = _TargetsSyncView.yataContent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yataError = e.toString();
        _yataLoading = false;
        _view = _TargetsSyncView.yataContent;
      });
    }
  }

  int _yataColorCode(String? colorString) {
    switch (colorString) {
      case 'z':
        return 0;
      case 'green':
        return 1;
      case 'orange':
        return 2;
      case 'red':
        return 3;
    }
    return 0;
  }

  Future<void> _startYataImport() async {
    setState(() {
      _yataImporting = true;
      _yataImportPercentage = 0;
      _yataImportTarget = '';
      _yataCancelRequested = false;
    });

    try {
      final attacks = await widget.targetsProvider.getAttacks();
      for (var i = 0; i < _onlyYata.length; i++) {
        if (_yataCancelRequested) {
          break;
        }

        final yataTarget = _onlyYata[i];
        final importResult = await widget.targetsProvider.addTarget(
          targetId: yataTarget.id,
          attacks: attacks,
          notes: yataTarget.noteYata,
          notesColor: _localColorCode(yataTarget.colorYata),
        );

        if (importResult.success && mounted) {
          setState(() {
            _yataImportTarget = yataTarget.name ?? '';
            _yataImportPercentage = (i + 1) / _onlyYata.length;
          });
        }

        if (_onlyYata.length > 60) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      for (final bothSidesTarget in _bothSides) {
        if (_yataCancelRequested) {
          break;
        }

        final notesController = Get.find<PlayerNotesController>();
        await notesController.setPlayerNote(
          playerId: bothSidesTarget.id.toString(),
          note: bothSidesTarget.noteYata ?? '',
          color: _localColorCode(bothSidesTarget.colorYata),
        );
      }

      if (_yataCancelRequested) {
        if (mounted) {
          setState(() {
            _yataImporting = false;
            _yataImportTarget = 'Cancelled';
            _yataImportPercentage = 0;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _yataImportTarget = 'Finishing...';
          _yataImportPercentage = 1;
        });
      }
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(TargetsSyncAction.importYata);
      }
    } catch (e) {
      BotToast.showText(
        text: 'There was an error importing from YATA.\n\n$e',
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        contentColor: Colors.red,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
      if (mounted) {
        setState(() {
          _yataImporting = false;
        });
      }
    }
  }

  Future<void> _exportToYata() async {
    try {
      final exportResult = await widget.targetsProvider.postTargetsToYata(
        onlyLocal: _onlyLocal,
        bothSides: _bothSides,
      );

      if (exportResult == '') {
        BotToast.showText(
          text: 'There was an error exporting!',
          textStyle: const TextStyle(fontSize: 13, color: Colors.white),
          contentColor: Colors.red,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      } else {
        BotToast.showText(
          text: exportResult,
          textStyle: const TextStyle(fontSize: 13, color: Colors.white),
          contentColor: Colors.green,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      BotToast.showText(
        text: 'There was an error exporting!\n\n$e',
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        contentColor: Colors.red,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  String _localColorCode(int? colorInt) {
    switch (colorInt) {
      case 0:
        return PlayerNoteColor.none;
      case 1:
        return 'green';
      case 2:
        return 'orange';
      case 3:
        return 'red';
    }
    return '';
  }

  void _cancelYataImport() {
    setState(() {
      _yataCancelRequested = true;
    });
  }
}
