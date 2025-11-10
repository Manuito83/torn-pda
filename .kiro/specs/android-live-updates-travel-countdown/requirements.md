# Requirements Document

## Introduction
Build an Android Live Update experience that mirrors Torn PDA's existing iOS travel Live Activity: eligible devices (especially OnePlus 13 "island" surfaces) should show a real-time countdown for departures and arrivals, keep content in sync with Flutter travel data, and open the app on tap while degrading gracefully on unsupported versions.

## Requirements

### Requirement 1: Capability Scoping & Device Eligibility
**Objective:** As a traveling player, I want the app to detect whether my device supports Android Live Updates so that countdowns only appear where they can be rendered reliably.

#### Acceptance Criteria
1. When the Flutter travel controller requests a Live Update session, the Live Update Service shall verify Android OS version, OEM Live Update availability, and required notification permissions before creating the session.
2. If any eligibility check fails, the Live Update Service shall return a structured "unsupported" status to the Flutter layer without attempting to render a Live Update.
3. Where the device exposes OnePlus 13 capsule/island mode, the Live Update Service shall publish a capability flag so settings screens can tell the user that the surface is available.
4. While eligibility changes because the user toggles permissions or disables system surfaces, the Live Update Service shall refresh its reported capability status before handling the next start request.

### Requirement 2: Countdown Content & Refresh Accuracy
**Objective:** As a traveling player, I want the Live Update to show an accurate departure or arrival countdown so that I can monitor travel timing without opening the app.

#### Acceptance Criteria
1. When a travel countdown begins, the Live Update Service shall present departure time, arrival time, remaining duration, and destination label on the Live Update surface.
2. While a Live Update is active, the Live Update Service shall keep the displayed remaining duration within ±1 second of the travel timer maintained by the Flutter controller.
3. When the travel ETA changes by at least 5 seconds, the Live Update Service shall push the updated times to the Live Update surface within 3 seconds of receiving the new data.
4. When the countdown reaches zero, the Live Update Service shall transition the surface into an "arrived" state that remains visible until Flutter ends the session or the system auto-dismisses it.

### Requirement 3: Interaction & Surface Behavior
**Objective:** As a traveling player, I want Live Updates to behave consistently across lock screen, notification shade, and island-style capsules so that tapping or dismissing them works the same everywhere.

#### Acceptance Criteria
1. When a user taps the Live Update on any supported surface, the Live Update Service shall launch Torn PDA's MainActivity with a payload that routes the user to the travel context.
2. While the Live Update is visible on lock screen, shade, or island, the Live Update Service shall ensure content parity (timer text, destination, and iconography) across all surfaces.
3. If the system or user dismisses the Live Update, the Live Update Service shall notify the Flutter layer with the dismissal reason before cleaning up session state.
4. Where OEM-specific animation hooks exist (such as the OnePlus capsule), the Live Update Service shall supply the tap intent and content format required by that surface to keep navigation functional.

### Requirement 4: Lifecycle Management & Fallback Handling
**Objective:** As a Torn PDA operator, I want predictable start/update/end flows so that telemetry, retries, and fallbacks remain consistent across devices.

#### Acceptance Criteria
1. When Flutter requests `startTravelActivity`, the Live Update Service shall create a uniquely identifiable Live Update session and return the identifier to Flutter for telemetry correlation.
2. When Flutter requests `endTravelActivity`, the Live Update Service shall cancel the associated Live Update session and confirm completion back to Flutter.
3. If the system times out or suppresses a Live Update (e.g., due to battery saver or background restrictions), the Live Update Service shall emit a timeout status so Flutter can trigger local notifications as fallback.
4. While no Live Update session is active, the Live Update Service shall keep the `isAnyTravelActivityActive` signal in sync so Flutter widgets and background workers can decide whether to display alternate countdown surfaces.

<!-- Generated via /prompts:kiro-spec-requirements -->
