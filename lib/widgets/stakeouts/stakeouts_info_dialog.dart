import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:torn_pda/providers/stakeouts_controller.dart';

class StakeoutsInfoDialog extends StatefulWidget {
  const StakeoutsInfoDialog({
    super.key,
  });

  @override
  State<StakeoutsInfoDialog> createState() => StakeoutsInfoDialogState();
}

class StakeoutsInfoDialogState extends State<StakeoutsInfoDialog> {
  final _maxDelayController = TextEditingController();
  final _maxDelayFormState = GlobalKey<FormState>();

  final _scrollController = ScrollController();

  final bool _firstLoad = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StakeoutsController>(
      builder: (s) {
        if (_firstLoad) {
          _maxDelayController.text = s.fetchMinutesDelayLimit.toString();
        }
        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: AlertDialog(
            title: const Text("Stakeouts...?"),
            content: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "GENERAL",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text.rich(
                        TextSpan(
                          text:
                              "The Stakeouts section allows you configure specific alerts for players of your choice.\n\n"
                              "Please be aware that these alerts are only active while using Torn PDA. They will NOT "
                              "generate notifications if the app is in the background or closed."
                              "\n\nThere is a maximum of 15 slots for targets and each one of them is updated every 30 "
                              "seconds, minimizing API usage as much as practicable",
                          style: TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: "\n\n\nDELAYED ALERTS",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "\n\nWhenever you launch the application, or when stakeouts are re-enabled (using the "
                                  "main switch), some of your targets might be out of date. If this situation, you might get "
                                  "instant alert for a condition that is no longer true (e.g.: you relaunch Torn PDA after 12 "
                                  "hours of no use, and some of your targets cause alerts for changes that took place hours ago "
                                  "that are no longer useful).\n\nBy default, changes that happened more than 60 minutes ago "
                                  "won't generate an alert, but you can change this setting here:",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Flexible(
                              child: Text(
                                "Max alert delay (minutes)",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            Flexible(
                              child: Form(
                                key: _maxDelayFormState,
                                child: SizedBox(
                                  width: 150,
                                  child: TextFormField(
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    controller: _maxDelayController,
                                    maxLength: 4,
                                    minLines: 1,
                                    keyboardType: const TextInputType.numberWithOptions(),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      counterText: "",
                                      isDense: true,
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          style: BorderStyle.none,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          style: BorderStyle.none,
                                        ),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'\d+'),
                                      )
                                    ],
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "Cannot be empty!";
                                      }
                                      final n = num.tryParse(value);
                                      if (n == null) {
                                        return '$value is not a number!';
                                      }
                                      final int number = n as int;
                                      if (number > 2880) {
                                        return 'Max 2 days (2880)!';
                                      } else if (number < 1) {
                                        return 'Min 1 minute!';
                                      }
                                      _maxDelayController.text = value.trim();
                                      return null;
                                    },
                                    onEditingComplete: () {
                                      if (_maxDelayFormState.currentState!.validate()) {
                                        s.fetchMinutesDelayLimit = int.tryParse(_maxDelayController.text)!;
                                      }
                                      final FocusScopeNode currentFocus = FocusScope.of(context);
                                      if (!currentFocus.hasPrimaryFocus) {
                                        currentFocus.unfocus();
                                      }
                                    },
                                    onTapOutside: (value) {
                                      if (_maxDelayFormState.currentState!.validate()) {
                                        s.fetchMinutesDelayLimit = int.tryParse(_maxDelayController.text)!;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  child: const Text("Sounds good!"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
