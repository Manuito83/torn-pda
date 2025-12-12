# Research & Design Decisions Template

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

**Usage**:
- Log research activities and outcomes during the discovery phase.
- Document design decision trade-offs that are too detailed for `design.md`.
- Provide references and evidence for future audits or reuse.
---

## Summary
- **Feature**: android-live-updates-travel-countdown
- **Discovery Scope**: Complex Integration
- **Key Findings**:
  - Existing Flutter Live Activity controller already packages complete travel countdown arguments and speaks over `com.tornpda.liveactivity`, so Android can reuse the contract with minimal Dart churn.
  - Android currently lacks any native channel handler, so a Kotlin `LiveUpdateManager` plus eligibility evaluator is needed to gate OS/OEM support and provide structured fallback reasons.
  - OEM-specific capsules (OnePlus 13) require explicit capability detection and tap intent formatting to ensure navigation parity across lock screen, notification shade, and vendor “island” surfaces.

## Research Log

### Live Activity Bridge Inventory
- **Context**: Verify how Flutter currently structures countdown payloads and lifecycle hooks.
- **Sources Consulted**: `lib/utils/live_activities/live_activity_travel_controller.dart`, `lib/utils/live_activities/live_activity_bridge.dart`, `ios/Runner/AppDelegate.swift`.
- **Findings**:
  - Travel controller already guards activation per platform and funnels `startTravelActivity` / `endTravelActivity` invocations through one bridge controller.
  - iOS implementation expects a rich payload (destination labels, timestamps, vehicle assets, arrival flag) and returns errors via `FlutterError` when validation fails.
  - `LiveActivityBridgeController` currently treats `invokeMethod` calls as `Future<void>` and only listens for `liveActivityTokenUpdated` callbacks.
- **Implications**: Android must implement the same channel name and arguments, but it should extend the result contract (e.g., returning `{status, reason}`) and add new callbacks (dismissal, timeout) so Flutter can meet Requirement 4 without polling.

### Android Live Updates API Readiness
- **Context**: Determine platform constraints and SDK surface for the unreleased Android Live Updates feature.
- **Sources Consulted**: `.shotgun/research.md` (internal brief); prior Android 15 DP release notes (local knowledge); no external WebSearch available under current sandbox.
- **Findings**:
  - Live Updates are expected to arrive on Android 15+ with OEM-specific capsules (OnePlus 13) mapping to the same underlying surface exposed on lock screen and notification shade.
  - Official dependency coordinates and lifecycle callbacks are pending, so we must isolate the integration behind an adapter to swap once Google/OEM docs are published.
  - Feature likely ties into notification permissions and foreground service allowances, meaning eligibility checks must include API level, vendor capability, and notification channel state.
- **Implications**: The design will introduce `LiveUpdateAdapter` and `NoOpLiveUpdateAdapter`. Kotlin code will short-circuit unsupported devices while still reporting capability metadata back to Flutter for settings disclosures.

### OnePlus Capsule Behavior
- **Context**: Ensure countdown/tap parity on OnePlus 13 “island” surfaces.
- **Sources Consulted**: `.shotgun/research.md` OEM notes; OnePlus 13 system behavior observed internally.
- **Findings**:
  - OnePlus capsules consume the same Live Update payload but expect branded icons and may require whitelisting in system settings; they expose a capability flag in OEM APIs.
  - Tap gestures route through regular PendingIntents, but animation states change if metadata omits capsule descriptors.
- **Implications**: Add an `OemCapabilityDetector` that surfaces `capsuleAvailable: true/false` to Flutter, and ensure the Kotlin adapter packages a capsule-friendly intent (same deep link used on other surfaces). Settings UI can read the capability flag before prompting users to enable the OEM setting.

### Method Channel Contract & Telemetry Needs
- **Context**: Requirements demand structured unsupported responses and dismissal/time-out notifications back to Flutter.
- **Sources Consulted**: Flutter bridge code; MethodChannel docs; existing `tornpda.channel` handler for reference of returning maps.
- **Findings**:
  - Current Dart bridge ignores results, so returning meaningful payloads requires updating the Dart side to parse responses while remaining backward compatible with iOS.
  - Android can leverage `MethodChannel.Result` to send `{ "status": "started", "sessionId": "..." }` or `{ "status": "unsupported", "reason": "MISSING_PERMISSION" }` without breaking iOS (since Swift already returns `nil`).
  - Dismissal events can be emitted via `invokeMethod` from Kotlin to Dart using the existing handler initialization pattern.
- **Implications**: Update Dart bridge to await `invokeMethod` results, introduce typed DTOs (`LiveUpdateStartResult`, `LiveUpdateStatusChange`), and document the bidirectional contracts in both `research.md` and `design.md`.

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Flutter-only countdown widgets | Implement Live Update look-alike purely in Flutter UI/widgets | No native work | Cannot reach lock screen/island surfaces; fails requirements | Rejected |
| Direct Android notifications without abstraction | Extend existing notification helpers to mimic Live Updates | Reuses current infra | OEM capsules likely won’t ingest them; harder to swap to official API later | Rejected |
| Adapter-backed Android Live Update Manager (Selected) | Introduce `LiveUpdateManager` with pluggable adapters (`AndroidLiveUpdateAdapter`, `NoOpLiveUpdateAdapter`) plus eligibility/capability sensors | Keeps integration isolated, enables staged rollout, satisfies structured status + callbacks | Requires upfront scaffolding and new Kotlin modules | Selected approach aligning with steering focus on reusable utilities |

## Design Decisions

### Decision: Adapter-backed Live Update Manager
- **Context**: Need to integrate a pending Android API without destabilizing Flutter flow.
- **Alternatives Considered**:
  1. Implement Live Update API calls directly inside the MethodChannel handler.
  2. Build a dedicated manager/adapter layer with eligibility + session tracking.
- **Selected Approach**: Create `LiveUpdateManager` to orchestrate lifecycle and delegate to adapters representing concrete OS capabilities.
- **Rationale**: Keeps `MainActivity` slim, allows mocking in unit tests, and lets us drop in the actual API once documentation ships.
- **Trade-offs**: Slightly more classes and indirection now; requires init wiring during app start.
- **Follow-up**: Wire real adapter once Google releases SDK artifacts and document dependency versions.

### Decision: Structured MethodChannel Contracts
- **Context**: Requirements need unsupported reasons, session IDs, and dismissal notifications.
- **Alternatives Considered**:
  1. Keep `void` results and rely on logs or implicit behavior.
  2. Return structured JSON and emit callbacks back into Flutter.
- **Selected Approach**: Extend MethodChannel to return maps and send event callbacks.
- **Rationale**: Matches EARS requirements, supports telemetry, and aligns with existing `tornpda.channel` pattern.
- **Trade-offs**: Requires changes on both Dart and Kotlin sides plus additional serialization models.
- **Follow-up**: Version the Dart bridge models to stay compatible with existing iOS responses (which continue returning `null`).

### Decision: Capability Exposure to Flutter
- **Context**: Requirement 1.3 needs Flutter settings to show whether OnePlus capsule exists.
- **Alternatives Considered**:
  1. Compute capability only inside Kotlin and never expose it upward.
  2. Surface capability flags (API level, OEM, notification permissions) to Flutter.
- **Selected Approach**: Add new MethodChannel method `getLiveUpdateCapabilities` returning structured info.
- **Rationale**: Enables UI messaging, analytics, and gating of user prompts without duplicating detection logic in Dart.
- **Trade-offs**: More channel calls, but they’re infrequent.
- **Follow-up**: Cache the result in Dart and update when permission broadcasts arrive.

## Risks & Mitigations
- Live Update API contract may change before GA — Mitigation: keep adapter behind interface and ship `NoOp` fallback until dependencies stabilize.
- OEM capsules may behave inconsistently — Mitigation: instrument capability telemetry and provide user setting to disable capsules.
- Permission revocations could desync eligibility — Mitigation: register for `ACTION_NOTIFICATION_POLICY_ACCESS_GRANTED_CHANGED` and re-run eligibility before each start call.

## References
- `.shotgun/research.md` — Live Updates feature research brief and OEM notes
- `lib/utils/live_activities/*.dart` — Existing Flutter travel Live Activity logic
- `ios/Runner/AppDelegate.swift` — iOS MethodChannel implementation used as parity baseline
