/// Status returned by native start/update requests.
enum LiveUpdateRequestStatus {
  started,
  updated,
  unsupported,
  error,
}

/// Reasons returned when a Live Update cannot be rendered.
enum LiveUpdateUnsupportedReason {
  apiTooOld,
  oemUnavailable,
  permissionDenied,
  batteryRestricted,
  internalError,
  unknown,
}

/// Lifecycle events emitted by the native layer.
enum LiveUpdateLifecycleStatus {
  started,
  updated,
  arrived,
  timeout,
  dismissed,
  ended,
}

/// System surface that currently shows the Live Update.
enum LiveUpdateSurface {
  lockscreen,
  shade,
  capsule,
  notification,
  unknown,
}

class LiveUpdateCapabilitySnapshot {
  final bool supportedApi;
  final bool oemCapsule;
  final bool notificationsEnabled;
  final bool batteryOptimized;
  final String vendor;
  final DateTime? timestamp;

  const LiveUpdateCapabilitySnapshot({
    required this.supportedApi,
    required this.oemCapsule,
    required this.notificationsEnabled,
    required this.batteryOptimized,
    required this.vendor,
    this.timestamp,
  });

  factory LiveUpdateCapabilitySnapshot.fromJson(Map<String, dynamic> json) {
    return LiveUpdateCapabilitySnapshot(
      supportedApi: json['supportedApi'] == true,
      oemCapsule: json['oemCapsule'] == true,
      notificationsEnabled: json['notificationsEnabled'] == true,
      batteryOptimized: json['batteryOptimized'] == true,
      vendor: (json['vendor'] ?? '') as String,
      timestamp:
          json['timestamp'] is num ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportedApi': supportedApi,
      'oemCapsule': oemCapsule,
      'notificationsEnabled': notificationsEnabled,
      'batteryOptimized': batteryOptimized,
      'vendor': vendor,
      'timestamp': timestamp?.millisecondsSinceEpoch,
    }..removeWhere((key, value) => value == null);
  }
}

class LiveUpdateStartResult {
  final LiveUpdateRequestStatus status;
  final String? sessionId;
  final LiveUpdateCapabilitySnapshot? capabilitySnapshot;
  final LiveUpdateUnsupportedReason? reason;
  final String? errorMessage;

  const LiveUpdateStartResult({
    required this.status,
    this.sessionId,
    this.capabilitySnapshot,
    this.reason,
    this.errorMessage,
  });

  bool get isSuccess => status == LiveUpdateRequestStatus.started || status == LiveUpdateRequestStatus.updated;

  factory LiveUpdateStartResult.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return LiveUpdateStartResult(
        status: _parseStatus(map['status']),
        sessionId: map['sessionId'] as String?,
        capabilitySnapshot: map['capabilitySnapshot'] is Map
            ? LiveUpdateCapabilitySnapshot.fromJson(map['capabilitySnapshot'].cast<String, dynamic>())
            : null,
        reason: _parseReason(map['reason']),
        errorMessage: map['errorMessage'] as String?,
      );
    }
    return const LiveUpdateStartResult(status: LiveUpdateRequestStatus.started);
  }

  static LiveUpdateRequestStatus _parseStatus(dynamic value) {
    switch (value) {
      case 'updated':
        return LiveUpdateRequestStatus.updated;
      case 'unsupported':
        return LiveUpdateRequestStatus.unsupported;
      case 'error':
        return LiveUpdateRequestStatus.error;
      case 'started':
      default:
        return LiveUpdateRequestStatus.started;
    }
  }

  static LiveUpdateUnsupportedReason? _parseReason(dynamic value) {
    switch (value) {
      case 'API_TOO_OLD':
        return LiveUpdateUnsupportedReason.apiTooOld;
      case 'OEM_UNAVAILABLE':
        return LiveUpdateUnsupportedReason.oemUnavailable;
      case 'PERMISSION_DENIED':
        return LiveUpdateUnsupportedReason.permissionDenied;
      case 'BATTERY_RESTRICTED':
        return LiveUpdateUnsupportedReason.batteryRestricted;
      case 'INTERNAL_ERROR':
        return LiveUpdateUnsupportedReason.internalError;
      case null:
        return null;
      default:
        return LiveUpdateUnsupportedReason.unknown;
    }
  }
}

class LiveUpdateEndResult {
  final bool success;
  final LiveUpdateUnsupportedReason? reason;
  final String? errorMessage;

  const LiveUpdateEndResult({
    required this.success,
    this.reason,
    this.errorMessage,
  });

  factory LiveUpdateEndResult.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return LiveUpdateEndResult(
        success: map['success'] != false,
        reason: LiveUpdateStartResult._parseReason(map['reason']),
        errorMessage: map['errorMessage'] as String?,
      );
    }
    return const LiveUpdateEndResult(success: true);
  }
}

class LiveUpdateStatusEvent {
  final String? sessionId;
  final LiveUpdateLifecycleStatus status;
  final LiveUpdateSurface surface;
  final LiveUpdateUnsupportedReason? reason;

  const LiveUpdateStatusEvent({
    this.sessionId,
    required this.status,
    required this.surface,
    this.reason,
  });

  factory LiveUpdateStatusEvent.fromJson(Map<String, dynamic> json) {
    return LiveUpdateStatusEvent(
      sessionId: json['sessionId'] as String?,
      status: _parseLifecycleStatus(json['status'] as String?),
      surface: _parseSurface(json['surface'] as String?),
      reason: LiveUpdateStartResult._parseReason(json['reason']),
    );
  }

  static LiveUpdateLifecycleStatus _parseLifecycleStatus(String? value) {
    switch (value) {
      case 'updated':
        return LiveUpdateLifecycleStatus.updated;
      case 'arrived':
        return LiveUpdateLifecycleStatus.arrived;
      case 'timeout':
        return LiveUpdateLifecycleStatus.timeout;
      case 'dismissed':
        return LiveUpdateLifecycleStatus.dismissed;
      case 'ended':
        return LiveUpdateLifecycleStatus.ended;
      case 'started':
      default:
        return LiveUpdateLifecycleStatus.started;
    }
  }

  static LiveUpdateSurface _parseSurface(String? value) {
    switch (value) {
      case 'lockscreen':
        return LiveUpdateSurface.lockscreen;
      case 'shade':
        return LiveUpdateSurface.shade;
      case 'capsule':
        return LiveUpdateSurface.capsule;
      case 'notification':
        return LiveUpdateSurface.notification;
      default:
        return LiveUpdateSurface.unknown;
    }
  }
}
