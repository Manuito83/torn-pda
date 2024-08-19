import 'package:flutter/material.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class EditTabDialog extends StatefulWidget {
  final TabDetails tabDetails;
  final Function(String, bool, bool) onSave;

  EditTabDialog({required this.tabDetails, required this.onSave});

  @override
  EditTabDialogState createState() => EditTabDialogState();
}

class EditTabDialogState extends State<EditTabDialog> {
  late TextEditingController _customNameController;
  late bool _showCustomNameInTitle;
  late bool _showCustomNameInTab;

  @override
  void initState() {
    super.initState();
    _customNameController = TextEditingController(text: widget.tabDetails.customName);
    _showCustomNameInTitle = widget.tabDetails.customNameInTitle;
    _showCustomNameInTab = widget.tabDetails.customNameInTab;
  }

  void _clearFields() {
    setState(() {
      _customNameController.clear();
      _showCustomNameInTitle = false;
      _showCustomNameInTab = true;
    });
  }

  void _saveChanges() {
    widget.onSave(
      _customNameController.text,
      _showCustomNameInTitle,
      _showCustomNameInTab,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Custom tab name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  style: TextStyle(
                    fontSize: 12,
                    //color: _themeProvider!.mainText,
                  ),
                  controller: _customNameController,
                  maxLength: 15,
                  onFieldSubmitted: (value) {
                    _saveChanges();
                  },
                  decoration: const InputDecoration(
                    counterText: "",
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Tab name',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _customNameController.clear();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          SwitchListTile(
            title: Text(
              'Show in page title',
              style: TextStyle(fontSize: 13),
            ),
            value: _showCustomNameInTitle,
            onChanged: (bool value) {
              setState(() {
                _showCustomNameInTitle = value;
              });
            },
          ),
          SwitchListTile(
            title: Text(
              'Show in tab',
              style: TextStyle(fontSize: 13),
            ),
            value: _showCustomNameInTab,
            onChanged: (bool value) {
              setState(() {
                _showCustomNameInTab = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearFields();
            _saveChanges();
          },
          child: Text('Clear'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: Text('Save'),
        ),
      ],
    );
  }
}
