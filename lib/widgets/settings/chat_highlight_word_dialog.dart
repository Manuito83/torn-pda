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
  List<String> _wordList = [];
  bool _enableButton = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _wordList = _settingsProvider.highlightWordList;
  }

  @override
  void dispose() {
    _addChatHighlightTextController.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select words to highlight'),
      content: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          )),
                      const SizedBox(height: 15),
                      Container(
                        child: Row(children: [
                          Flexible(
                              child: TextFormField(
                            controller: _addChatHighlightTextController,
                            style: const TextStyle(fontSize: 14),
                            maxLength: 30,
                            decoration: InputDecoration(hintText: "Enter a word to highlight"),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (s) {
                              if (s is! String || s.trim().isEmpty) return 'Please enter a valid word';
                              if (_wordList.contains(s.trim().toLowerCase())) return 'Word already added';
                              return null;
                            },
                            textInputAction: TextInputAction.unspecified,
                            onChanged: (s) => setState(() => _enableButton = _formKey.currentState!.validate()),
                            onFieldSubmitted: (s) {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                _wordList.add(s.toLowerCase());
                                _addChatHighlightTextController.text = "";
                                _settingsProvider.changeHighlightWordList = _wordList;
                              });
                              }
                            },
                          )),
                          IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: _enableButton
                                  ? () {
                                      if (!_formKey.currentState!.validate()) return;
                                      setState(() {
                                        _wordList.add(_addChatHighlightTextController.text.toLowerCase());
                                        _addChatHighlightTextController.text = "";
                                        _settingsProvider.changeHighlightWordList = _wordList;
                                      });
                                    }
                                  : null)
                        ]),
                        margin: EdgeInsets.only(right: 10),
                      ),
                      SingleChildScrollView(
                        child: Column(
                            children: _wordList
                                .map((s) => Container(
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(s), flex: 1),
                                        IconButton(
                                            onPressed: () => setState(() {
                                                  _wordList.remove(s);
                                                  _settingsProvider.changeHighlightWordList = _wordList;
                                                }),
                                            icon: const Icon(Icons.delete, color: Colors.red))
                                      ],
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    margin: EdgeInsets.symmetric(vertical: 5)))
                                .toList()),
                      )
                    ],
                  )))),
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

  Widget wordCards() {
    return ListView(
      shrinkWrap: true,
      children: _wordList
          .map<Widget>((s) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s),
                IconButton(
                    onPressed: () => setState(() {
                          _wordList.remove(s);
                          _settingsProvider.changeHighlightWordList = _wordList;
                        }),
                    icon: const Icon(Icons.delete))
              ]))
          .toList(),
    );
  }
}
