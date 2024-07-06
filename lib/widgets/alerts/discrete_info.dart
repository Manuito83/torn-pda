// Flutter imports:
import 'package:flutter/material.dart';

class DiscreteInfo extends StatefulWidget {
  @override
  DiscreteInfoState createState() => DiscreteInfoState();
}

class DiscreteInfoState extends State<DiscreteInfo> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Discrete notifications"),
      content: const Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Discrete notifications are designed for environments (work, school...) where the standard "
                      "notification text (i.e.: referencing loot, drugs, etc.) would not be appropriate."
                      "\n\nInstead, you will receive a much shorter text, as explained below."
                      "\n\nBe aware that you might lose some key information in the notification "
                      "(e.g.: event or message details). Applies both for manual notifications and automatic alerts.",
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Examples notification titles and bodies if discrete notifications are enabled:",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          "Travel",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: T",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Flight departure",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Scheduled",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Departure",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Energy",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: E",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Nerve",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: N",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Life",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Lf",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Hospital admission",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Adm",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Hospital release (approaching)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: App",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Hospital release (out)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Out",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Drug cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: D",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Booster cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: B",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Medical cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Med",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Race start",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: R",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Start",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Race ending",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: R",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: End",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Message",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: M",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Manuito",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Event",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Event",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Trade",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Trade",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Foreign stock",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Stock",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Refills",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Refills",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Retaliation",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Retal",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Loot",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: L",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Body: Duke - 4",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Loot Rangers",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: LR",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Assist",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Assist",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Level 20 - 200 days old",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Stock market",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: Shares",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "Ranked War",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: W",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "App",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        Text(
                          "War target notification",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Title: WT",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Quiet!"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
