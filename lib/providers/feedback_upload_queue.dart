import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';
import 'package:torn_pda/utils/feedback_attachment_functions.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

enum FeedbackPickState { waiting, uploading, done, failed }

class FeedbackPick {
  FeedbackPick({required this.name, required this.path, required this.size, required this.contentType});

  final String name;
  final String path;
  final int size;
  final String contentType;
  FeedbackPickState state = FeedbackPickState.waiting;
  double progress = 0;
  String? error;
}

typedef FeedbackPicked = ({String name, String path, int size});

typedef FeedbackFilePicker = Future<List<FeedbackPicked>> Function();

typedef FeedbackFileUpload =
    Future<void> Function(
      FeedbackPick pick,
      String feedbackId,
      String? commentId,
      void Function(double progress) onProgress,
    );

Future<List<FeedbackPicked>> _choosePlatformFiles() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: feedbackAttachmentExtensions,
    allowMultiple: true,
  );
  return [
    if (result != null)
      for (final file in result.files)
        if (file.path != null) (name: file.name, path: file.path!, size: file.size),
  ];
}

Future<void> _uploadPick(FeedbackPick pick, String feedbackId, String? commentId, void Function(double) onProgress) {
  return uploadFeedbackFile(
    feedbackId: feedbackId,
    commentId: commentId,
    name: feedbackUploadName(pick.name),
    contentType: pick.contentType,
    path: pick.path,
    size: pick.size,
    onProgress: onProgress,
  );
}

class FeedbackUploadQueue extends ChangeNotifier {
  FeedbackUploadQueue({FeedbackFilePicker? pickFiles, FeedbackFileUpload? upload})
    : _pickFiles = pickFiles ?? _choosePlatformFiles,
      _upload = upload ?? _uploadPick;

  final FeedbackFilePicker _pickFiles;
  final FeedbackFileUpload _upload;

  final _picks = <FeedbackPick>[];
  String? _problem;
  bool _uploading = false;
  bool _disposed = false;

  List<FeedbackPick> get picks => List.unmodifiable(_picks);
  bool get uploading => _uploading;
  bool get isFull => _picks.length >= feedbackMaxAttachments;

  // Something still has to go up
  bool get hasPending => _picks.any((pick) => pick.state != FeedbackPickState.done);

  // Last file refused
  String? get problem => _problem;

  Future<void> add() async {
    if (_uploading || isFull) return;
    _problem = null;
    final List<FeedbackPicked> chosen;
    try {
      chosen = await _pickFiles();
    } catch (_) {
      _problem = feedbackReasonText(null);
      _notify();
      return;
    }
    for (final file in chosen) {
      final refusal = feedbackFileProblem(name: file.name, size: file.size, already: _picks.length);
      if (refusal != null) {
        _problem = refusal;
        continue;
      }
      _picks.add(
        FeedbackPick(name: file.name, path: file.path, size: file.size, contentType: feedbackContentType(file.name)!),
      );
    }
    _notify();
  }

  void remove(FeedbackPick pick) {
    if (_uploading) return;
    _picks.remove(pick);
    _problem = null;
    _notify();
  }

  void clear() {
    _picks.clear();
    _problem = null;
    _notify();
  }

  // Failed files, files already up are skipped
  Future<int> uploadAll(String feedbackId, {String? commentId}) async {
    if (_uploading) return 0;
    _uploading = true;
    var failed = 0;
    for (final pick in _picks.where((pick) => pick.state != FeedbackPickState.done)) {
      pick
        ..state = FeedbackPickState.uploading
        ..progress = 0
        ..error = null;
      _notify();
      try {
        await _upload(pick, feedbackId, commentId, (progress) {
          pick.progress = progress;
          _notify();
        });
        pick.state = FeedbackPickState.done;
      } catch (e) {
        pick
          ..state = FeedbackPickState.failed
          ..error = e is FeedbackCallError ? e.text : feedbackReasonText(null);
        failed++;
      }
      _notify();
    }
    _uploading = false;
    _notify();
    return failed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
