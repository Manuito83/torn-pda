// Package imports:
import 'package:bot_toast/bot_toast.dart';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class WorkStatsTargetsDialog extends StatefulWidget {
  final FirebaseUserModel? userModel;

  const WorkStatsTargetsDialog({required this.userModel});

  @override
  WorkStatsTargetsDialogState createState() => WorkStatsTargetsDialogState();
}

class WorkStatsTargetsDialogState extends State<WorkStatsTargetsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _manualLaborController;
  late TextEditingController _intelligenceController;
  late TextEditingController _enduranceController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _manualLaborController = TextEditingController(text: _initialText(widget.userModel?.workStatsManualLaborTarget));
    _intelligenceController = TextEditingController(text: _initialText(widget.userModel?.workStatsIntelligenceTarget));
    _enduranceController = TextEditingController(text: _initialText(widget.userModel?.workStatsEnduranceTarget));
  }

  @override
  void dispose() {
    _manualLaborController.dispose();
    _intelligenceController.dispose();
    _enduranceController.dispose();
    super.dispose();
  }

  String _initialText(int? target) {
    if (target == null || target <= 0) return "";
    return target.toString();
  }

  int _parse(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Work stats targets"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "You'll get a single notification for each target as soon as you reach it, and the target will "
                "then be cleared. Leave a field empty to disable that particular target",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 15),
              _targetField("Manual labor", _manualLaborController),
              const SizedBox(height: 10),
              _targetField("Intelligence", _intelligenceController),
              const SizedBox(height: 10),
              _targetField("Endurance", _enduranceController),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text("Cancel")),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(onPressed: _saving ? null : _save, child: const Text("Save")),
        ),
      ],
    );
  }

  Widget _targetField(String label, TextEditingController controller) {
    return TextFormField(
      style: const TextStyle(fontSize: 14),
      controller: controller,
      maxLength: 9,
      keyboardType: const TextInputType.numberWithOptions(),
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(isDense: true, counterText: "", border: const OutlineInputBorder(), labelText: label),
      validator: (value) {
        final text = value?.trim() ?? "";
        if (text.isEmpty) return null;
        final parsed = int.tryParse(text);
        if (parsed == null) return "Invalid value!";
        if (parsed < 0) return "Invalid value!";
        return null;
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final manualLabor = _parse(_manualLaborController);
    final intelligence = _parse(_intelligenceController);
    final endurance = _parse(_enduranceController);

    setState(() => _saving = true);

    try {
      await FirestoreHelper().setWorkStatsTargets(
        manualLabor: manualLabor,
        intelligence: intelligence,
        endurance: endurance,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      BotToast.showText(
        clickClose: true,
        text: "Could not save your targets, please try again!",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[900]!,
        duration: const Duration(seconds: 4),
        contentPadding: const EdgeInsets.all(10),
      );
      return;
    }

    widget.userModel?.workStatsManualLaborTarget = manualLabor;
    widget.userModel?.workStatsIntelligenceTarget = intelligence;
    widget.userModel?.workStatsEnduranceTarget = endurance;

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
