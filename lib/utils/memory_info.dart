import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MemoryInfo {
  static const MethodChannel _platformAndroid = MethodChannel('tornpda.channel');
  static const MethodChannel _platformIOS = MethodChannel('tornpda/memory');
  static final MethodChannel _platform = Platform.isIOS ? _platformIOS : _platformAndroid;

  static Future<Map<String, int>?> getMemoryInfoDetailed() async {
    try {
      final raw = await _platform.invokeMethod<Map>('getMemoryInfoDetailed');
      if (raw == null) return null;
      return raw.map((k, v) => MapEntry(k as String, v as int));
    } on PlatformException catch (e) {
      debugPrint('getMemoryInfoDetailed error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('getMemoryInfoDetailed unexpected: $e');
      return null;
    }
  }

  static Future<Map<String, int>?> getDeviceMemoryInfo() async {
    try {
      final raw = await _platform.invokeMethod<Map>('getDeviceMemoryInfo');
      if (raw == null) return null;
      return raw.map((k, v) => MapEntry(k as String, v as int));
    } on PlatformException catch (e) {
      debugPrint('getDeviceMemoryInfo error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('getDeviceMemoryInfo unexpected: $e');
      return null;
    }
  }

  static String formatBytes(int bytes, {bool includeUnits = true}) {
    final mb = bytes ~/ (1024 * 1024);
    return '$mb ${includeUnits ? "MB" : ""}';
  }
}
