import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
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
    required this.changeApiError,
    required this.changeUserProfile,
  });

  @override
  State<ApiKeySectionWidget> createState() => _ApiKeySectionWidgetState();
}

class _ApiKeySectionWidgetState extends State<ApiKeySectionWidget> {
  final ExpandableController _tosExpandableController = ExpandableController();

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
            theme: ExpandableThemeData(iconColor: context.read<ThemeProvider>().mainText),
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
                                    UserHelper.removeUser();
                                    widget.setStateOnParent();
                                    widget.changeUserProfile(null);
                                    widget.changeApiError(false);

                                    if (!Platform.isWindows) {
                                      try {
                                        await FirebaseMessaging.instance.deleteToken();
                                      } catch (e) {
                                        //
                                      }

                                      try {
                                        await FirestoreHelper().deleteUserProfile();
                                      } catch (e) {
                                        //
                                      }

                                      try {
                                        await FirebaseAuth.instance.signOut();
                                      } catch (e) {
                                        //
                                      }
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
        padding: const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
        child: Column(
          children: <Widget>[
            const Text(
              "Torn PDA needs your API Key to obtain your user's "
              'information. The key is protected in the app and will not '
              'be shared under any circumstances.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ToS Compliance Table
                      const SizedBox(
                        height: 10,
                      ),
                      Card(
                        shadowColor: Colors.blueGrey,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ExpandablePanel(
                            theme: ExpandableThemeData(iconColor: context.read<ThemeProvider>().mainText),
                            controller: _tosExpandableController,
                            header: const Text(
                              "See how we comply with Torn's Terms of Service",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            collapsed: const Text(
                              "Expand the section below to see how Torn PDA complies with these guidelines.",
                            ),
                            expanded: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Table(
                                    border: TableBorder.all(
                                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                                    ),
                                    columnWidths: const <int, TableColumnWidth>{
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(2),
                                    },
                                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                    children: <TableRow>[
                                      const TableRow(
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(5), topRight: Radius.circular(5)),
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
                                      _buildTosTableRow('Data Storage',
                                          'Persistent - until you remove the key from the app. This also applies to the Torn PDA server'),
                                      _buildTosTableRow('Data Sharing',
                                          'Your data is not shared. Only service owners may access data for maintenance and support purposes'),
                                      _buildTosTableRow('Purpose of Use',
                                          'To provide application features and display your Torn data within the app'),
                                      _buildTosTableRow('Key Storage & Sharing',
                                          'Stored remotely and securely. Used only for automated requests to the Torn API on your behalf'),
                                      _buildTosTableRow('Key Access Level', 'Limited Access'),
                                    ],
                                  ),
                                ),
                                const Text(
                                  "Note: if you are curious about Torn PDA's own privacy policy, you can access it in the Abour section of the app",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        "\nYou can get your API key in the Torn website by tapping your profile picture (upper right corner)"
                        " and going to Settings, API Keys. Torn PDA only needs a Limited Access key.\n",
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
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
                            TextSpan(
                              text: ' to be redirected',
                              style: DefaultTextStyle.of(context).style,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Text('\nIn any case, please make sure to '
                "follow Torn's staff recommendations on how to protect your key "
                'from any malicious use.'),
            const Text('\nYou can always remove it from the '
                'app or reset it in your Torn preferences page.'),
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
}
