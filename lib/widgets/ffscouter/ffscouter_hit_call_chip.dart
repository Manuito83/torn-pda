import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_hit_calling_model.dart';
import 'package:torn_pda/providers/ffscouter_hit_calling_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';

class FFScouterHitCallChip extends StatelessWidget {
  final int targetId;
  final String? targetName;

  const FFScouterHitCallChip({super.key, required this.targetId, this.targetName});

  @override
  Widget build(BuildContext context) {
    if (context.read<SettingsProvider>().ffScouterEnabledStatus != 1) return const SizedBox.shrink();
    return GetBuilder<FFScouterPremiumController>(
      builder: (_) => GetBuilder<FFScouterHitCallingController>(
        builder: (ctrl) {
          if (!ctrl.available) return const SizedBox.shrink();
          if (ctrl.isBusy(targetId)) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final claims = ctrl.claimsFor(targetId);
          if (claims.isEmpty) {
            return GestureDetector(
              onTap: () => _claim(ctrl),
              onLongPress: () => _showDetails(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.front_hand_outlined, size: 18, color: Colors.grey[600]),
              ),
            );
          }

          final myIndex = claims.indexWhere((c) => c.claimerId == UserHelper.playerId);
          final first = claims.first;
          final Color color;
          final String label;
          if (myIndex == 0) {
            color = Colors.green[600]!;
            label = "Mine ${_remaining(first)}";
          } else if (myIndex > 0) {
            color = Colors.orange[700]!;
            label = "#${myIndex + 1} ${first.claimerName ?? "?"}";
          } else {
            color = Colors.red[400]!;
            label = "${first.claimerName ?? "Called"}${claims.length > 1 ? " +${claims.length - 1}" : ""}";
          }

          return GestureDetector(
            onTap: () => _showDetails(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(maxWidth: 110),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.front_hand, size: 12, color: color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _remaining(FFScouterHitClaim claim) {
    final seconds = claim.expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (seconds < 60) return "<1m";
    return "${seconds ~/ 60}m";
  }

  Future<void> _claim(FFScouterHitCallingController ctrl) async {
    _toast(await ctrl.claim(targetId));
  }

  void _toast(String? error) {
    if (error == null) return;
    BotToast.showText(
      text: error,
      contentColor: Colors.red[800]!,
      textStyle: const TextStyle(fontSize: 13, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => GetBuilder<FFScouterHitCallingController>(
        builder: (ctrl) {
          final claims = ctrl.claimsFor(targetId);
          final mine = claims.any((c) => c.claimerId == UserHelper.playerId);
          final myCalls = ctrl.myClaims.length;
          return AlertDialog(
            title: Text("Calls on ${targetName ?? targetId}", style: const TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (claims.isEmpty)
                  const Text("Nobody in your faction has called this target", style: TextStyle(fontSize: 13)),
                for (int i = 0; i < claims.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "#${i + 1}  ${claims[i].claimerName ?? claims[i].claimerId}  "
                      "(expires in ${_remaining(claims[i])})",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: claims[i].claimerId == UserHelper.playerId ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  "Calls are shared with your faction through FFScouter and expire after "
                  "${ctrl.ttlSeconds ~/ 60} minutes.",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              if (myCalls > 0)
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    _toast(await ctrl.releaseAll());
                  },
                  child: Text("Release all mine ($myCalls)"),
                ),
              if (mine)
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    _toast(await ctrl.unclaim(targetId));
                  },
                  child: const Text("Release"),
                )
              else
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    _toast(await ctrl.claim(targetId));
                  },
                  child: Text(claims.isEmpty ? "Call" : "Call too"),
                ),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close")),
            ],
          );
        },
      ),
    );
  }
}
