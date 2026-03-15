import 'package:flutter/material.dart';

import 'package:mcp_test_app/app.dart';
import 'package:mcp_test_app/core/mcp/mcp_registry.dart';
import 'package:mcp_test_app/core/mcp/mcp_service_extensions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final registry = McpRegistry();
  registerMcpExtensions(registry);
  runApp(McpTestApp(registry: registry));
}