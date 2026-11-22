import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';
import 'package:torn_pda/utils/territory_map/map_video_encoder.dart';

class TerritoryVideoController extends ChangeNotifier {
  TerritoryVideoController(this._encoder);

  final MapVideoEncoder _encoder;

  bool exporting = false;
  double progress = 0;

  // Day being recorded, from 1
  int day = 0;
  int total = 0;

  // Last frames in, file closing
  bool finishing = false;
  bool _cancelled = false;
  bool _disposed = false;

  bool get cancelled => _cancelled;

  void begin({int total = 0}) {
    exporting = true;
    _cancelled = false;
    finishing = false;
    progress = 0;
    day = 0;
    this.total = total;
    _notify();
  }

  void end() {
    exporting = false;
    _notify();
  }

  // Only counts while exporting
  void cancel() {
    if (!exporting || _cancelled) return;
    _cancelled = true;
    _notify();
  }

  @override
  void dispose() {
    _cancelled = true;
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // Null when cancelled
  Future<String?> export({
    required String path,
    required VideoSize size,
    required List<String> days,
    required Future<bool> Function(String day) showDay,
    required Future<Uint8List> Function() captureFrame,
  }) async {
    if (days.isEmpty) return null;
    if (!exporting) begin();
    total = days.length;
    try {
      await _encoder.start(path: path, width: size.width, height: size.height);
      late Uint8List last;
      for (var i = 0; i < days.length; i++) {
        day = i + 1;
        _notify();
        if (_cancelled || !await showDay(days[i])) return await _abort();
        last = await captureFrame();
        if (_cancelled) return await _abort();
        await _encoder.addFrame(last);
        progress = (i + 1) / days.length;
        _notify();
      }
      finishing = true;
      _notify();
      for (var i = 0; i < videoFinalHold; i++) {
        await _encoder.addFrame(last);
      }
      if (_cancelled) return await _abort();
      return await _encoder.finish();
    } catch (_) {
      await _encoder.cancel();
      rethrow;
    } finally {
      end();
    }
  }

  Future<String?> _abort() async {
    await _encoder.cancel();
    return null;
  }
}
