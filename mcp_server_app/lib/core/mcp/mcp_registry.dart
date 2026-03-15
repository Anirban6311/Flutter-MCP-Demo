import 'package:flutter/material.dart';

/// Central registry that MCP-controllable widgets register with.
/// Screens register controllers/callbacks in initState() and
/// remove them in dispose().
class McpRegistry {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, TextEditingController> textControllers = {};
  final Map<String, VoidCallback> tapCallbacks = {};
  final Map<String, String Function()> textGetters = {};

  void registerTextController(String key, TextEditingController controller) {
    textControllers[key] = controller;
  }

  void unregisterTextController(String key) {
    textControllers.remove(key);
  }

  void registerTapCallback(String key, VoidCallback callback) {
    tapCallbacks[key] = callback;
  }

  void unregisterTapCallback(String key) {
    tapCallbacks.remove(key);
  }

  void registerTextGetter(String key, String Function() getter) {
    textGetters[key] = getter;
  }

  void unregisterTextGetter(String key) {
    textGetters.remove(key);
  }
}

/// InheritedWidget to provide McpRegistry down the widget tree.
class McpRegistryScope extends InheritedWidget {
  final McpRegistry registry;

  const McpRegistryScope({
    super.key,
    required this.registry,
    required super.child,
  });

  static McpRegistry of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<McpRegistryScope>();
    assert(scope != null, 'No McpRegistryScope found in widget tree');
    return scope!.registry;
  }

  @override
  bool updateShouldNotify(McpRegistryScope oldWidget) =>
      registry != oldWidget.registry;
}