import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';

class PipHost extends StatefulWidget {
  final Widget child;

  const PipHost({super.key, required this.child});

  @override
  State<PipHost> createState() => _PipHostState();
}

class _PipHostState extends State<PipHost> {
  final _pip = Get.find<PipController>();
  MediaQueryData? _fullMedia;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return widget.child;
    final media = MediaQuery.of(context);
    return Obx(() {
      final inPip = _pip.inPip.value;
      if (!inPip) _fullMedia = media;
      // Keeps the browser at full size
      final frozen = inPip ? _fullMedia : null;
      return Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: inPip,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: frozen?.size.width,
              maxWidth: frozen?.size.width,
              minHeight: frozen?.size.height,
              maxHeight: frozen?.size.height,
              child: MediaQuery(data: frozen ?? media, child: widget.child),
            ),
          ),
          if (inPip) const Positioned.fill(child: PipView()),
        ],
      );
    });
  }
}

class PipView extends StatefulWidget {
  const PipView({super.key});

  @override
  State<PipView> createState() => _PipViewState();
}

class _PipViewState extends State<PipView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PipController>(
      builder: (pip) {
        return Material(
          color: Colors.black,
          child: FittedBox(
            child: SizedBox(
              width: 240,
              height: 180,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: switch (pip.mode) {
                      PipMode.chain => _chain(),
                      PipMode.player => _player(pip),
                      PipMode.stakeouts => _stakeouts(pip),
                    },
                  ),
                  if (pip.bannerVisible && pip.mode != PipMode.stakeouts)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Text(
                          pip.stakeoutLines.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chain() {
    return GetBuilder<ChainStatusController>(
      builder: (chain) {
        final model = chain.chainModel?.chain;
        if (chain.modelError || model == null) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: chain.watcherActive
                ? BoxDecoration(
                    border: Border.all(color: chain.borderColor, width: 12),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No chain data', style: TextStyle(color: Colors.white, fontSize: 22)),
                if (chain.watcherActive)
                  Text(
                    chain.chainWatcherDefcon.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
              ],
            ),
          );
        }
        final cooldown = (model.cooldown ?? 0) > 0;
        final seconds = chain.currentSecondsCounter;
        Color accent = Colors.green;
        if (cooldown) {
          accent = Colors.lightBlue;
        } else if (model.current! >= 10 && seconds < 60) {
          accent = Colors.red;
        } else if (model.current! >= 10 && seconds < 150) {
          accent = Colors.orange;
        }
        final border = chain.watcherActive
            ? Border.all(color: chain.borderColor, width: 12)
            : Border.all(color: accent, width: 4);
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(border: border, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cooldown ? 'COOLDOWN' : 'CHAIN ${model.current}/${model.max}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  chain.currentChainTimeString,
                  style: TextStyle(color: accent, fontSize: 58, fontWeight: FontWeight.bold),
                ),
              ),
              if (chain.watcherActive)
                Text(
                  chain.chainWatcherDefcon.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _player(PipController pip) {
    (String, Color) status(PipPlayer player) {
      if (player.confined && player.remaining > 0) {
        final d = Duration(seconds: player.remaining);
        final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
        final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
        final color = player.state == 'Hospital' ? Colors.red[300]! : Colors.brown[300]!;
        return (d.inHours > 0 ? '${d.inHours}:$minutes:$secs' : '$minutes:$secs', color);
      }
      if (player.confined) return ('OUT?', Colors.white);
      if (player.state == 'Okay') return ('OKAY', Colors.white);
      return (player.state ?? '...', Colors.white);
    }

    if (pip.players.length > 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final player in pip.sortedPlayers)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: player.highlighted ? Colors.green[700] : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status(player).$1,
                      style: TextStyle(
                        color: player.highlighted ? Colors.white : status(player).$2,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (pip.players.isEmpty) return const SizedBox.shrink();
    final player = pip.players.first;
    var (main, mainColor) = status(player);
    Color background = Colors.black;
    if (player.highlighted) {
      background = DateTime.now().second.isEven ? Colors.green[700]! : Colors.black;
      mainColor = Colors.white;
    }

    return Container(
      color: background,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              main,
              style: TextStyle(color: mainColor, fontSize: 52, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            player.error ? 'API error' : player.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _stakeouts(PipController pip) {
    String age = '';
    if (pip.stakeoutAt != null) {
      final minutes = DateTime.now().difference(pip.stakeoutAt!).inMinutes;
      age = minutes < 1 ? 'just now' : (minutes < 60 ? '$minutes min ago' : '${minutes ~/ 60} h ago');
    }

    if (pip.stakeoutHighlighted) {
      final what = pip.stakeoutLines
          .map((line) {
            final text = line.startsWith(pip.stakeoutName) ? line.substring(pip.stakeoutName.length).trim() : line;
            return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
          })
          .join('\n');
      return Container(
        color: DateTime.now().second.isEven ? Colors.green[700] : Colors.black,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pip.stakeoutName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                what,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              pip.stakeoutCount > 1 ? '${pip.stakeoutCount} alerts, $age' : 'Stakeout, $age',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'STAKEOUTS',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Get.isRegistered<StakeoutsController>() && Get.find<StakeoutsController>().timeUntilStakeoutsSlept() > 0
                  ? 'Sleeping'
                  : '${pip.stakeoutPlayers} ${pip.stakeoutPlayers == 1 ? 'player' : 'players'}',
              style: TextStyle(color: Colors.blue[200], fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            pip.stakeoutAt == null ? 'No alerts yet' : 'Last: ${pip.stakeoutLines.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (pip.stakeoutAt != null) Text(age, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
