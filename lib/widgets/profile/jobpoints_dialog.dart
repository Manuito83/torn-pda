// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/profile/own_profile_misc.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class JobPointsDialog extends StatefulWidget {
  final int? currentType;
  final int? currentPoints;
  final Jobpoints? jobpoints;
  final Job? job;
  final bool unemployed;

  const JobPointsDialog({
    required this.currentType,
    required this.currentPoints,
    required this.jobpoints,
    required this.job,
    required this.unemployed,
  });

  @override
  JobPointsDialogState createState() => JobPointsDialogState();
}

class JobPointsDialogState extends State<JobPointsDialog> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = context.read<ThemeProvider>();
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
                  color: _themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'JOB POINTS',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _currentPoints(),
                      const Divider(),
                      _jopPoints(),
                      _companyPoints(),
                      const Divider(),
                      TextButton(
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(
                      Icons.work,
                      color: Colors.brown[300],
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

  Widget _currentPoints() {
    if (widget.unemployed) {
      return const Text(
        'You are unemployed!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              widget.job!.companyName == 'None' ? widget.job!.job! : HtmlParser.fix(widget.job!.companyName),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              '${widget.currentPoints} points',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _jopPoints() {
    if (widget.jobpoints!.jobs == null) {
      return const Text(
        'No starter-job points found!',
        style: TextStyle(
          fontSize: 12,
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Army: ${widget.jobpoints!.jobs!.army}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Casino: ${widget.jobpoints!.jobs!.casino}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Education: ${widget.jobpoints!.jobs!.education}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Grocer: ${widget.jobpoints!.jobs!.grocer}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Law: ${widget.jobpoints!.jobs!.law}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Medical: ${widget.jobpoints!.jobs!.medical}',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _companyPoints() {
    final jobs = <Widget>[];

    if (widget.jobpoints!.companies != null) {
      jobs.add(const Divider());
      widget.jobpoints!.companies!.forEach((type, details) {
        jobs.add(
          Text(
            '${details.name}: ${details.jobpoints}',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        );
      });
    }

    return Column(children: jobs);
  }
}
