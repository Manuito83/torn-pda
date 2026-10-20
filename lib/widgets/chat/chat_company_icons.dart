import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/user_controller.dart';

const Map<int, IconData> _companyTypeIcons = {
  1: Icons.content_cut_rounded,
  2: Icons.gavel_rounded,
  3: Icons.local_florist_rounded,
  4: Icons.directions_car_rounded,
  5: Icons.checkroom_rounded,
  6: Icons.gps_fixed_rounded,
  7: Icons.sports_esports_rounded,
  8: Icons.local_fire_department_rounded,
  9: Icons.toys_rounded,
  10: Icons.favorite_rounded,
  11: Icons.computer_rounded,
  12: Icons.local_grocery_store_rounded,
  13: Icons.theater_comedy_rounded,
  14: Icons.icecream_rounded,
  15: Icons.directions_boat_rounded,
  16: Icons.tv_rounded,
  18: Icons.pets_rounded,
  19: Icons.celebration_rounded,
  20: Icons.real_estate_agent_rounded,
  21: Icons.chair_rounded,
  22: Icons.local_gas_station_rounded,
  23: Icons.music_note_rounded,
  24: Icons.nightlife_rounded,
  25: Icons.sports_bar_rounded,
  26: Icons.nightlife_rounded,
  27: Icons.restaurant_rounded,
  28: Icons.oil_barrel_rounded,
  29: Icons.fitness_center_rounded,
  30: Icons.build_rounded,
  31: Icons.attractions_rounded,
  32: Icons.shopping_bag_rounded,
  33: Icons.warehouse_rounded,
  34: Icons.agriculture_rounded,
  35: Icons.code_rounded,
  36: Icons.nightlife_rounded,
  37: Icons.security_rounded,
  38: Icons.hardware_rounded,
  39: Icons.search_rounded,
  40: Icons.local_shipping_rounded,
};

IconData? _chatCompanyTypeIcon(int? type) => _companyTypeIcons[type];

IconData? chatOwnCompanyIcon() {
  if (!Get.isRegistered<UserController>()) return null;
  return _chatCompanyTypeIcon(Get.find<UserController>().basic?.job?.companyType);
}
