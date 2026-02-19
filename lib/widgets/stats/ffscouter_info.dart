import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog_simple.dart';

class FFScouterInfoPage extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final ThemeProvider themeProvider;

  /// If true, the page opens with the KEY SETUP section expanded.
  final bool jumpToKeySetup;

  const FFScouterInfoPage({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
    this.jumpToKeySetup = false,
  });

  @override
  State<FFScouterInfoPage> createState() => _FFScouterInfoPageState();
}

class _FFScouterInfoPageState extends State<FFScouterInfoPage> {
  final _scrollController = ScrollController();
  final _keyController = TextEditingController();
  final UserController _u = Get.find<UserController>();

  // Whether the KEY SETUP section is expanded
  late bool _keySetupExpanded;

  // Key setup state
  bool _isCheckingKey = false;
  bool _isRegistering = false;
  bool _keyChecked = false;
  bool _keyIsRegistered = false;
  bool _keyRegisteredJustNow = false;
  bool _keySavedAsAlternative = false;
  bool _agreedToPolicy = false;
  String? _checkError;
  String? _registerError;
  String? _registerSuccess;

  /// Whether the current alt key is the same as the main Torn PDA API key.
  bool get _altKeyIsSameAsMainKey {
    return _u.alternativeFFScouterKeyEnabled &&
        _u.alternativeFFScouterKey.isNotEmpty &&
        _u.alternativeFFScouterKey == _u.apiKey;
  }

  /// Whether a valid dedicated alt key is already configured.
  bool get _hasDedicatedAltKey {
    return _u.alternativeFFScouterKeyEnabled &&
        _u.alternativeFFScouterKey.isNotEmpty &&
        _u.alternativeFFScouterKey != _u.apiKey;
  }

  /// Whether the pasted key is the same as the main Torn PDA API key.
  bool get _isSameAsMainKey {
    final pasted = _keyController.text.trim();
    return pasted.isNotEmpty && pasted == _u.apiKey;
  }

  /// Whether the pasted key looks valid (16 alphanumeric chars).
  bool get _keyLooksValid {
    final pasted = _keyController.text.trim();
    return RegExp(r'^[a-zA-Z0-9]{16}$').hasMatch(pasted);
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with the current alternative key if one is set
    if (_u.alternativeFFScouterKeyEnabled && _u.alternativeFFScouterKey.isNotEmpty) {
      _keyController.text = _u.alternativeFFScouterKey;
    }

    // Collapse key setup if a dedicated alt key is already configured (and not the same as main key).
    // Expand if jumpToKeySetup is requested or if alt key == main key (needs fixing).
    _keySetupExpanded = widget.jumpToKeySetup || _altKeyIsSameAsMainKey || !_hasDedicatedAltKey;

    if (widget.jumpToKeySetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.themeProvider.mainText;
    final mutedColor = Colors.grey[500]!;
    final linkColor = Colors.blue[400]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FFScouter"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ABOUT ---
                    _sectionHeader("ABOUT"),
                    const SizedBox(height: 6),
                    Text(
                      "FFScouter is a free tool designed to help estimate the difficulty and battle stats "
                      "of your opponents. Using this tool will not expose any information about yourself to "
                      "other players, nor will you be able to view information about others except battle stat "
                      "estimates. Your actual battle stats, and those of others, will remain private.",
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Any stat estimates made via the free API are available for any person or group to access "
                      "and use, free of charge, for any purpose.",
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "FFScouter is not affiliated with Torn, it is an independent community tool.",
                      style: TextStyle(fontSize: 13, color: mutedColor, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),

                    // --- KEY SETUP ---
                    _sectionHeader("KEY SETUP"),
                    const SizedBox(height: 6),
                    _buildKeySetupSection(textColor, mutedColor, linkColor),
                    const SizedBox(height: 16),

                    // --- TERMS AND CONDITIONS ---
                    _sectionHeader("TERMS AND CONDITIONS"),
                    const SizedBox(height: 6),
                    Text(
                      "By using FFScouter you agree to the following:",
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    _bulletPoint(
                      "FFScouter will make API requests to Torn using your API key to obtain information "
                      "about you and your attacks. These requests may be made up to 13 times per day.",
                      textColor,
                    ),
                    _bulletPoint(
                      "Your data will be used to make predictions about the battle stats of people who "
                      "you attack, or who have attacked you. These estimates will then become public.",
                      textColor,
                    ),
                    _bulletPoint(
                      "The battle stat predictions of other people will be provided to other users of "
                      "FFScouter (the general public). These estimates, once made, belong to FFScouter.",
                      textColor,
                    ),
                    _bulletPoint(
                      "By using FFScouter, you are contributing to a shared pool of stat estimates. "
                      "Using it will not update your own public stat estimates and your own raw battle "
                      "stats will never be provided to anyone else.",
                      textColor,
                    ),
                    _bulletPoint(
                      "Data may also be used to train a machine learning model to improve accuracy. "
                      "This model may only be accessible to fee paying users of FFScouter.",
                      textColor,
                    ),
                    _bulletPoint(
                      "You can remove your API key at any time by deleting or pausing it in the Torn "
                      "API Settings page. Your private information will be deleted at the next update attempt.",
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // --- DATA POLICY ---
                    _sectionHeader("DATA POLICY"),
                    const SizedBox(height: 6),
                    _dataRow("Player ID", "Stored forever, visible to general public", textColor),
                    _dataRow("Battle Stats", "Stored until account deletion, owners only", textColor),
                    _dataRow("BSS Private", "Stored until account deletion, owners only", textColor),
                    _dataRow("BSS Public", "Stored forever, visible to general public", textColor),
                    _dataRow("Attacks", "Temporary (<10 sec), never stored to database", textColor),
                    _dataRow("API Key", "Stored until deletion, owners only (debugging)", textColor),
                    _dataRow("Personal Stats", "Stored until deletion, AI training only", textColor),
                    const SizedBox(height: 8),
                    Text(
                      "Your attack history is never saved to the database, shared, or sold. "
                      "Your own bss_public is not updated by registering; it is generated by other users' estimates.",
                      style: TextStyle(fontSize: 12, color: mutedColor, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),

                    // --- API KEY ---
                    _sectionHeader("API KEY REQUIREMENTS"),
                    const SizedBox(height: 6),
                    Text(
                      "Recommended: Custom key with selections: basic, battlestats, attacks, hof, personalstats.",
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Limited and Full keys also work, but Custom is recommended.",
                      style: TextStyle(fontSize: 12, color: mutedColor, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),

                    // --- TORN PDA INTEGRATION ---
                    _sectionHeader("TORN PDA INTEGRATION"),
                    const SizedBox(height: 6),
                    Text(
                      "Prefer FFScouter battle score",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "When enabled, war/retal cards and profile checks will show the FFScouter battle score "
                      "estimate (e.g. ~12.5M) in orange instead of the vague estimated range (e.g. 2M-25M) for "
                      "unspied targets. The same value is used for sorting, filters (Total Stats slider), and SmartScore. "
                      "Disabling this setting clears the local cache.",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Override old spies",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "When the 'Prefer FFScouter' option is active, a slider lets you choose a spy age threshold "
                      "(1–12 months). If a target's spied stats are older than that threshold and FFScouter has a "
                      "battle score estimate, the FFS value will replace the spied stats on the card. "
                      "A small clock icon indicates the override. Sorting, filters, and SmartScore also use the "
                      "FFS value in that case. Set to 'Off' to always keep spied stats regardless of age.",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 16),

                    // --- DEVELOPER ---
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      "FFScouter is developed by Glasnost [1844049].",
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Visit ffscouter.com for full details",
                          style: TextStyle(
                            fontSize: 14,
                            color: linkColor,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await openSimpleWebViewDialog(
                                context: context,
                                url: 'https://ffscouter.com',
                                title: 'FFScouter',
                              );
                            },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom button bar
          if (widget.settingsProvider.ffScouterEnabledStatus != 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.themeProvider.secondBackground,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.settingsProvider.ffScouterEnabledStatus = 1;
                  Navigator.of(context).pop();
                },
                child: const Text("Accept & Enable FFScouter"),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KEY SETUP SECTION — collapsible wizard
  // ---------------------------------------------------------------------------

  Widget _buildKeySetupSection(Color textColor, Color mutedColor, Color linkColor) {
    // Show a status banner + collapsible details
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: widget.themeProvider.currentTheme == AppTheme.light ? Colors.grey[50] : Colors.grey[900],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner (always visible, tappable to expand/collapse)
          _buildKeyStatusBanner(textColor),

          // Expandable wizard steps
          if (_keySetupExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),

                  // Step 1: Create a dedicated key
                  _stepHeader("1", "Create a dedicated API key", textColor),
                  const SizedBox(height: 6),
                  Text(
                    "We strongly recommend creating a dedicated API key for FFScouter "
                    "instead of using your main Torn PDA key.",
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        const url = 'https://www.torn.com/preferences.php#tab=api?step=addNewKey'
                            '&title=FFScouterv3.2'
                            '&user=hof,faction,basic,profile,cooldowns,refills,attacks,battlestats,personalstats'
                            '&faction=members,rankedwarreport,warfare,wars,rankedwars'
                            '&torn=rankedwarreport,rankedwars';
                        await openSimpleWebViewDialog(
                          context: context,
                          url: url,
                          title: 'Create API Key',
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text("Create FFScouter Key on Torn", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Once created, copy the new key and paste it below:",
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 8),

                  // Key input field
                  TextField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      hintText: "Paste your FFScouter API key here",
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      suffixIcon: _keyController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _keyController.clear();
                                  _resetKeyState();
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    maxLength: 16,
                    onChanged: (_) {
                      setState(() {
                        _resetKeyState();
                      });
                    },
                  ),

                  // Warning: same key as main Torn PDA key
                  if (_keyController.text.trim().isNotEmpty && _isSameAsMainKey)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "This is the same API key used by Torn PDA. We recommend creating a "
                              "separate key for FFScouter to keep your main key private. "
                              "You can still proceed, but consider using a dedicated key.",
                              style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Check: dedicated key detected
                  if (_keyController.text.trim().isNotEmpty && _keyLooksValid && !_isSameAsMainKey && !_keyChecked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Great! You're using a dedicated key.",
                              style: TextStyle(fontSize: 11, color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Step 2: Check & Register
                  _stepHeader("2", "Check & register your key", textColor),
                  const SizedBox(height: 6),

                  if (!_keyLooksValid && _keyController.text.trim().isNotEmpty)
                    Text(
                      "Key must be exactly 16 alphanumeric characters.",
                      style: TextStyle(fontSize: 11, color: Colors.red[400]),
                    ),

                  if (_keyLooksValid && !_keyChecked) ...[
                    Text(
                      "Check if your key is already registered with FFScouter, "
                      "or register it now.",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: _isCheckingKey
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton.icon(
                              onPressed: _checkKey,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text("Check if key is registered", style: TextStyle(fontSize: 12)),
                            ),
                    ),
                    if (_checkError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_checkError!, style: TextStyle(fontSize: 11, color: Colors.red[400])),
                      ),
                  ],

                  // Key is already registered
                  if (_keyChecked && _keyIsRegistered) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _keyRegisteredJustNow
                                  ? "Key registered successfully with FFScouter!"
                                  : "This key is already registered with FFScouter. You're all set!",
                              style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Key checked but NOT registered — show registration form
                  if (_keyChecked && !_keyIsRegistered) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        "This key is not yet registered with FFScouter.",
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Policy agreement checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToPolicy,
                            onChanged: (v) => setState(() => _agreedToPolicy = v ?? false),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _agreedToPolicy = !_agreedToPolicy),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 11, color: textColor),
                                children: [
                                  const TextSpan(text: "I have read and agree to the "),
                                  TextSpan(
                                    text: "FFScouter Data Policy and Terms",
                                    style: TextStyle(
                                      color: linkColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        await openSimpleWebViewDialog(
                                          context: context,
                                          url: 'https://ffscouter.com',
                                          title: 'FFScouter Policy',
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: _isRegistering
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton.icon(
                              onPressed: _agreedToPolicy ? _registerKey : null,
                              icon: const Icon(Icons.app_registration, size: 16),
                              label: const Text("Register Key with FFScouter", style: TextStyle(fontSize: 12)),
                            ),
                    ),

                    if (_registerError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_registerError!, style: TextStyle(fontSize: 11, color: Colors.red[400])),
                      ),
                    if (_registerSuccess != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_registerSuccess!, style: TextStyle(fontSize: 11, color: Colors.green[600])),
                      ),
                  ],

                  // Step 3: Save as alternative key
                  if (_keyLooksValid && (_keyChecked && _keyIsRegistered)) ...[
                    const SizedBox(height: 12),
                    _stepHeader("3", "Save key in Torn PDA", textColor),
                    const SizedBox(height: 6),
                    if (!_isSameAsMainKey && !_keySavedAsAlternative) ...[
                      Text(
                        "Save this key as your FFScouter alternative key so Torn PDA uses it "
                        "instead of your main API key.",
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveAsAlternativeKey,
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text("Save as FFScouter Alternative Key", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    if (!_isSameAsMainKey && _keySavedAsAlternative)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Saved! FFScouter will use this dedicated key instead of your main Torn PDA key.",
                                style: TextStyle(fontSize: 12, color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isSameAsMainKey)
                      Text(
                        "You're using your main Torn PDA key. You can configure an alternative key "
                        "later in Settings > Alternative API Keys.",
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Tappable banner showing key status. Tap to expand/collapse the wizard.
  Widget _buildKeyStatusBanner(Color textColor) {
    Widget banner;

    if (_altKeyIsSameAsMainKey) {
      // RED: alt key is the same as main key
      banner = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Your FFScouter key is the same as your main Torn PDA key. "
              "We recommend creating a separate dedicated key for privacy.",
              style: TextStyle(fontSize: 12, color: Colors.red[700]),
            ),
          ),
          Icon(
            _keySetupExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.red[700],
            size: 22,
          ),
        ],
      );
    } else if (_hasDedicatedAltKey) {
      // GREEN: dedicated alt key configured
      banner = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You have a dedicated FFScouter key configured. "
              "Expand to verify registration or change your key.",
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
            ),
          ),
          Icon(
            _keySetupExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.green[700],
            size: 22,
          ),
        ],
      );
    } else {
      // NEUTRAL: no alt key yet
      banner = Row(
        children: [
          Icon(Icons.vpn_key_outlined, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Set up your FFScouter API key to get started.",
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
          Icon(
            _keySetupExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey[600],
            size: 22,
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => setState(() => _keySetupExpanded = !_keySetupExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: banner,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _resetKeyState() {
    _keyChecked = false;
    _keyIsRegistered = false;
    _keyRegisteredJustNow = false;
    _keySavedAsAlternative = false;
    _agreedToPolicy = false;
    _checkError = null;
    _registerError = null;
    _registerSuccess = null;
  }

  Future<void> _checkKey() async {
    setState(() {
      _isCheckingKey = true;
      _checkError = null;
    });

    final result = await FFScouterComm.checkKey(key: _keyController.text.trim());

    if (!mounted) return;
    setState(() {
      _isCheckingKey = false;
      if (result.success && result.data != null) {
        _keyChecked = true;
        _keyIsRegistered = result.data!.isRegistered;
      } else {
        _checkError = result.errorMessage ?? "Could not check key status";
      }
    });
  }

  Future<void> _registerKey() async {
    setState(() {
      _isRegistering = true;
      _registerError = null;
      _registerSuccess = null;
    });

    final result = await FFScouterComm.registerKey(key: _keyController.text.trim());

    if (!mounted) return;
    setState(() {
      _isRegistering = false;
      if (result.success) {
        _keyIsRegistered = true;
        _keyRegisteredJustNow = true;
        _registerSuccess = result.data?.message ?? "Key registered successfully!";
      } else {
        if (result.errorCode == 8) {
          // Already registered
          _keyIsRegistered = true;
          _registerSuccess = "Key was already registered.";
        } else if (result.errorCode == 7) {
          _registerError = "Too many attempts. Please wait and try again.";
        } else if (result.errorCode == 6) {
          _registerError = "Key is invalid. Please check and try again.";
        } else {
          _registerError = result.errorMessage ?? "Registration failed";
        }
      }
    });
  }

  void _saveAsAlternativeKey() {
    final key = _keyController.text.trim();
    _u.alternativeFFScouterKeyEnabled = true;
    _u.alternativeFFScouterKey = key;
    Prefs().setAlternativeFFScouterKeyEnabled(true);
    Prefs().setAlternativeFFScouterKey(key);
    _u.update();
    setState(() {
      _keySavedAsAlternative = true;
    });
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _stepHeader(String number, String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _bulletPoint(String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String category, String details, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              category,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Expanded(
            child: Text(
              details,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
