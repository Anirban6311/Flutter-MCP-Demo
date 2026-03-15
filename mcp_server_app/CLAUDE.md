# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flutter test app (`mcp_test_app`) designed for testing the Flutter VM MCP server. The app exposes Dart VM service extensions (`ext.mcptest.*`) that allow an MCP server to programmatically interact with the running app — navigating routes, entering text, tapping buttons, and reading widget state.

## Commands

```bash
flutter run              # Run the app (debug mode)
flutter analyze          # Static analysis (uses flutter_lints)
flutter test             # Run all widget tests
flutter test test/widget_test.dart  # Run a single test file
```

## Architecture

```
lib/
├── main.dart                     # Entry point: creates McpRegistry, registers extensions, runs app
├── app.dart                      # McpTestApp widget (MaterialApp + McpRegistryScope)
├── core/
│   ├── mcp/
│   │   ├── mcp_registry.dart     # McpRegistry class + McpRegistryScope InheritedWidget
│   │   └── mcp_service_extensions.dart  # VM service extension registration
│   ├── routing/
│   │   └── app_routes.dart       # Route name constants + route map builder
│   └── theme/
│       └── app_theme.dart        # ThemeData factory
├── features/                     # One folder per screen
│   ├── login/login_screen.dart
│   ├── home/home_screen.dart
│   ├── counter/counter_screen.dart
│   ├── settings/settings_screen.dart
│   └── profile/profile_screen.dart
└── shared/widgets/               # Reusable widgets (NavCard, SectionHeader)
```

### McpRegistry (Dependency Inversion)

`McpRegistry` (in `core/mcp/mcp_registry.dart`) replaces the old global maps. It holds:
- `textControllers` — registered `TextEditingController`s
- `tapCallbacks` — registered `VoidCallback`s
- `textGetters` — registered `String Function()` getters
- `navigatorKey` — the app's navigator key

The registry is provided to the widget tree via `McpRegistryScope` (an `InheritedWidget`). Screens access it with `McpRegistryScope.of(context)` in `didChangeDependencies()` and unregister in `dispose()`.

### VM Service Extensions

`registerMcpExtensions(McpRegistry)` in `core/mcp/mcp_service_extensions.dart` registers all `ext.mcptest.*` extensions. It depends only on the registry interface, not on any screen.

| Extension | Purpose |
|---|---|
| `ext.mcptest.navigate` | Push a named route |
| `ext.mcptest.back` | Pop current route |
| `ext.mcptest.setText` | Set text on a registered controller |
| `ext.mcptest.tap` | Fire a registered tap callback |
| `ext.mcptest.getText` | Read text from a getter or controller |
| `ext.mcptest.listKeys` | List all registered keys |

### Adding a New Screen

1. Create `lib/features/<name>/<name>_screen.dart`
2. Add a route constant in `AppRoutes` (`core/routing/app_routes.dart`)
3. Add the route entry in `AppRoutes.buildRoutes()`
4. Register MCP keys in `didChangeDependencies()`, unregister in `dispose()`

### Key Widget Keys by Screen

| Route | Key widgets |
|---|---|
| `/login` (initial) | `email_field`, `password_field`, `login_btn`, `skip_btn` |
| `/home` | `counter_card`, `settings_card`, `profile_card`, `fab_snackbar` |
| `/counter` | `increment_btn`, `decrement_btn`, `reset_btn`, `counter_value` |
| `/settings` | `dark_mode_switch`, `notifications_switch`, `save_settings_btn` |
| `/profile` | `name_field`, `bio_field`, `save_profile_btn` |

Login credentials: `test@mcp.com` / `1234` (or use "Skip" button).

## Notes

- Lint rules: `package:flutter_lints/flutter.yaml` with no custom overrides.
- SDK constraint: `>=3.0.0 <4.0.0`.
- Use `package:mcp_test_app/...` imports (not relative) for consistency.