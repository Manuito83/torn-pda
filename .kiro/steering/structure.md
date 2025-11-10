# Project Structure

## Organization Philosophy

Feature-first layout layered on top of shared infrastructure. Each domain (travel, chaining, friends, loot, etc.) gets:
1. A UI page + dialogs in `lib/pages/**` or `lib/widgets/**`.
2. Domain models in `lib/models/**`.
3. State + side effects in `lib/providers/**`.
4. Cross-cutting helpers in `lib/utils/**`.

This keeps presentation, state, and integration concerns decoupled while reusing shared widgets, assets, and storage.

## Directory Patterns

### Feature Pages
**Location**: `lib/pages/<feature>/`  
**Purpose**: Screen widgets that compose providers, dialogs, and common widgets for a specific Torn workflow. Subdirectories hold complex flows (e.g., `lib/pages/travel/`, `lib/pages/chaining/`).  
**Example**: `lib/pages/travel/travel_page.dart` binds travel data providers, timers, and dialogs into a routed screen.

### Providers & Controllers
**Location**: `lib/providers/`  
**Purpose**: Application state, API orchestration, timers, and background tasks. Uses `ChangeNotifier` for UI-facing state and `GetxController` for queue-based logic (`lib/providers/api/api_caller.dart`).  
**Example**: `lib/providers/settings_provider.dart` exposes persisted settings, while `lib/providers/war_controller.dart` streams chain/war updates.

### Models & API Clients
**Location**: `lib/models/`  
**Purpose**: DTOs mirroring Torn API entities plus generated Swagger clients (e.g., `lib/models/api_v2`). Grouped by domain (`models/travel`, `models/chaining`, etc.) so providers can share typed contracts.  
**Example**: `lib/models/profile/` stores profile snapshots and stats calculators.

### Widgets & Dialogs
**Location**: `lib/widgets/`  
**Purpose**: Reusable UI components, modal dialogs, and feature-specific widgets (travel dialogs, stats cards, vault widgets). They remain stateless/stateful widgets fed entirely by providers.  
**Example**: `lib/widgets/stats/stats_dialog.dart` formats stats data for multiple sources (Torn, YATA, TSC).

### Utilities & Platform Bridges
**Location**: `lib/utils/`  
**Purpose**: Shared services (notifications, connectivity, storage, WebView bridges, live activities). Encapsulates platform channels and isolates so higher layers call simple Dart APIs.  
**Example**: `lib/utils/shared_prefs.dart` (with Sembast migration) and `lib/utils/live_activities/` (iOS live activity glue).

## Naming Conventions

- **Files**: `snake_case.dart` (e.g., `chain_status_controller.dart`)
- **Widgets & Classes**: PascalCase (e.g., `ChainStatusController`, `TravelPage`)
- **Providers/Controllers**: Suffix with `Provider` or `Controller` to signal lifecycle expectations
- **Assets**: Grouped directories under `images/`, `sounds/`, `userscripts/` mirroring pubspec asset entries

## Import Organization

```dart
// Flutter & dart core first
import 'package:flutter/material.dart';

// Third-party packages
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// Project modules
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/widgets/travel/stock_options_dialog.dart';
```

**Path Alias**: `package:torn_pda/...` is the canonical absolute import root; keep relative imports for same-directory helpers only.

## Code Organization Principles

- UI pages never invoke HTTP directly; they read data through Providers or Controllers, which in turn rely on `utils/` services.
- Background responsibilities (Workmanager, notifications, widgets) live in utilities/controllers so they can run without the UI tree.
- Domain modules share typed models to coordinate API payloads, ensuring calculators and dialogs stay consistent across screens.
- Keep feature assets (images, sounds, JS) in the dedicated root folders referenced in `pubspec.yaml` so Flutter’s asset bundling stays predictable.

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_
