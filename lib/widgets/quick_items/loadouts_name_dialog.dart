import 'package:flutter/material.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class LoadoutsNameDialog extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final QuickItemsProvider? quickItemsProvider;
  final QuickItem loadout;

  const LoadoutsNameDialog({
    required this.themeProvider,
    required this.quickItemsProvider,
    required this.loadout,
    super.key,
  });

  @override
  _LoadoutsNameDialogState createState() => _LoadoutsNameDialogState();
}

class _LoadoutsNameDialogState extends State<LoadoutsNameDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.loadout.loadoutName!;
  }

  @override
  Widget build(BuildContext context) {
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
                  color: widget.themeProvider!.secondBackground,
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
                    Flexible(
                      child: Text(
                        "Enter a custom name for this loadout (${widget.loadout.loadoutNumber}):",
                        style: TextStyle(fontSize: 12, color: widget.themeProvider!.mainText),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        maxLength: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Save"),
                          onPressed: () {
                            widget.quickItemsProvider!.changeLoadoutName(widget.loadout, _nameController.text);
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Forget it"),
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
                backgroundColor: widget.themeProvider!.secondBackground,
                child: CircleAvatar(
                  backgroundColor: widget.themeProvider!.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Image.asset(
                      'images/icons/loadout.png',
                    ),
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
