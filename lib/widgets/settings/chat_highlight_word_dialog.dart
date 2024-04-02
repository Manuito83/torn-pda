import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class ChatHighlightAddWordsDialog extends StatefulWidget {
  @override
  State<ChatHighlightAddWordsDialog> createState() => ChatHighlightAddWordsDialogState();
}

class ChatHighlightAddWordsDialogState extends State<ChatHighlightAddWordsDialog> {
  final TextEditingController _addChatHighlightTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late SettingsProvider _settingsProvider;
  bool _enableButton = false;

  @override
  void dispose() {
    _addChatHighlightTextController.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: true);
    return AlertDialog(
      title: const Text('Select words to highlight'),
      content: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                    "Your username will be highlighted by default, so you do not need to add it here. "
                    "Keep in mind that the highlights are a simple substring check - if you add 'cat', "
                    "it would match 'catastrophe'.",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    )),
                const SizedBox(height: 15),
                Container(
                  child: Row(
                    children: [
                      Flexible(
                        child: TextFormField(
                          controller: _addChatHighlightTextController,
                          style: const TextStyle(fontSize: 14),
                          maxLength: 30,
                          decoration: InputDecoration(hintText: "Enter a word to highlight"),
                          validator: (s) {
                            if (s is! String || s.trim().isEmpty) {
                              return 'Please enter a valid word';
                            }
                            if (_settingsProvider.highlightWordList.contains(s.trim().toLowerCase())) {
                              return 'Word already added';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.unspecified,
                          onChanged: (s) => setState(() => _enableButton = _formKey.currentState!.validate()),
                          onFieldSubmitted: (s) {
                            if (_formKey.currentState!.validate()) {
                              _addWord(s);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _enableButton
                            ? () {
                                if (!_formKey.currentState!.validate()) return;
                                _addWord(_addChatHighlightTextController.text.toLowerCase());
                              }
                            : null,
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(right: 10),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: _settingsProvider.highlightWordList
                        .map(
                          (s) => Card(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(s)),
                                  IconButton(
                                    onPressed: () {
                                      _removeWord(s);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Got it'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _addWord(String s) {
    _settingsProvider.changeHighlightWordList = [..._settingsProvider.highlightWordList, s.toLowerCase()];
    _addChatHighlightTextController.clear();
  }

  void _removeWord(String s) {
    _settingsProvider.changeHighlightWordList = _settingsProvider.highlightWordList.where((item) => item != s).toList();
  }
}
