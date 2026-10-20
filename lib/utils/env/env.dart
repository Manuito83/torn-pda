// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(allowOptionalFields: true)
abstract class Env {
  @EnviedField(varName: 'TSC_HEADER_KEY', defaultValue: '', obfuscate: true)
  static String tscHeader = _Env.tscHeader;
}
