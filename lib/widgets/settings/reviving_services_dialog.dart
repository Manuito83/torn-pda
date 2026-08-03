// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/profile/revive_services/revive_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/revive/revive_provider_info_text.dart';

class RevivingServicesDialog extends StatefulWidget {
  @override
  RevivingServicesDialogState createState() => RevivingServicesDialogState();
}

class RevivingServicesDialogState extends State<RevivingServicesDialog> {
  final WarController _w = Get.find<WarController>();

  final _pageController = PageController();

  // Provider whose details are being shown in the second page (null while showing the list)
  ReviveProvider? _details;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Both pages share this height so that the dialog doesn't resize when switching
    final double contentHeight = min(430, MediaQuery.of(context).size.height * 0.55);

    return PopScope(
      canPop: _details == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showList();
      },
      child: AlertDialog(
        title: _details == null
            ? const Text("Reviving services")
            : Row(
                children: [
                  Image.asset(_details!.icon, width: 24),
                  const SizedBox(width: 10),
                  Flexible(child: Text(_details!.name)),
                ],
              ),
        content: SizedBox(
          width: double.maxFinite,
          height: contentHeight,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_servicesList(), _serviceDetails()],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _details == null
                ? TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                : TextButton(child: const Text("Back"), onPressed: _showList),
          ),
        ],
      ),
    );
  }

  Widget _servicesList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            "Choose which reviving services you might want to use. "
            "If enabled, when you are in hospital you'll have the option to call "
            "one of their revivers from several places (e.g. Profile and Chaining sections).",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 5),
          for (final provider in ReviveProviders.all)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(provider.settingsTitle, style: const TextStyle(fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    tooltip: "More information",
                    onPressed: () => _showDetails(provider),
                  ),
                  Switch(
                    value: provider.isActive(_w),
                    onChanged: (value) {
                      setState(() {
                        provider.setActive(_w, value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          const Text(
            "NOTE: Torn PDA is not affiliated to any of these services in any form",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _serviceDetails() {
    if (_details == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReviveProviderInfoText(provider: _details!),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text("Use ${_details!.name}", style: const TextStyle(fontSize: 13))),
              Switch(
                value: _details!.isActive(_w),
                onChanged: (value) {
                  setState(() {
                    _details!.setActive(_w, value);
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(ReviveProvider provider) {
    setState(() => _details = provider);
    _pageController.animateToPage(1, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _showList() {
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut).whenComplete(
      () {
        if (mounted) setState(() => _details = null);
      },
    );
  }
}
