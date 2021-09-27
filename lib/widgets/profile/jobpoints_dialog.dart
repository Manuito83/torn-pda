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
  final int currentType;
  final int currentPoints;
  final Jobpoints jobpoints;
  final Job job;
  final bool unemployed;

  JobPointsDialog({
    @required this.currentType,
    @required this.currentPoints,
    @required this.jobpoints,
    @required this.job,
    @required this.unemployed,
  });

  @override
  _JobPointsDialogState createState() => _JobPointsDialogState();
}

class _JobPointsDialogState extends State<JobPointsDialog> {
  ThemeProvider _themeProvider;

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
                padding: EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: EdgeInsets.only(top: 15),
                decoration: new BoxDecoration(
                  color: _themeProvider.background,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'JOB POINTS',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 10),
                      _currentPoints(),
                      Divider(),
                      _jopPoints(),
                      _companyPoints(),
                      Divider(),
                      TextButton(
                        child: Text(
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
                backgroundColor: _themeProvider.background,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.background,
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
      return Text(
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
              widget.job.companyName == 'None' ? widget.job.position : HtmlParser.fix(widget.job.companyName),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              '${widget.currentPoints} points',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _jopPoints() {
    if (widget.jobpoints.jobs == null) {
      return Text(
        'No starter-job points found!',
        style: TextStyle(
          fontSize: 12,
        ),
      );
    }
    
    return Column(
      children: [
        Text(
          'Army: ${widget.jobpoints.jobs.army}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Casino: ${widget.jobpoints.jobs.casino}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Education: ${widget.jobpoints.jobs.education}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Grocer: ${widget.jobpoints.jobs.grocer}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Law: ${widget.jobpoints.jobs.law}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        Text(
          'Medical: ${widget.jobpoints.jobs.medical}',
          style: TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _companyPoints() {
    var jobs = <Widget>[];

    if (widget.jobpoints.companies != null) {
      jobs.add(Divider());
      widget.jobpoints.companies.forEach((type, details) {
        jobs.add(
          Text(
            '${details.name}: ${details.jobpoints}',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        );
      });
    }

    return Column(children: jobs);
  }
}
