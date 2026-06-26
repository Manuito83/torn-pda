import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog_simple.dart';

const String kFFScouterPremiumUrl = 'https://ffscouter.com/premium';

/// Shows [child] if premium, else nothing or a dismissible upgrade promo (when
/// [premiumDataExists]). Triggers a premium re-check on mount
class FFScouterPremiumGate extends StatefulWidget {
  final Widget child;

  final bool premiumDataExists;

  /// Feature name shown in the promo, e.g. "Stat distribution"
  final String featureName;

  const FFScouterPremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.premiumDataExists = true,
  });

  @override
  State<FFScouterPremiumGate> createState() => _FFScouterPremiumGateState();
}

class _FFScouterPremiumGateState extends State<FFScouterPremiumGate> {
  @override
  void initState() {
    super.initState();
    final premium = Get.find<FFScouterPremiumController>();
    if (!premium.isPremium) {
      premium.refreshPremiumStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FFScouterPremiumController>(
      builder: (premium) {
        if (premium.isPremium) return widget.child;
        if (widget.premiumDataExists && premium.shouldShowPromo) {
          return FFScouterPremiumPromo(featureName: widget.featureName, onDismiss: premium.dismissPromo);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// "Premium feature" card with learn-more and dismiss
class FFScouterPremiumPromo extends StatelessWidget {
  final String featureName;
  final VoidCallback onDismiss;

  const FFScouterPremiumPromo({super.key, required this.featureName, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.deepPurple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$featureName is an FFScouter premium feature",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Premium unlocks individual stat distribution, travel and landing "
            "timers, and activity tracking.",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Don't show again", style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () async {
                  await openSimpleWebViewDialog(
                    context: context,
                    url: kFFScouterPremiumUrl,
                    title: 'FFScouter Premium',
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text("Learn more", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
