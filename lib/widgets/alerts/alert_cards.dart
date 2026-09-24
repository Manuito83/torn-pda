import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

enum AlertChipKind { neutral, warning, critical }

class AlertGroupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? on;
  final int? total;
  final List<Widget> children;
  final ThemeProvider theme;

  const AlertGroupCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    required this.theme,
    this.on,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final bool light = theme.currentTheme == AppTheme.light;
    final line = theme.mainText.withValues(alpha: light ? 0.10 : 0.09);
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: line));
      rows.add(children[i]);
    }

    final Color surface = theme.currentTheme == AppTheme.extraDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.06), theme.cardColor)
        : theme.cardColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.mainText.withValues(alpha: light ? 0.12 : 0.14)),
        boxShadow: light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.blueGrey[300]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: theme.mainText.withValues(alpha: 0.7)),
                  ),
                ),
                if (on != null && total != null)
                  Text(
                    "$on / $total",
                    style: TextStyle(
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.mainText.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: line),
          ...rows,
        ],
      ),
    );
  }
}

class AlertRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? extra;
  final bool sub;
  final Color? titleColor;
  final bool boldTitle;
  final Color? subtitleColor;

  const AlertRow({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.value,
    this.onChanged,
    this.trailing,
    this.onTap,
    this.extra,
    this.sub = false,
    this.titleColor,
    this.boldTitle = false,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final muted = DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.78);
    final Widget? control =
        trailing ??
        (value != null
            ? Switch(
                value: value!,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green[600],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null);
    final VoidCallback? tap = onTap ?? (value != null && onChanged != null ? () => onChanged!(!value!) : null);

    return InkWell(
      onTap: tap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(sub ? 24 : 14, 9, 10, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (sub)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(color: Colors.blueGrey[300], shape: BoxShape.circle),
                        ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: sub ? 13.5 : 14.5,
                          color: titleColor,
                          fontWeight: boldTitle ? FontWeight.bold : null,
                        ),
                      ),
                      if (titleTrailing != null) titleTrailing!,
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2, left: sub ? 14 : 0),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 11.5, height: 1.3, color: subtitleColor ?? muted),
                      ),
                    ),
                  if (extra != null)
                    Padding(
                      padding: EdgeInsets.only(top: 6, left: sub ? 14 : 0),
                      child: extra!,
                    ),
                ],
              ),
            ),
            if (control != null) ...[const SizedBox(width: 8), control],
          ],
        ),
      ),
    );
  }
}

class AlertSubRows extends StatelessWidget {
  final List<Widget> children;
  final ThemeProvider theme;

  const AlertSubRows({super.key, required this.children, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bool light = theme.currentTheme == AppTheme.light;
    final line = theme.mainText.withValues(alpha: 0.08);
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: line, indent: 24));
      rows.add(children[i]);
    }

    return Container(
      color: light ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class AlertChip extends StatelessWidget {
  final String label;
  final AlertChipKind kind;

  const AlertChip(this.label, {super.key, this.kind = AlertChipKind.neutral});

  @override
  Widget build(BuildContext context) {
    final bool light = (DefaultTextStyle.of(context).style.color?.computeLuminance() ?? 1) < 0.5;
    final Color tone = switch (kind) {
      AlertChipKind.critical => light ? Colors.red[800]! : Colors.red[400]!,
      AlertChipKind.warning => light ? Colors.deepOrange[900]! : Colors.amber[600]!,
      AlertChipKind.neutral => light ? Colors.blueGrey[800]! : Colors.blueGrey[300]!,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: light ? 0.10 : 0.16),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: tone, fontWeight: kind == AlertChipKind.neutral ? null : FontWeight.w600),
      ),
    );
  }
}
