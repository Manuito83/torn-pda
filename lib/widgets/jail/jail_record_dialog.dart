import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class JailRecordDialog extends StatelessWidget {
  const JailRecordDialog({
    required this.recordCallback,
    required this.currentRecord,
    super.key,
  });

  final Function recordCallback;
  final int? currentRecord;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    textController.text = currentRecord.toString();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Set max score",
                              style: TextStyle(fontSize: 11, color: themeProvider.mainText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          TextFormField(
                            style: const TextStyle(fontSize: 14),
                            controller: textController,
                            maxLength: 6,
                            minLines: 1,
                            keyboardType: const TextInputType.numberWithOptions(),
                            decoration: const InputDecoration(
                              isDense: true,
                              counterText: "",
                              border: OutlineInputBorder(),
                              labelText: "",
                            ),
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Cannot be empty!";
                              }
                              final n = int.tryParse(value);
                              if (n == null) {
                                return 'Invalid value!';
                              } else {
                                if (n < 0) {
                                  return 'Min is 0!';
                                } else if (n > 250000) {
                                  return 'Max is 250000!';
                                }
                              }
                              textController.text = value.trim();
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Set"),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop();
                              int? input = int.tryParse(textController.text);
                              recordCallback(input);
                            }
                          },
                        ),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: themeProvider.secondBackground,
                  radius: 22,
                  child: const SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(MdiIcons.alarmPanelOutline),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
