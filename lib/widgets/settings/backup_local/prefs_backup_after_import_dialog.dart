// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

class PrefsLocalAfterImportDialog extends StatefulWidget {
  final bool autoTriggered;

  const PrefsLocalAfterImportDialog({super.key, this.autoTriggered = true});

  @override
  PrefsLocalAfterImportDialogState createState() => PrefsLocalAfterImportDialogState();
}

class PrefsLocalAfterImportDialogState extends State<PrefsLocalAfterImportDialog> {
  final _scrollController = ScrollController();

  bool _isCloseButtonEnabled = false;
  int _countdownSeconds = 6;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (widget.autoTriggered) {
      _startCountdown();
    } else {
      _isCloseButtonEnabled = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        setState(() {
          _isCloseButtonEnabled = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'READ THIS, ACTION NEEDED!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 30),
                          Text(
                            'Local Preferences Imported',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 30),
                          Text(
                            'After importing a backup from a local file, a new user has been created for you in the '
                            'Torn PDA server to handle Alerts and other settings.\n\n'
                            'As a result, a few things have been reset to their default values.\n\n'
                            'It is highly recommended to visit the Alerts section and reconfigure your alerts preferences.\n\n'
                            'Also, native login, if used, might need to be reconfigured in Settings.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                thickness: 1,
                color: Colors.blueGrey,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: ElevatedButton(
                  onPressed: _isCloseButtonEnabled
                      ? () {
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCloseButtonEnabled ? null : Colors.grey.shade300,
                    foregroundColor: _isCloseButtonEnabled ? null : Colors.grey.shade500,
                  ),
                  child: Text(
                    _isCloseButtonEnabled ? 'Great!' : 'Great! ($_countdownSeconds)',
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
