// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

// Before adding keys, untrack env.g.dart
@Envied(allowOptionalFields: true)
abstract class Env {}
