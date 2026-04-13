import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

bool isFullColorShortcutIcon(String? iconUrl) {
  return shortcutIconOptions.any((o) => o.iconUrl == iconUrl && o.fullColor);
}

class ShortcutIconOption {
  final String iconUrl;
  final Color color;
  final String label;
  final bool fullColor;

  const ShortcutIconOption({
    required this.iconUrl,
    required this.color,
    required this.label,
    this.fullColor = false,
  });
}

const List<ShortcutIconOption> shortcutIconOptions = [
  ShortcutIconOption(iconUrl: 'images/icons/pda_icon.png', color: Color(0xFFFF9800), label: 'PDA'),
  ShortcutIconOption(iconUrl: 'images/icons/home/home.png', color: Color(0xFF757575), label: 'Home'),
  ShortcutIconOption(iconUrl: 'images/icons/home/messages.png', color: Color(0xFF757575), label: 'Messages'),
  ShortcutIconOption(iconUrl: 'images/icons/home/events.png', color: Color(0xFF757575), label: 'Events'),
  ShortcutIconOption(iconUrl: 'images/icons/home/awards.png', color: Color(0xFF757575), label: 'Awards'),
  ShortcutIconOption(iconUrl: 'images/icons/home/stats.png', color: Color(0xFF757575), label: 'Stats'),
  ShortcutIconOption(iconUrl: 'images/icons/home/crimes.png', color: Color(0xFF757575), label: 'Crimes'),
  ShortcutIconOption(iconUrl: 'images/icons/home/missions.png', color: Color(0xFF757575), label: 'Missions'),
  ShortcutIconOption(iconUrl: 'images/icons/home/newspaper.png', color: Color(0xFF757575), label: 'Newspaper'),
  ShortcutIconOption(iconUrl: 'images/icons/home/laptop.png', color: Color(0xFF757575), label: 'Laptop'),
  ShortcutIconOption(iconUrl: 'images/icons/home/job.png', color: Color(0xFF757575), label: 'Job'),
  ShortcutIconOption(iconUrl: 'images/icons/home/city.png', color: Color(0xFF757575), label: 'City'),
  ShortcutIconOption(iconUrl: 'images/icons/home/bounty.png', color: Color(0xFF757575), label: 'Bounty'),
  ShortcutIconOption(iconUrl: 'images/icons/home/friends.png', color: Color(0xFF757575), label: 'Friends'),
  ShortcutIconOption(iconUrl: 'images/icons/home/enemies.png', color: Color(0xFF757575), label: 'Enemies'),
  ShortcutIconOption(iconUrl: 'images/icons/home/hall_fame.png', color: Color(0xFF757575), label: 'Hall of Fame'),
  ShortcutIconOption(iconUrl: 'images/icons/home/recruit.png', color: Color(0xFF757575), label: 'Recruit'),
  ShortcutIconOption(iconUrl: 'images/icons/home/faction.png', color: Color(0xFF607D8B), label: 'Faction'),
  ShortcutIconOption(iconUrl: 'images/icons/home/forums.png', color: Color(0xFF795548), label: 'Forums'),
  ShortcutIconOption(iconUrl: 'images/icons/home/vault.png', color: Color(0xFF64B5F6), label: 'Vault'),
  ShortcutIconOption(iconUrl: 'images/icons/home/items.png', color: Color(0xFFCE93D8), label: 'Items'),
  ShortcutIconOption(iconUrl: 'images/icons/map/gym.png', color: Color(0xFF757575), label: 'Gym'),
  ShortcutIconOption(iconUrl: 'images/icons/map/property.png', color: Color(0xFF757575), label: 'Property'),
  ShortcutIconOption(iconUrl: 'images/icons/map/education.png', color: Color(0xFF757575), label: 'Education'),
  ShortcutIconOption(iconUrl: 'images/icons/map/hospital.png', color: Color(0xFF757575), label: 'Hospital'),
  ShortcutIconOption(iconUrl: 'images/icons/map/jail.png', color: Color(0xFF757575), label: 'Jail'),
  ShortcutIconOption(iconUrl: 'images/icons/map/casino.png', color: Color(0xFFA5D6A7), label: 'Casino'),
  ShortcutIconOption(iconUrl: 'images/icons/map/auction_house.png', color: Color(0xFFFDD835), label: 'Auction House'),
  ShortcutIconOption(iconUrl: 'images/icons/map/gun_shop.png', color: Color(0xFFFDD835), label: 'Gun Shop'),
  ShortcutIconOption(iconUrl: 'images/icons/map/bits_bobs.png', color: Color(0xFFFDD835), label: "Bits 'n' Bobs"),
  ShortcutIconOption(iconUrl: 'images/icons/map/cyber_force.png', color: Color(0xFFFDD835), label: 'Cyber Force'),
  ShortcutIconOption(iconUrl: 'images/icons/map/docks.png', color: Color(0xFFFDD835), label: 'Docks'),
  ShortcutIconOption(iconUrl: 'images/icons/map/estate_agents.png', color: Color(0xFFFDD835), label: 'Estate Agents'),
  ShortcutIconOption(iconUrl: 'images/icons/map/item_market.png', color: Color(0xFFFDD835), label: 'Item Market'),
  ShortcutIconOption(iconUrl: 'images/icons/map/jewelry_store.png', color: Color(0xFFFDD835), label: 'Jewelry Store'),
  ShortcutIconOption(iconUrl: 'images/icons/map/pawn_shop.png', color: Color(0xFFFDD835), label: 'Pawn Shop'),
  ShortcutIconOption(iconUrl: 'images/icons/map/pharmacy.png', color: Color(0xFFFDD835), label: 'Pharmacy'),
  ShortcutIconOption(
      iconUrl: 'images/icons/map/points_building.png', color: Color(0xFFFDD835), label: 'Points Building'),
  ShortcutIconOption(iconUrl: 'images/icons/map/points_market.png', color: Color(0xFFFDD835), label: 'Points Market'),
  ShortcutIconOption(iconUrl: 'images/icons/map/post_office.png', color: Color(0xFFFDD835), label: 'Post Office'),
  ShortcutIconOption(iconUrl: 'images/icons/map/print_store.png', color: Color(0xFFFDD835), label: 'Print Store'),
  ShortcutIconOption(iconUrl: 'images/icons/map/super_store.png', color: Color(0xFFFDD835), label: 'Super Store'),
  ShortcutIconOption(iconUrl: 'images/icons/map/sweet_shop.png', color: Color(0xFFFDD835), label: 'Sweet Shop'),
  ShortcutIconOption(iconUrl: 'images/icons/map/tc_clothing.png', color: Color(0xFFFDD835), label: 'TC Clothing'),
  ShortcutIconOption(iconUrl: 'images/icons/map/token_shop.png', color: Color(0xFFFDD835), label: 'Token Shop'),
  ShortcutIconOption(iconUrl: 'images/icons/map/bank.png', color: Color(0xFF1976D2), label: 'Bank'),
  ShortcutIconOption(iconUrl: 'images/icons/map/donator_house.png', color: Color(0xFF1976D2), label: 'Donator House'),
  ShortcutIconOption(iconUrl: 'images/icons/map/msg_inc.png', color: Color(0xFF1976D2), label: 'MSG Inc'),
  ShortcutIconOption(iconUrl: 'images/icons/map/stock_exchange.png', color: Color(0xFF1976D2), label: 'Stock Exchange'),
  ShortcutIconOption(iconUrl: 'images/icons/map/church.png', color: Color(0xFF7B1FA2), label: 'Church'),
  ShortcutIconOption(iconUrl: 'images/icons/map/dump.png', color: Color(0xFF7B1FA2), label: 'Dump'),
  ShortcutIconOption(iconUrl: 'images/icons/map/loan_shark.png', color: Color(0xFF7B1FA2), label: 'Loan Shark'),
  ShortcutIconOption(iconUrl: 'images/icons/map/travel_agency.png', color: Color(0xFF7B1FA2), label: 'Travel Agency'),
  ShortcutIconOption(
      iconUrl: 'images/icons/map/chronicle_archives.png', color: Color(0xFF388E3C), label: 'Chronicle Archives'),
  ShortcutIconOption(
      iconUrl: 'images/icons/map/community_center.png', color: Color(0xFF388E3C), label: 'Community Center'),
  ShortcutIconOption(iconUrl: 'images/icons/map/race_track.png', color: Color(0xFF388E3C), label: 'Race Track'),
  ShortcutIconOption(iconUrl: 'images/icons/map/sports_shop.png', color: Color(0xFF388E3C), label: 'Sports Shop'),
  ShortcutIconOption(iconUrl: 'images/icons/map/city_hall.png', color: Color(0xFFEF9A9A), label: 'City Hall'),
  ShortcutIconOption(iconUrl: 'images/icons/map/committee.png', color: Color(0xFFEF9A9A), label: 'Committee'),
  ShortcutIconOption(iconUrl: 'images/icons/map/staff.png', color: Color(0xFFEF9A9A), label: 'Staff'),
  ShortcutIconOption(iconUrl: 'images/icons/map/visitor_center.png', color: Color(0xFFEF9A9A), label: 'Visitor Center'),
  ShortcutIconOption(iconUrl: 'images/icons/map/museum.png', color: Color(0xFF757575), label: 'Museum'),
  ShortcutIconOption(iconUrl: 'images/icons/map/missions.png', color: Color(0xFF757575), label: 'Map Missions'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/trades.png', color: Color(0xFFCE93D8), label: 'Trades'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/bazaar.png', color: Color(0xFFCE93D8), label: 'Bazaar'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/ammo.png', color: Color(0xFFCE93D8), label: 'Ammo'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/primary.png', color: Color(0xFFCE93D8), label: 'Primary'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/secondary.png', color: Color(0xFFCE93D8), label: 'Secondary'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/melee.png', color: Color(0xFFCE93D8), label: 'Melee'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/temporary.png', color: Color(0xFFCE93D8), label: 'Temporary'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/armor.png', color: Color(0xFFCE93D8), label: 'Armor'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/clothing.png', color: Color(0xFFCE93D8), label: 'Clothing'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/medical.png', color: Color(0xFFCE93D8), label: 'Medical'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/drugs.png', color: Color(0xFFCE93D8), label: 'Drugs'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/energy.png', color: Color(0xFFCE93D8), label: 'Energy'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/alcohol.png', color: Color(0xFFCE93D8), label: 'Alcohol'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/candy.png', color: Color(0xFFCE93D8), label: 'Candy'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/boosters.png', color: Color(0xFFCE93D8), label: 'Boosters'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/enhancer.png', color: Color(0xFFCE93D8), label: 'Enhancer'),
  ShortcutIconOption(
      iconUrl: 'images/icons/inventory/supply_packs.png', color: Color(0xFFCE93D8), label: 'Supply Packs'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/electronics.png', color: Color(0xFFCE93D8), label: 'Electronics'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/jewelry.png', color: Color(0xFFCE93D8), label: 'Jewelry'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/flowers.png', color: Color(0xFFCE93D8), label: 'Flowers'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/plushies.png', color: Color(0xFFCE93D8), label: 'Plushies'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/viruses.png', color: Color(0xFFCE93D8), label: 'Viruses'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/artifacts.png', color: Color(0xFFCE93D8), label: 'Artifacts'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/books.png', color: Color(0xFFCE93D8), label: 'Books'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/special.png', color: Color(0xFFCE93D8), label: 'Special'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/misc.png', color: Color(0xFFCE93D8), label: 'Misc'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/cars.png', color: Color(0xFFCE93D8), label: 'Cars'),
  ShortcutIconOption(
      iconUrl: 'images/icons/inventory/collectibles.png', color: Color(0xFFCE93D8), label: 'Collectibles'),
  ShortcutIconOption(iconUrl: 'images/icons/inventory/all.png', color: Color(0xFFCE93D8), label: 'All Items'),
  ShortcutIconOption(iconUrl: 'images/icons/world_icon.png', color: Color(0xFFFF9800), label: 'Globe', fullColor: true),
];

const List<Color> shortcutPickerColors = [
  Color(0xFF212121),
  Color(0xFFF5F5F5),
  Color(0xFFFF8F00),
  Color(0xFF757575),
  Color(0xFF388E3C),
  Color(0xFF1976D2),
  Color(0xFF7B1FA2),
  Color(0xFFD32F2F),
  Color(0xFFEF9A9A),
  Color(0xFFCE93D8),
  Color(0xFF90CAF9),
  Color(0xFFA5D6A7),
  Color(0xFFFFCC80),
  Color(0xFFBCAAA4),
];

class ShortcutIconPicker extends StatelessWidget {
  final String selectedIconUrl;
  final Color? selectedIconColor;
  final Color selectedBorderColor;
  final ValueChanged<ShortcutIconOption> onIconSelected;
  final ValueChanged<Color?> onIconColorChanged;
  final ValueChanged<Color> onBorderColorChanged;

  const ShortcutIconPicker({
    required this.selectedIconUrl,
    required this.selectedIconColor,
    required this.selectedBorderColor,
    required this.onIconSelected,
    required this.onIconColorChanged,
    required this.onBorderColorChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final hasOverlay = selectedIconColor != null;
    final selectedIsFullColor = shortcutIconOptions.any((o) => o.iconUrl == selectedIconUrl && o.fullColor);
    final normalIcons = shortcutIconOptions.where((o) => !o.fullColor).toList();
    final fullColorIcons = shortcutIconOptions.where((o) => o.fullColor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose an icon:",
          style: TextStyle(fontSize: 12, color: themeProvider.mainText),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: normalIcons.map((option) {
                    return _iconTile(option, hasOverlay, themeProvider.mainText);
                  }).toList(),
                ),
                if (fullColorIcons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Full color:",
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: fullColorIcons.map((option) {
                      return _iconTile(option, false, themeProvider.mainText);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!selectedIsFullColor) ...[
          Row(
            children: [
              Text(
                "Icon color overlay:",
                style: TextStyle(fontSize: 12, color: themeProvider.mainText),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 24,
                width: 36,
                child: Switch(
                  value: hasOverlay,
                  onChanged: (value) {
                    onIconColorChanged(value ? shortcutPickerColors.first : null);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (hasOverlay) ...[
            const SizedBox(height: 8),
            _colorRow(shortcutPickerColors, selectedIconColor, onIconColorChanged),
          ],
          const SizedBox(height: 12),
        ],
        Text(
          "Border color:",
          style: TextStyle(fontSize: 12, color: themeProvider.mainText),
        ),
        const SizedBox(height: 8),
        _colorRow(shortcutPickerColors, selectedBorderColor, (c) {
          if (c != null) onBorderColorChanged(c);
        }),
      ],
    );
  }

  Widget _iconTile(ShortcutIconOption option, bool applyOverlay, Color mainText) {
    final isSelected = option.iconUrl == selectedIconUrl;
    return GestureDetector(
      onTap: () {
        onIconSelected(option);
        if (option.fullColor) {
          onIconColorChanged(null);
        }
      },
      child: Tooltip(
        message: option.label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            option.iconUrl,
            width: 24,
            height: 24,
            color: option.fullColor ? null : (applyOverlay ? selectedIconColor : mainText),
          ),
        ),
      ),
    );
  }

  Widget _colorRow(List<Color> colors, Color? selected, ValueChanged<Color?> onTap) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((color) {
        final isSelected = selected == color;
        return GestureDetector(
          onTap: () => onTap(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)] : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
