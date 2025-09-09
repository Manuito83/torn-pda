import 'package:get/get.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';

class UserHelper {
  static UserController get _uc => Get.find<UserController>();

  static bool get isApiKeyValid => _uc.isApiKeyValid;
  static String get apiKey => _uc.safeApiKey;
  static int get playerId => _uc.safePlayerId;
  static String get playerName => _uc.safePlayerName;
  static int get factionId => _uc.factionId;
  static int get companyId => _uc.companyId;

  // Stats access
  static int get totalStats => _uc.basic?.total ?? 0;
  static int get strength => _uc.basic?.strength ?? 0;
  static int get defense => _uc.basic?.defense ?? 0;
  static int get speed => _uc.basic?.speed ?? 0;
  static int get dexterity => _uc.basic?.dexterity ?? 0;

  // Other profile data
  static int get awards => _uc.basic?.awards ?? 0;

  // Marriage data
  static int get spouseId => _uc.basic?.married?.spouseId ?? 0;
  static String get spouseName => _uc.basic?.married?.spouseName ?? "";

  // User management methods
  static void removeUser() => _uc.removeUser();
  static void setUserDetails({required OwnProfileBasic userDetails}) => _uc.setUserDetails(userDetails: userDetails);

  // Direct access to basic profile when needed
  static OwnProfileBasic? get basic => _uc.basic;
}
