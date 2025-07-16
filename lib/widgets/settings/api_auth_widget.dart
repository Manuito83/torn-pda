import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ApiKeySectionWidget extends StatefulWidget {
  final bool apiIsLoading;
  final OwnProfileBasic? userProfile;
  final bool apiError;
  final String errorReason;
  final String errorDetails;

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormState> apiFormKey;
  final TextEditingController apiKeyInputController;
  final ExpandableController expandableController;

  final Future<void> Function({required bool userTriggered, required String currentKey}) getApiDetails;
  final Function changeUID;
  final void Function() setStateOnParent;
  final void Function() removeUserProvider;

  final void Function(bool) changeApiError;
  final void Function(dynamic) changeUserProfile;

  const ApiKeySectionWidget({
    super.key,
    required this.apiIsLoading,
    required this.userProfile,
    required this.apiError,
    required this.errorReason,
    required this.errorDetails,
    required this.formKey,
    required this.apiFormKey,
    required this.apiKeyInputController,
    required this.expandableController,
    required this.getApiDetails,
    required this.changeUID,
    required this.setStateOnParent,
    required this.removeUserProvider,
    required this.changeApiError,
    required this.changeUserProfile,
  });

  @override
  State<ApiKeySectionWidget> createState() => _ApiKeySectionWidgetState();
}

class _ApiKeySectionWidgetState extends State<ApiKeySectionWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.apiIsLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      );
    }

    if (widget.userProfile != null) {
      return Padding(
        key: widget.apiFormKey,
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Card(
          child: ExpandablePanel(
            controller: widget.expandableController,
            collapsed: Container(),
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Text(
                        "TORN API USER LOADED",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "${widget.userProfile!.name} [${widget.userProfile!.playerId}]",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: false),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: const Text(
                                  "Copy",
                                  style: TextStyle(fontSize: 13),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.userProfile!.userApiKey.toString()),
                                  );
                                  BotToast.showText(
                                    text: "API key copied to the clipboard, be careful!",
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.blue,
                                    duration: const Duration(seconds: 4),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: const Text(
                                    "Reload",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  onPressed: widget.apiKeyInputController.text.trim().isEmpty
                                      ? null
                                      : () {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          if (widget.formKey.currentState!.validate()) {
                                            String myCurrentKey = widget.apiKeyInputController.text.trim();
                                            myCurrentKey = _sanitizeApiKey(myCurrentKey);
                                            widget.getApiDetails(
                                              userTriggered: true,
                                              currentKey: myCurrentKey,
                                            );
                                          }
                                        },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    // Removes the form error
                                    widget.formKey.currentState!.reset();
                                    widget.apiKeyInputController.clear();
                                    widget.removeUserProvider();
                                    widget.setStateOnParent();
                                    widget.changeUserProfile(null);
                                    widget.changeApiError(false);

                                    if (!Platform.isWindows) {
                                      await FirebaseMessaging.instance.deleteToken();
                                      await FirestoreHelper().deleteUserProfile();
                                      await FirebaseAuth.instance.signOut();
                                    }
                                    widget.changeUID("");
                                  },
                                ),
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      widget.expandableController.expanded = true;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Card(
          child: ExpandablePanel(
            collapsed: Container(),
            controller: widget.expandableController,
            header: const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "NO USER LOADED",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      "(expand for details)",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: true),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: const Text("Load"),
                                onPressed: widget.apiKeyInputController.text.trim().isEmpty
                                    ? null
                                    : () {
                                        FocusScope.of(context).requestFocus(FocusNode());
                                        if (widget.formKey.currentState!.validate()) {
                                          String myCurrentKey = widget.apiKeyInputController.text.trim();
                                          myCurrentKey = _sanitizeApiKey(myCurrentKey);
                                          widget.getApiDetails(
                                            userTriggered: true,
                                            currentKey: myCurrentKey,
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  SizedBox _apiKeyForm({required bool enabled}) {
    return SizedBox(
      width: 300,
      child: Form(
        key: widget.formKey,
        child: TextFormField(
          enabled: enabled,
          validator: (value) {
            if (value!.isEmpty) {
              return "The API Key is empty!";
            }
            return null;
          },
          controller: widget.apiKeyInputController,
          maxLength: 30,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Please insert your Torn API Key',
            hintStyle: const TextStyle(fontSize: 14),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: const BorderSide(
                color: Colors.amber,
              ),
            ),
          ),
          // This is here in case the user submits from the keyboard
          // and not hitting the "Load" button
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(FocusNode());
            if (widget.formKey.currentState!.validate()) {
              String myCurrentKey = widget.apiKeyInputController.text.trim();
              myCurrentKey = _sanitizeApiKey(myCurrentKey);
              widget.getApiDetails(userTriggered: true, currentKey: myCurrentKey);
            }
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
    );
  }

  /// Builds a single row for the ToS compliance table.
  TableRow _buildTosTableRow(String title, String content) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(content),
        ),
      ],
    );
  }

  Widget _bottomExplanatory() {
    if (widget.apiError) {
      return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: 15),
              child: Text(
                "ERROR LOADING USER",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text("Error: ${widget.errorReason}"),
            if (widget.errorDetails.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  widget.errorDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (widget.userProfile == null) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 30, 10, 0),
        child: Column(
          children: <Widget>[
            // ToS Compliance Table
            Table(
              border: TableBorder.all(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: <TableRow>[
                const TableRow(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                  ),
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _buildTosTableRow('Data Storage', 'Persistent - until you remove the key from the app.'),
                _buildTosTableRow('Data Sharing',
                    'Your data is not shared. Only service owners may access data for maintenance and support purposes.'),
                _buildTosTableRow(
                    'Purpose of Use', 'To provide application features and display your personal Torn data within the app.'),
                _buildTosTableRow('Key Storage & Sharing',
                    'Stored remotely and securely. Used only for automated requests to the Torn API on your behalf.'),
                _buildTosTableRow('Key Access Level', 'Limited Access.'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.info_outline, color: Colors.blue),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You can get your API key on the Torn website under Settings > API Keys. Torn PDA only needs a Limited Access key.",
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: const Text(
                                  'Tap here',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: ' to be redirected to the API key page.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text('By providing your API key, you agree to these terms. You can remove your key from the app at any time.'),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: <Widget>[
            Text(
              "${widget.userProfile!.name} [${widget.userProfile!.playerId}]",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Gender: ${widget.userProfile!.gender}"),
            Text("Level: ${widget.userProfile!.level}"),
            Text("Life: ${widget.userProfile!.life!.current}"),
            Text("Status: ${widget.userProfile!.status!.description}"),
            Text("Last action: ${widget.userProfile!.lastAction!.relative}"),
            Text("Rank: ${widget.userProfile!.rank}"),
          ],
        ),
      );
    }
  }

  String _sanitizeApiKey(String myCurrentKey) {
    String allowedChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    myCurrentKey = myCurrentKey.replaceAll(RegExp('[^$allowedChars]+'), '');
    return myCurrentKey;
  }
}