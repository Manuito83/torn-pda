# Config files (private)

The `.dart` files in this directory contain sensitive configuration and are excluded
from version control via `.gitignore`. The `.dart.example` files are templates.

For full build instructions, see the [Building from Source](../../docs/README.md#building-from-source) section in the developer docs.

`lib/utils/env/env.g.dart.example` is an empty stub. If keys are ever added to `Env`, the real `env.g.dart` is generated with build_runner and never committed.

The app will compile with the placeholder values, but some features
(e.g. YATA proxy, TAC, native auth, native chat) will not function without real credentials.
