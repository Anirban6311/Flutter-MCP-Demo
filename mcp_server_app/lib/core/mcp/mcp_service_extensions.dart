import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:mcp_test_app/core/mcp/mcp_registry.dart';

/// Registers Dart VM service extensions that the MCP server calls
/// to interact with the running app.
void registerMcpExtensions(McpRegistry registry) {
  dev.registerExtension('ext.mcptest.navigate', (method, params) async {
    final route = params['route'] ?? '/home';
    registry.navigatorKey.currentState?.pushNamed(route);
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'route': route}));
  });

  dev.registerExtension('ext.mcptest.back', (method, params) async {
    registry.navigatorKey.currentState?.pop();
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok'}));
  });

  dev.registerExtension('ext.mcptest.setText', (method, params) async {
    final key = params['key'] ?? '';
    final text = params['text'] ?? '';
    final ctrl = registry.textControllers[key];
    if (ctrl == null) {
      return dev.ServiceExtensionResponse.result(
          jsonEncode({'status': 'error', 'msg': 'No controller for key: $key'}));
    }
    ctrl.text = text;
    ctrl.selection = TextSelection.collapsed(offset: text.length);
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'key': key, 'text': text}));
  });

  dev.registerExtension('ext.mcptest.tap', (method, params) async {
    final key = params['key'] ?? '';
    final cb = registry.tapCallbacks[key];
    if (cb == null) {
      return dev.ServiceExtensionResponse.result(
          jsonEncode({'status': 'error', 'msg': 'No tap callback for key: $key'}));
    }
    cb();
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'key': key}));
  });

  dev.registerExtension('ext.mcptest.getText', (method, params) async {
    final key = params['key'] ?? '';
    final getter = registry.textGetters[key];
    if (getter == null) {
      final ctrl = registry.textControllers[key];
      if (ctrl != null) {
        return dev.ServiceExtensionResponse.result(
            jsonEncode({'status': 'ok', 'text': ctrl.text}));
      }
      return dev.ServiceExtensionResponse.result(
          jsonEncode({'status': 'error', 'msg': 'No getter for key: $key'}));
    }
    return dev.ServiceExtensionResponse.result(
        jsonEncode({'status': 'ok', 'text': getter()}));
  });

  dev.registerExtension('ext.mcptest.listKeys', (method, params) async {
    return dev.ServiceExtensionResponse.result(jsonEncode({
      'textControllers': registry.textControllers.keys.toList(),
      'tapCallbacks': registry.tapCallbacks.keys.toList(),
      'textGetters': registry.textGetters.keys.toList(),
    }));
  });
}