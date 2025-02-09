// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(allowOptionalFields: true)
abstract class Env {
  @EnviedField(varName: 'SENDBIRD_APP_ID', defaultValue: '', obfuscate: true)
  static String sendbirdAppId = _Env.sendbirdAppId;

  @EnviedField(varName: 'SENDBIRD_APP_TOKEN', defaultValue: '', obfuscate: true)
  static String sendbirdAppToken = _Env.sendbirdAppToken;

  @EnviedField(varName: 'TSC_HEADER_KEY', defaultValue: '', obfuscate: true)
  static String tscHeader = _Env.tscHeader;
}
