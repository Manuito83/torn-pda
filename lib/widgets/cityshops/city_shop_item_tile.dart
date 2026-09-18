import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/cityshops/city_shop_item_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';

class CityShopModeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const CityShopModeBadge({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}

class CityShopItemTile extends StatelessWidget {
  final CityShopItemModel item;
  final bool subscribed;
  final ValueChanged<CityShopItemModel> onToggleAlert;

  const CityShopItemTile({required this.item, required this.subscribed, required this.onToggleAlert, super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final modeColor = item.gone ? Colors.grey : item.mode.color;
    final modeLabel = item.gone ? "No longer sold" : item.mode.label;
    final windowText = _windowText(settingsProvider);

    return Opacity(
      opacity: item.gone ? 0.5 : 1.0,
      child: ListTile(
        onTap: () => _showDetail(context, themeProvider, settingsProvider),
        title: Text(item.item ?? "Unknown item"),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CityShopModeBadge(label: modeLabel, color: modeColor),
                  const SizedBox(width: 6),
                  Text("Stock: ${item.stock}", style: const TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.statusLabel, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              if (windowText != null) Text(windowText, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            subscribed ? Icons.notifications_active : Icons.notifications_none,
            color: subscribed ? Colors.blue : null,
          ),
          onPressed: () => onToggleAlert(item),
        ),
      ),
    );
  }

  String? _windowText(SettingsProvider settingsProvider) {
    final window = item.window;
    if (window == null || item.mode != CityShopMode.headsUp) return null;
    final start = TimeFormatter(
      inputTime: DateTime.fromMillisecondsSinceEpoch(window.start),
      timeFormatSetting: settingsProvider.currentTimeFormat,
      timeZoneSetting: settingsProvider.currentTimeZone,
    ).formatHour;
    final end = TimeFormatter(
      inputTime: DateTime.fromMillisecondsSinceEpoch(window.end),
      timeFormatSetting: settingsProvider.currentTimeFormat,
      timeZoneSetting: settingsProvider.currentTimeZone,
    ).formatHour;
    final overdue = DateTime.now().millisecondsSinceEpoch > window.end;
    return overdue ? "Restock overdue (expected $start to $end)" : "Restock expected $start to $end";
  }

  void _showDetail(BuildContext context, ThemeProvider themeProvider, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeProvider.canvas,
      builder: (context) {
        final updatedText = TimeFormatter(
          inputTime: DateTime.fromMillisecondsSinceEpoch(item.updated),
          timeFormatSetting: settingsProvider.currentTimeFormat,
          timeZoneSetting: settingsProvider.currentTimeZone,
        ).formatHourWithDaysElapsed(includeToday: true);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item ?? "Unknown item",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeProvider.mainText),
                ),
                Text(item.shop ?? "", style: TextStyle(fontSize: 12, color: themeProvider.mainText.withAlpha(180))),
                const SizedBox(height: 16),
                if (item.reliability == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      item.reason == CityShopReason.neverStocked
                          ? "Never seen in stock."
                          : "Not enough restocks seen yet. Check back in a few days.",
                      style: TextStyle(fontSize: 13, color: themeProvider.mainText),
                    ),
                  ),
                if (item.reliability != null)
                  _detailRow(
                    themeProvider,
                    "Reliability",
                    "${item.reliability}%",
                    "Estimated chance the restock lands inside the expected window",
                  ),
                if (item.baseMin != null)
                  _detailRow(
                    themeProvider,
                    "Restocks about every",
                    "${item.baseMin!.round()} min",
                    "Usual time the shop takes to refill this item",
                  ),
                if (item.stockMedianMin != null)
                  _detailRow(
                    themeProvider,
                    "Stock usually lasts",
                    "${item.stockMedianMin!.round()} min",
                    "Median time the item stays in stock once restocked",
                  ),
                if (item.stockP10Min != null)
                  _detailRow(
                    themeProvider,
                    "Stock lasts at least",
                    "${item.stockP10Min!.round()} min",
                    "In 9 out of 10 restocks, stock lasted at least this long",
                  ),
                if (item.fastSellFraction != null)
                  _detailRow(
                    themeProvider,
                    "Sells out fast",
                    "${(item.fastSellFraction! * 100).round()}%",
                    "Share of restocks that sold out within a few minutes",
                  ),
                if (item.cycles > 0)
                  _detailRow(
                    themeProvider,
                    "Restocks measured",
                    "${item.cycles}",
                    "Restocks this prediction is built on",
                  ),
                _detailRow(themeProvider, "Last change", updatedText, "Last time the stock or the prediction changed"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeProvider themeProvider, String label, String value, String explanation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: themeProvider.mainText),
              ),
              Text(value, style: TextStyle(fontSize: 13, color: themeProvider.mainText)),
            ],
          ),
          Text(
            explanation,
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: themeProvider.mainText.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}
